return  {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/Documents/combined_notes/Obsidian/Vanity/",
      }
    },
    ui = {
      enable = false, -- Offload UI to render-markdown.nvim for better consistency
    },
    mappings = {
      -- Disable the default <cr> mapping that can be intrusive
      ["<cr>"] = {
        action = function()
          -- Fallback to default behavior (insert newline if in insert mode, or move down in normal)
          return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, false, true), "n", true)
        end,
        opts = { buffer = true, expr = true },
      },
    },
  },
}
