-- Swift support: LazyVim has no bundled Swift extra, so wire sourcekit-lsp
-- (ships with the Swift toolchain at ~/.local/bin/sourcekit-lsp) by hand.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      sourcekit = {},
    },
    setup = {
      sourcekit = function()
        -- Make sure the Swift toolchain (and its LSP) is on PATH for nvim.
        vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. vim.env.PATH
      end,
    },
  },
}
