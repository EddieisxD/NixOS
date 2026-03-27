return  {
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
    callout = {
      note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
      tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
      warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
    },

    -- TABLES & LINKS: Full Aesthetic
    pipe_table = {
      preset = "round",
      style = "full"
    },

    link = {
      enabled = true, -- render-markdown handles icons
      wiki = { icon = "󰌷", highlight = "RenderMarkdownWiki" },
    },
    quote = { icon = "▋", highlight = "RenderMarkdownQuote" },
    latex = { enabled = true, highlight = "RenderMarkdownMath" },
  },
}

