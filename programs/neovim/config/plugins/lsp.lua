return {
  -- LSP設定（Homebrew / mise を使用、nil のみ Nix）
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- PATH 上の LSP を使用（Mason による重複インストールを無効化）
        lua_ls = {},
        nil_ls = {},
        rust_analyzer = {},
        ts_ls = {},
        dartls = {},
      },
    },
  },
  -- Mason無効化（Brewfile / mise で管理）
  {
    "williamboman/mason.nvim",
    enabled = false,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    enabled = false,
  },
}
