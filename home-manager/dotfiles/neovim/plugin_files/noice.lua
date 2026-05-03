-- Example lazy.nvim setup
return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },

    -- opts = {
    --   presets = {
    --     command_palette = true, -- Positions cmdline and popupmenu together in the center
    --     long_message_to_split = true, -- Sends long messages to a split window
    --     inc_rename = false, -- Enables an input dialog for inc-rename.nvim
    --     lsp_doc_border = false, -- Adds a border to hover docs and signature help
    --   },
    -- }
    opts = {
      views = {
        cmdline_popup = {
          position = {
            row = "40%", -- Adjust this percentage to move it up or down
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
      },
    }

  }
}

