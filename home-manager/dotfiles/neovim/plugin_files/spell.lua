return {
  -- Dictionary completion
  {
    "uga-rosa/cmp-dictionary",
    event = "InsertCharPre",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    config = function(_, opts)
      -- Dictionary setup
      require("cmp_dictionary").setup(opts)
      
      -- Spell settings
      vim.opt.spelllang = "en_us"
      
      -- Autocmd to enable spell only for text-based files
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
        org = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
        norg = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
        text = vim.fn.stdpath("config") .. "/dictionaries/markdown.dict",
      },
      exact_length = 2,
      first_case_insensitive = true,
    },
  },

  -- Spell completion (source for nvim-cmp)
  -- This provides completions from the vim spell engine
  {
    "f3mshe/cmp-spell",
    dependencies = "hrsh7th/nvim-cmp",
  },
}
