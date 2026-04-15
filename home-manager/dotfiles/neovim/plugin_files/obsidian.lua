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
  },
}
