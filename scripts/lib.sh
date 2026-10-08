#!/usr/bin/env bash
# Shared helpers; source this file from the setup scripts.
DOTFILES_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

require_platform() {
  if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    printf '%s\n' 'This configuration requires Apple Silicon macOS.' >&2
    return 1
  fi
}

require_commands() {
  local name
  for name in "$@"; do
    if ! command -v "$name" >/dev/null 2>&1; then
      printf 'Required command not found: %s. See README.md for prerequisites.\n' "$name" >&2
      return 1
    fi
  done
}

apply_home_manager() {
  # Resolve Home Manager from the repository lock, not master/latest.
  # Back up unmanaged files on collision instead of replacing their contents.
  NIX_CONFIG="${NIX_CONFIG:-}"$'\nextra-experimental-features = nix-command flakes' \
  nix --extra-experimental-features 'nix-command flakes' run \
    --no-write-lock-file --inputs-from "$DOTFILES_ROOT" home-manager -- \
    switch --no-write-lock-file --flake "$DOTFILES_ROOT" \
    -b "before-dotfiles-$(date +%Y%m%d%H%M%S)"
}
