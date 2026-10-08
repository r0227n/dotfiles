"""Exercise provisioning boundaries using fake executables, never the real Mac."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles test ")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "commands.jsonl"
        stub = f"#!{sys.executable}\n" + '''import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["TEST_LOG"], "a") as stream:
    stream.write(json.dumps({"name": name, "args": args,
        "config": os.environ.get("MISE_GLOBAL_CONFIG_FILE"),
        "nix_config": os.environ.get("NIX_CONFIG"),
        "no_upgrade": os.environ.get("HOMEBREW_BUNDLE_NO_UPGRADE"),
        "cleanup": os.environ.get("HOMEBREW_BUNDLE_INSTALL_CLEANUP"),
        "force_cleanup": os.environ.get("HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP"),
        "no_install_cleanup": os.environ.get("HOMEBREW_NO_INSTALL_CLEANUP")}) + "\\n")
if name == os.environ.get("FAIL_COMMAND"):
    sys.exit(23)
if name == "uname":
    print(os.environ.get("TEST_OS", "Darwin") if args == ["-s"] else "arm64")
elif name == "brew" and args == ["--prefix"]:
    print(Path(sys.argv[0]).parent.parent)
'''
        for name in ("brew", "nix", "mise", "uname"):
            path = self.bin / name
            path.write_text(stub)
            path.chmod(0o755)
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "TEST_LOG": str(self.log),
            # Catch accidental inheritance instead of silently relying on it.
            "HOMEBREW_BUNDLE_NO_UPGRADE": "inherited",
            "HOMEBREW_BUNDLE_INSTALL_CLEANUP": "1",
            "HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP": "1",
            "MISE_GLOBAL_CONFIG_FILE": "/unrelated/project/config.toml",
            "NIX_CONFIG": "warn-dirty = false",
        }

    def run_script(self, name, *args):
        result = subprocess.run(
            ["/bin/bash", str(ROOT / "scripts" / name), *args],
            cwd=self.base, env=self.env, text=True, capture_output=True,
        )
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return result, calls

    def test_install_orders_brew_settings_and_pinned_runtimes(self):
        result, calls = self.run_script("install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        work = [c for c in calls if c["name"] != "uname"
                and c["args"] != ["--prefix"]]
        self.assertEqual([c["name"] for c in work], ["brew", "nix", "mise", "mise"])
        self.assertEqual(work[0]["args"], ["bundle", "install", f"--file={ROOT}/Brewfile"])
        self.assertEqual(work[0]["no_upgrade"], "1")
        self.assertIsNone(work[0]["cleanup"])
        self.assertIsNone(work[0]["force_cleanup"])
        self.assertEqual(work[0]["no_install_cleanup"], "1")
        self.assertIn("--no-write-lock-file", work[1]["args"])
        self.assertIn("--inputs-from", work[1]["args"])
        self.assertIn("warn-dirty = false", work[1]["nix_config"])
        self.assertIn("extra-experimental-features = nix-command flakes", work[1]["nix_config"])
        self.assertEqual(work[1]["args"].count("--no-write-lock-file"), 2)
        self.assertIn("-b", work[1]["args"])
        self.assertEqual(work[2]["args"], ["--cd", str(ROOT), "install"])
        self.assertEqual(work[3]["args"], ["--cd", str(ROOT), "reshim"])
        self.assertEqual(work[2]["config"], str(ROOT / "programs/mise/config.toml"))

    def test_update_upgrades_brew_but_keeps_runtime_pins(self):
        before = (ROOT / "programs/mise/config.toml").read_bytes(), (ROOT / "flake.lock").read_bytes()
        result, calls = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        bundle = next(c for c in calls if c["name"] == "brew" and "bundle" in c["args"])
        self.assertIsNone(bundle["no_upgrade"])
        self.assertIsNone(bundle["cleanup"])
        self.assertIsNone(bundle["force_cleanup"])
        self.assertFalse(any("upgrade" in c["args"] for c in calls if c["name"] == "mise"))
        self.assertEqual(before, ((ROOT / "programs/mise/config.toml").read_bytes(), (ROOT / "flake.lock").read_bytes()))

    def test_brew_failure_prevents_settings_and_runtime_changes(self):
        self.env["FAIL_COMMAND"] = "brew"
        result, calls = self.run_script("install.sh")
        self.assertEqual(result.returncode, 23)
        self.assertFalse(any(c["name"] in ("nix", "mise") for c in calls))

    def test_home_manager_failure_prevents_runtime_install(self):
        self.env["FAIL_COMMAND"] = "nix"
        result, calls = self.run_script("install.sh")
        self.assertEqual(result.returncode, 23)
        self.assertFalse(any(c["name"] == "mise" for c in calls))

    def test_mise_failure_prevents_reshim(self):
        self.env["FAIL_COMMAND"] = "mise"
        result, calls = self.run_script("setup-mise.sh")
        self.assertEqual(result.returncode, 23)
        self.assertFalse(any("reshim" in c["args"] for c in calls))

    def test_missing_nix_fails_before_installing_anything(self):
        (self.bin / "nix").unlink()
        result, calls = self.run_script("install.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required command not found: nix", result.stderr)
        self.assertFalse(any(c["name"] in ("brew", "mise") for c in calls))

    def test_unsupported_platform_fails_before_installing_anything(self):
        self.env["TEST_OS"] = "Linux"
        result, calls = self.run_script("install.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(all(c["name"] == "uname" for c in calls))

    def test_cleanup_is_not_an_accepted_operation(self):
        result, calls = self.run_script("setup-brew.sh", "--cleanup")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(any(c["name"] == "brew" for c in calls))


class ManagementPolicyTests(unittest.TestCase):
    def test_excluded_apps_and_runtime_formulae_are_not_declared(self):
        entries = re.findall(r'^(?:brew|cask) "([^"]+)"', (ROOT / "Brewfile").read_text(), re.M)
        excluded = {
            "hermes", "hermes-agent", "appium", "deno", "idb-companion",
            "cua-driver", "hhkb", "hhkb-keymap-tool", "raycast",
            "flutter", "bun", "node", "rust", "python", "zig",
            "lazygit", "lua-language-server", "typescript-language-server",
            "vscode-langservers-extracted", "block-goose-cli", "opencode",
            "tuist/tuist/tuist@4.155.3", "xcodegen", "1password-cli",
        }
        self.assertFalse(excluded.intersection(entries))
        self.assertEqual(len(entries), len(set(entries)))
        self.assertIn("mise", entries)
        self.assertNotIn('tap "tuist/tuist"', (ROOT / "Brewfile").read_text())

    def test_runtime_versions_are_explicit_and_not_rolling(self):
        content = (ROOT / "programs/mise/config.toml").read_text()
        tools = content.split("[tools]", 1)[1].split("[plugins]", 1)[0]
        pins = dict(re.findall(r'^(\w+) = "([^"]+)"', tools, re.M))
        self.assertTrue({"flutter", "bun", "node", "rust"}.issubset(pins))
        self.assertNotIn("zig", pins)
        for version in pins.values():
            self.assertRegex(version, r"^\d+\.\d+\.\d+$")


if __name__ == "__main__":
    unittest.main()
