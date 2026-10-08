{ config, pkgs, lib, ... }:

{
  home.shellAliases = {
      # モダンツール
      ls = "eza --icons=auto";
      ll = "eza -l --icons=auto --git";
      la = "eza -la --icons=auto --git";
      lt = "eza --tree --icons=auto --level=2";
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
      vimdiff = "nvim -d";

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

  # macOS supplies Zsh; Homebrew supplies its plugins and prompt/CLI tools.
  home.file.".zshenv".text = ''
    if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    export ZDOTDIR="$HOME/.config/zsh"
  '';

  xdg.configFile."zsh/.zprofile".source = ./zprofile;
  xdg.configFile."zsh/.zshrc".text =
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "alias ${name}=${lib.escapeShellArg value}")
      config.home.shellAliases)
    + "\n" + builtins.readFile ./zshrc;

  xdg.configFile."starship.toml".source =
    (pkgs.formats.toml { }).generate "starship.toml" {
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

  xdg.configFile."bat/config".text = ''
    --theme="TwoDark"
    --style="numbers,changes,header"
  '';
}
