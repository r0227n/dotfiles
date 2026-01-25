{ config, pkgs, ... }:

{
  # WezTerm本体は Homebrew Cask でインストール
  # brew install --cask wezterm
  # ここでは設定ファイルのみ管理

  home.file.".config/wezterm/wezterm.lua".source = ./wezterm.lua;
  home.file.".config/wezterm/keybinds.lua".source = ./keybinds.lua;
}
