return {
  -- LSP設定（Homebrew / mise を使用、nil のみ Nix）
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- PATH 上の LSP を使用（Mason による重複インストールを無効化）
        -- Opt out of inherited LazyVim server defaults for unmanaged tools.
        lua_ls = { enabled = false },
        ts_ls = { enabled = false },
        vtsls = { enabled = false },
        html = { enabled = false },
        cssls = { enabled = false },
        jsonls = { enabled = false },
        eslint = { enabled = false },
        nil_ls = {},
        rust_analyzer = {},
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
