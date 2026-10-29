vim.pack.add{
  { src = 'https://github.com/neovim/nvim-lspconfig' },
}


vim.lsp.config('basedpyright', {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard"
      }
    }
  }
})

vim.lsp.enable('basedpyright')
