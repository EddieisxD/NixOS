return {
  "renerocksai/telekasten.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  ft = { "markdown", "org" },
  cmd = { "Telekasten" },
  keys = {
    { "<leader>z", "<cmd>Telekasten<cr>", desc = "Open Telekasten" },
    { "<leader>zN", "<cmd>Telekasten new_note<cr>", desc = "New Note" },
    { "<leader>zs", "<cmd>Telekasten search_notes<cr>", desc = "Search Notes" },
    { "<leader>zt", "<cmd>Telekasten goto_today<cr>", desc = "Go to Today" },
    { "<leader>zb", "<cmd>Telekasten show_backlinks<cr>", desc = "Show Backlinks" },
    { "<leader>zf", "<cmd>Telekasten find_notes<cr>", desc = "Find Notes" },
    { "<leader>zi", "<cmd>Telekasten insert_link<cr>", desc = "Insert Link" },
    { "<leader>zp", "<cmd>Telekasten paste_img_and_link<cr>", desc = "Paste Image" },
  },
  opts = {
    home = vim.env.HOME .. "/Documents/combined_notes/Telekasten",
    take_over_my_home = true,
    auto_set_filetype = true,
    extension = ".md",
    new_note_location = "smart",
    rename_update_links = true,
    template_new_note = vim.env.HOME .. "/Documents/combined_notes/Telekasten/templates/new_note.md",
    template_new_journal = vim.env.HOME .. "/Documents/combined_notes/Telekasten/templates/new_journal.md",
    vaults = {
      personal = {
        home = vim.env.HOME .. "/Documents/combined_notes/Telekasten",
      },
    },
    -- Media and Images
    media_dir = "img",
    image_link_style = "markdown",
    -- Calendar
    calendar_opts = {
      weeknm = 4,
      calendar_monday = 1,
      calendar_mark = "left-fit",
    },
    -- UI
    highlights = true,
    fold_levels = false,
    show_tags = true,
  },
}
