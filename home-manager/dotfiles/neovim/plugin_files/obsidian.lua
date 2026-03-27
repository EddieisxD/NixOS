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
    -- FIXED: UI table is now correctly INSIDE opts
    ui = {
      enable = true, -- Enable for link hiding and embeddings
      update_debounce = 200,
      -- SURGICAL FIX: Disable checkboxes/bullets here 
      -- so they don't fight with render-markdown
      checkboxes = {},
      bullets = {},
      -- Keep these for the "Obsidian" look
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
    },
  },
}
