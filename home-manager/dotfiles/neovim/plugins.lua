-- File: dotfiles/neovim/plugins.lua
local M = {
  -- Plugin 1: Render Markdown (The "Beauty" Engine)
  require("configs.plugin_files.render_markdown"),
  -- Plugin 2: Obsidian.nvim (The "Logic" Engine)
  require("configs.plugin_files.obsidian"),
  -- Plugin 3: Telekasten.nvim (Zettelkasten for plain markdown)
  require("configs.plugin_files.telekasten"),
  -- Plugin 4: nvim-orgmode (Full Org mode)
  require("configs.plugin_files.orgmode"),
  -- Plugin 6: LSP Configuration
  require("configs.plugin_files.lsp"),

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

-- Plugin 5: Spelling & Dictionary (returns a list, so we flatten it)
local spell_plugins = require("configs.plugin_files.spell")
for _, p in ipairs(spell_plugins) do
  table.insert(M, p)
end

return M
