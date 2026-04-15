return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
  ft = { "markdown", "norg", "rmd", "org" },
  opts = {
    preset = "obsidian",
    acknowledge_conflicts = true,
    heading = {
      enabled = true,
      sign = true,
      position = "inline",
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      width = "full",
      border = false,
      background = false,
    },
    checkbox = {
      enabled = true,
      position = "inline",
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
    pipe_table = {
      preset = "round",
      style = "full"
    },
    link = {
      enabled = true,
      wiki = { icon = "󰌷", highlight = "RenderMarkdownWiki" },
    },
    quote = { icon = "▋", highlight = "RenderMarkdownQuote" },
    latex = { enabled = true, highlight = "RenderMarkdownMath" },
  },
}
