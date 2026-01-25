{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # 履歴設定
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # エイリアス
    shellAliases = {
      # モダンツール
      ls = "eza --icons";
      ll = "eza -l --icons --git";
      la = "eza -la --icons --git";
      lt = "eza --tree --icons --level=2";
      cat = "bat";

      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --all --decorate";
      gd = "git diff";
      lg = "lazygit";

      # Neovim
      v = "nvim";
      vim = "nvim";
      vi = "nvim";

      # dotfiles管理
      dotfiles = "cd ~/dotfiles";
      nixup = "cd ~/dotfiles && home-manager switch --flake .";
      nixclean = "nix-collect-garbage -d";

      # mise
      mi = "mise";
      mii = "mise install";
      mil = "mise list";
      miu = "mise use";

      # その他
      c = "clear";
      h = "history";
      t = "tree";
    };

    # 追加設定
    initExtra = ''
      # fzf統合
      source <(fzf --zsh)

      # zoxide統合
      eval "$(zoxide init zsh)"

      # 補完設定
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # キーバインド
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward

      # ローカル設定の読み込み（API key等）
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local

      # 便利な関数

      # プロジェクトディレクトリに移動してmiseを確認
      function pd() {
        z "$1" && mise current
      }

      # mise環境のクリーンインストール
      function mise-reinstall() {
        mise uninstall "$1"
        mise install "$1"
      }
    '';
  };

  # Starship（プロンプト）
  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;

      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nodejs"
        "$rust"
        "$flutter"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };

      git_branch = {
        symbol = " ";
        format = "on [$symbol$branch]($style) ";
      };

      git_status = {
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        conflicted = "🏳";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++\($count\)](green)";
        renamed = "👅";
        deleted = "🗑";
      };

      # mise管理の言語バージョン表示
      nodejs = {
        format = "via [$symbol($version )]($style)";
        symbol = " ";
      };

      rust = {
        format = "via [$symbol($version )]($style)";
        symbol = "🦀 ";
      };

      flutter = {
        format = "via [$symbol($version )]($style)";
        symbol = " ";
      };

      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
      };
    };
  };

  # fzf設定
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
    ];

    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} | head -200'"
    ];

    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # zoxide設定
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  # bat設定
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };
}
