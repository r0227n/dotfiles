{ config, pkgs, lib, ... }:

{
  # macOS特有のパッケージ
  home.packages = lib.mkIf pkgs.stdenv.isDarwin (with pkgs; [
    mas           # Mac App Store CLI
    m-cli         # macOS管理ツール
  ]);

  # macOS専用の環境変数
  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    # Homebrewパス（必要な場合）
    # PATH = "$PATH:/opt/homebrew/bin";
  };
}
