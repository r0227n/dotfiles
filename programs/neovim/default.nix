{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Neovimに必要なパッケージ
    extraPackages = with pkgs; [
      # LSP servers（mise管理の言語用）
      lua-language-server       # Lua
      nil                       # Nix
      # Node.js, Rust, Flutterは mise で管理するため除外

      # Formatters
      stylua                    # Lua
      nixpkgs-fmt              # Nix
      # prettier, rustfmtなどはmiseで管理

      # Linters
      shellcheck

      # 必須ツール
      tree-sitter
      ripgrep
      fd
      lazygit
      gcc                       # treesitterコンパイル用
    ];
  };

  # AstroVimのインストール
  home.activation.installAstroNvim = ''
    NVIM_DIR="${config.home.homeDirectory}/.config/nvim"

    if [ ! -d "$NVIM_DIR/lua/astronvim" ]; then
      $DRY_RUN_CMD rm -rf "$NVIM_DIR"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/AstroNvim/AstroNvim "$NVIM_DIR"
    fi
  '';

  # AstroVimユーザー設定
  home.file.".config/nvim/lua/user/init.lua".text = ''
    return {
      -- カラースキーム
      colorscheme = "astrodark",

      -- UI設定
      options = {
        opt = {
          relativenumber = true,
          number = true,
          spell = false,
          signcolumn = "yes",
          wrap = false,
        },
      },

      -- LSP設定
      lsp = {
        setup_handlers = {
          -- miseで管理される言語のLSP設定
          rust_analyzer = function(_, opts)
            -- Rustプロジェクトではmiseのrust-analyzerを使用
            require("astronvim.utils.lsp").setup("rust_analyzer", opts)
          end,
          tsserver = function(_, opts)
            -- Node.jsプロジェクトではmiseのtsserverを使用
            require("astronvim.utils.lsp").setup("tsserver", opts)
          end,
        },

        config = {
          lua_ls = {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
              },
            },
          },
        },
      },

      -- プラグイン追加
      plugins = {
        -- mise統合
        {
          "williamboman/mason.nvim",
          opts = function(_, opts)
            -- Masonを無効化してmiseを使用
            opts.ensure_installed = opts.ensure_installed or {}
            -- LSPはmiseで管理するため、Masonでインストールしない
          end,
        },
      },
    }
  '';
}
