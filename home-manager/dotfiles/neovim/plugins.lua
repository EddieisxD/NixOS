-- File: dotfiles/neovim/plugins.lua
return {
  -- Plugin 1: Render Markdown (The "Beauty" Engine)
  require("plugin_files.render_markdown"),
  -- Plugin 2: Obsidian.nvim (The "Logic" Engine)
  require("plugin_files.obsidian"),
  -- Plugin 3: Telekasten.nvim (Zettelkasten for plain markdown)
  require("plugin_files.telekasten"),
  -- Plugin 4: nvim-orgmode (Full Org mode)
  require("plugin_files.orgmode"),
  -- Plugin 5: Spelling & Dictionary
  require("plugin_files.spell"),
  -- Plugin 6: LSP Configuration
  require("plugin_files.lsp"),

  -- Override NvChad default cmp to add dictionary and spell
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, { name = "dictionary", keyword_length = 2 })
      table.insert(opts.sources, { name = "spell" })
      return opts
    end,
  },
}
