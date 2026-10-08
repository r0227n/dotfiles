{ ... }:

{
  # Neovim and its helpers come from Brewfile; only configuration is managed here.
  # Deploy existing LazyVim sources without cloning over ~/.config/nvim.
  xdg.configFile = {
    "nvim/init.lua".source = ./config/init.lua;
    "nvim/lua/config/lazy.lua".source = ./config/lazy.lua;
    "nvim/lua/config/options.lua".source = ./config/options.lua;
    "nvim/lua/config/keymaps.lua".source = ./config/keymaps.lua;
    "nvim/lua/config/autocmds.lua".source = ./config/autocmds.lua;
    "nvim/lua/plugins".source = ./config/plugins;
  };
}
