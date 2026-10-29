vim.pack.add({
    { src  =  "https://github.com/neovim/nvim-lspconfig" },
    { src  =  "https://github.com/sainnhe/everforest" }
})

require("config.treesitter")
require("config.mini-pairs")
require("config.tmux-navigator")
