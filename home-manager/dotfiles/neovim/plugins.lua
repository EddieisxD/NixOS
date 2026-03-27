-- File: dotfiles/neovim/plugins.lua
return {
  -- Plugin 1: Render Markdown (The "Beauty" Engine)
  require("plugin_files.render_markdown"),
  -- Plugin 2: Obsidian.nvim (The "Logic" Engine)
  require("plugin_files.obsidian")
}
