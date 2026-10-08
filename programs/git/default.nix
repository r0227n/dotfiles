{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = null; # Installed by Homebrew.
    settings = {
      user.name = "r0227n";
      user.email = "r0227n@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "nvim";
      core.autocrlf = "input";

      # Delta設定
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";

      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Nord";
      };

      merge = {
        conflictstyle = "diff3";
        tool = "nvimdiff";
      };

      diff = {
        colorMoved = "default";
        algorithm = "histogram";
      };

      # rerere（コンフリクト解決を記憶）
      rerere.enabled = true;
    };

    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      # エディタ
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".idea/"

      # Node.js
      "node_modules/"
      "npm-debug.log"
      "yarn-error.log"

      # 環境変数
      ".env"
      ".env.local"
      ".env.*.local"
      ".claude.env"

      # シェル設定（ローカル）
      ".zshrc.local"

      # ログ
      "*.log"

      # mise
      ".mise.local.toml"

      # その他
      ".direnv/"
    ];

    settings.alias = {
      st = "status -sb";
      co = "checkout";
      cob = "checkout -b";
      br = "branch";
      ci = "commit";
      cm = "commit -m";
      ca = "commit --amend";
      unstage = "reset HEAD --";
      last = "log -1 HEAD --stat";
      visual = "log --graph --all --oneline --decorate";
      ll = "log --oneline --graph --all --decorate";
      contributors = "shortlog --summary --numbered";
    };
  };

  # Generate settings without installing a second gh through Nix.
  xdg.configFile."gh/config.yml".source = (pkgs.formats.yaml { }).generate "gh-config.yml" {
    git_protocol = "ssh";
    editor = "nvim";
    prompt = "enabled";
    pager = "delta";
  };
}
