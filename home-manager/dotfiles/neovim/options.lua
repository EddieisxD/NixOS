vim.opt.conceallevel = 2

-- Obsidian specific mappings
local opts = { noremap = true, silent = true }

-- Search & Navigation
vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Open Note" })
vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "Search Vault" })
vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "Show Backlinks" })

-- Creation
vim.keymap.set("n", "<leader>od", "<cmd>ObsidianToday<cr>", { desc = "Daily Note" })
vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "New Note" })

-- Functionality
vim.keymap.set("v", "<leader>ol", "<cmd>ObsidianLink<cr>", { desc = "Link Selection" })
vim.keymap.set("n", "<leader>op", "<cmd>ObsidianPasteImg<cr>", { desc = "Paste Image" })

