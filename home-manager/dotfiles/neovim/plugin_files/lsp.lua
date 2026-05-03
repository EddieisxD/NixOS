local M = {
  "neovim/nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "hrsh7th/cmp-nvim-lsp" },
}

M.config = function()
  local lspconfig = require("lspconfig")
  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  local on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  end

  -- List of servers to check for in PATH
  local servers = {
    marksman = { "marksman" },
    nil_ls = { "nil" },
    pyright = { "pyright" },
    ruff = { "ruff" },
    ts_ls = { "typescript-language-server" },
    gopls = { "gopls" },
    rust_analyzer = { "rust-analyzer" },
    clangd = { "clangd" },
    hls = { "haskell-language-server-wrapper", "hls" },
    lua_ls = { "lua-language-server" },
  }

  for server, binaries in pairs(servers) do
    local found = false
    for _, bin in ipairs(binaries) do
      if vim.fn.executable(bin) == 1 then
        found = true
        break
      end
    end

    if found then
      lspconfig[server].setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end
  end

  -- Diagnostics config
  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })
end

return M
