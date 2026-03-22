-- File: dotfiles/neovim/plugins.lua
return {
  -- Plugin 1: Render Markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      preset = "obsidian",
      anti_conceal = {
        enabled = true,
        ignore = {
          code_background = true,
          sign = true,
        },
      },
      heading = {
        enabled = true,
        sign = true,
        position = "overlay",
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        signs = { "󰫎 " },
        width = "full",
        left_margin = 0,
        left_pad = 2,
        right_pad = 2,
        min_width = 0,
        border = true,
        border_virtual = true,
        border_prefix = false,
      },
      code = {
        enabled = true,
        sign = true,
        style = "full",
        position = "left",
        language_pad = 2,
        width = "full",
        left_pad = 2,
        right_pad = 2,
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅒 Important", highlight = "RenderMarkdownError" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
      dash = {
        enabled = true,
        icon = "─",
        width = "full",
      },
      bullet = {
        icons = { "●", "○", "◆", "◇" },
        left_pad = 0,
        right_pad = 1,
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = " " },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 Pending", highlight = "RenderMarkdownWarn" },
        },
      },
      quote = {
        enabled = true,
        icon = "▋", -- A thick vertical bar
        highlight = "RenderMarkdownQuote",
      },
      latex = {
        enabled = true,
        converter = "latex2text",
        highlight = "RenderMarkdownMath",
      }
    },
  }, -- Correctly closed render-markdown

  -- Plugin 2: Obsidian.nvim
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/combined_notes/Obsidian/Vanity/",
        }
      },
    },
  },
}
