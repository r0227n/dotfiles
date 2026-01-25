{ config, pkgs, username, ... }:

{
  # Home Managerの基本設定
  programs.home-manager.enable = true;

  home = {
    username = username;
    homeDirectory = "/Users/${username}";  # macOS
    stateVersion = "24.05";

    # グローバル環境変数
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "ja_JP.UTF-8";
      LC_ALL = "ja_JP.UTF-8";
    };

    # Android SDK パス
    sessionPath = [
      "$HOME/Library/Android/sdk/platform-tools"
      "$HOME/Library/Android/sdk/emulator"
    ];
  };

  # 基本CLIツール（mise管理外）
  home.packages = with pkgs; [
    # コアツール
    curl
    wget
    git

    # モダンCLIツール
    ripgrep       # grep代替 (rg)
    fd            # find代替
    bat           # cat代替
    eza           # ls代替
    fzf           # ファジーファインダー
    zoxide        # cd代替 (z)
    delta         # Git diff viewer

    # ファイル操作
    tree
    jq            # JSON processor
    yq-go         # YAML processor

    # システムモニタリング
    htop
    btop

    # Git関連
    gh            # GitHub CLI
    lazygit       # Git TUI

    # 開発補助ツール
    direnv        # プロジェクト環境変数管理

    # その他
    tldr          # コマンド例集
  ];

  # モジュールのインポート
  imports = [
    ./modules/common.nix
    ./modules/darwin.nix
    ./modules/fonts.nix
    ./programs/neovim
    ./programs/wezterm
    ./programs/shell
    ./programs/git
    ./programs/mise
    ./programs/claude
  ];
}
