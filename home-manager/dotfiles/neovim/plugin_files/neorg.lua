return {
  "nvim-neorg/neorg",
  lazy = false,
  version = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("neorg").setup({
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {
          config = {
            icon_preset = "diamond",
          },
        },
        ["core.dirman"] = {
          config = {
            workspaces = {
              personal = "~/Documents/combined_notes/Neorg",
            },
            default_workspace = "personal",
          },
        },
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          },
        },
        ["core.journal"] = {
          config = {
            journal_folder = "journal",
          },
        },
        ["core.itero"] = {},
        ["core.esupports.metagen"] = {
          config = {
            type = "auto",
          },
        },
        ["core.ui.calendar"] = {},
      },
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "norg",
      callback = function()
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = "nc"
      end,
    })
  end,
}
