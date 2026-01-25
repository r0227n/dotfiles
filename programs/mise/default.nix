{ config, pkgs, ... }:

{
  # mise本体のインストール
  home.packages = with pkgs; [
    mise
  ];

  # mise設定ファイル
  home.file.".config/mise/config.toml".text = ''
    [tools]
    # グローバルバージョン（プロジェクトで上書き可能）
    # ここでは指定せず、プロジェクトごとに管理することを推奨

    [settings]
    experimental = true
    verbose = false

    # プラグイン自動インストール
    plugin_autoupdate_last_check_duration = "7d"

    # ショートハンド有効化
    shorthands_file = "~/.config/mise/shorthands.toml"
  '';

  # ショートハンド設定（オプション）
  home.file.".config/mise/shorthands.toml".text = ''
    # カスタムショートハンドをここに追加
  '';

  # シェル統合
  programs.zsh.initExtra = ''
    # mise初期化
    eval "$(mise activate zsh)"

    # mise補完
    eval "$(mise completion zsh)"
  '';
}
