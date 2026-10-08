{ config, pkgs, ... }:

{
  # XDG Base Directory設定
  xdg = {
    enable = true;

    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  # Keep Flakes enabled for subsequent home-manager/nix commands as well.
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  # 統合 direnvrc（mise + claude）
  home.file.".config/direnv/direnvrc".text = ''
    # nix-direnv is not packaged by Homebrew; retain this Nix integration.
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc

    # miseとdirenvの統合
    use_mise() {
      eval "$(mise direnv exec)"
    }

    # Claude API key読み込み（.envrc内で使用）
    use_claude() {
      if [ -f ".claude.env" ]; then
        source_env ".claude.env"
      fi
    }
  '';
}
