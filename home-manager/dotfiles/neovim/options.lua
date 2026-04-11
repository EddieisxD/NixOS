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

----- markdown.nvim 

vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.list = true
vim.opt.listchars = "tab:  ,trail: ,extends: ,precedes: "

vim.opt.conceallevel = 2
vim.opt.concealcursor = 'nc'

vim.opt.relativenumber = true
----
vim.opt.wrap = true            -- Enable wrapping
vim.opt.linebreak = true       -- Don't break words in the middle
vim.opt.breakindent = true     -- Keep the wrap aligned with the line's start
vim.opt.showbreak = "  "       -- Add a little padding to the start of wrapped lines
