return {
  -- LSP設定（Nix管理のLSPを使用）
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Nixで提供されるLSPを使用（Mason無効）
        lua_ls = {},
        nil_ls = {},
        rust_analyzer = {},
        ts_ls = {},
        dartls = {},
      },
    },
  },
  -- Mason無効化（NixでLSP管理）
  {
    "williamboman/mason.nvim",
    enabled = false,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    enabled = false,
  },
}
