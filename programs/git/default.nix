{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "r0227n";
    userEmail = "r0227n@users.noreply.github.com";

    extraConfig = {
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

    aliases = {
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

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      prompt = "enabled";
      pager = "delta";
    };
  };

  # lazygit設定
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          selectedLineBgColor = [ "reverse" ];
          selectedRangeBgColor = [ "reverse" ];
        };
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };
}
