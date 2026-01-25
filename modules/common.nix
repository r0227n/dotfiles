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

  # direnv統合
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # 統合 direnvrc（mise + claude）
  home.file.".config/direnv/direnvrc".text = ''
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
