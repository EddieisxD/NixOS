-- File: dotfiles/neovim/plugins.lua
return {
  -- Plugin 1: Render Markdown (The "Beauty" Engine)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      preset = "obsidian",
      acknowledge_conflicts = true, -- Stops warnings about obsidian.nvim
      anti_conceal = { enabled = true },
      
      -- HEADINGS: Clean & Bold
      heading = {
        enabled = true,
        sign = false, -- Cleaner look without double icons
        position = "inline", 
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "full",
        border = true,
      },

      -- CHECKBOXES: This fixes the "endar" issue
      checkbox = {
        enabled = true,
        position = "inline", -- Inline pushes text, Overlay eats it.
        unchecked = { icon = "󰄱", highlight = "RenderMarkdownTodo" },
        checked = { icon = "", highlight = "RenderMarkdownDone" },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔", highlight = "RenderMarkdownWarn" },
        },
      },

      -- TABLES & LINKS: Full Aesthetic
      pipe_table = { preset = "round" },
      link = {
        enabled = true, -- render-markdown handles icons
        wiki = { icon = "󱗘 ", highlight = "RenderMarkdownWiki" },
      },
    },
  },

  -- Plugin 2: Obsidian.nvim (The "Logic" Engine)
  {
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
  },
}
