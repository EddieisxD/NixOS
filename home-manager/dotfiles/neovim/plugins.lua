-- File: dotfiles/neovim/plugins.lua
return {
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
        position = "inline",
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
      checkbox = {
        enabled = true,
        position = "inline",
        width = "constant",
        unchecked = { icon = "󰄱 " },
        checked = { icon = " " },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownWarn" },
        },
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
      quote = {
        enabled = true,
        icon = "▋",
        highlight = "RenderMarkdownQuote",
      },
      pipe_table = {
        enabled = true,
        preset = "round", -- Aesthetic upgrade for tables
        style = "full",
      },
    },
  },

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
    },
    ui = {
      enable = true,
      checkboxs = {},
      bullets = {}
    },
  },
}
