return {
  -- Flutter/Dart support
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        lsp = {
          color = { enabled = true },
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
          },
        },
        debugger = { enabled = true },
        widget_guides = { enabled = true },
      })
    end,
  },
}
