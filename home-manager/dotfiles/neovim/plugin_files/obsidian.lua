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
      enable = true,
      update_debounce = 200,
      -- DISABLED in obsidian.nvim so they don't fight with render-markdown
      checkboxes = {},
      bullets = {},
      -- Set hl_groups to empty to disable their rendering
      hl_groups = {
        ObsidianTodo = { link = "Normal" },
        ObsidianDone = { link = "Normal" },
        ObsidianCheckRightBrace = { link = "Normal" },
        ObsidianCheckLeftBrace = { link = "Normal" },
        ObsidianAtxHeader = { link = "Normal" },
      },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      tags = { hl_group = "ObsidianTag" },
    },
  },
}
