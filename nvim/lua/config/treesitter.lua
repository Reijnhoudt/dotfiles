vim.pack.add({
  { src  =  "https://github.com/nvim-treesitter/nvim-treesitter" }
})

local TS = require("nvim-treesitter")

-- Enable tree-sitter highlighting
vim.api.nvim_create_autocmd('FileType', {
  pattern = { '<filetype>' },
  callback = function() vim.treesitter.start() end,
})
