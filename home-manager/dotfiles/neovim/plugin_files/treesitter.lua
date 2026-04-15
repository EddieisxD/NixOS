return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufEnter", "BufWinEnter" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "markdown",
        "markdown_inline",
        "org",
        "norg",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    })
  end,
}
