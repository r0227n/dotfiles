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
      "$HOME/.local/share/mise/shims"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "$HOME/.local/bin"
      "$HOME/.pub-cache/bin"
      "$HOME/Library/Android/sdk/platform-tools"
      "$HOME/Library/Android/sdk/emulator"
    ];
  };

  # Application binaries are installed by Brewfile; Home Manager owns settings.
  # nil is not available in Homebrew and remains a Nix-only language server.
  home.packages = [ pkgs.nil ];

  # モジュールのインポート
  imports = [
    ./modules/common.nix
    ./modules/darwin.nix
    ./programs/neovim
    ./programs/wezterm
    ./programs/shell
    ./programs/git
    ./programs/mise
    ./programs/claude
  ];
}
