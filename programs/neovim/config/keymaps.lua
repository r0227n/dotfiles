-- カスタムキーマップ
local map = vim.keymap.set

-- lazygit
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
