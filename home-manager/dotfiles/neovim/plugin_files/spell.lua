return {
  "uga-rosa/cmp-dictionary",
  event = "InsertCharPre",
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  config = function()
    vim.opt.spell = false -- Don't enable globally
    vim.opt.spelllang = "en_us"
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "org", "norg", "text" },
      callback = function()
        vim.opt_local.spell = true
      end,
    })
  end,
  opts = {
    paths = {
     markdown = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
      org = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict", -- Reuse for now
      norg = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
      text = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
    },
    exact_length = 2,
    first_case_insensitive = true,
  },
}
