vim.pack.add({
    { src = "https://github.com/sainnhe/everforest" },
    { src = "https://github.com/e-ink-colorscheme/e-ink.nvim"}
})

vim.api.nvim_set_hl(0, "Keyword", { bold = true })
vim.api.nvim_set_hl(0, "Comment", { italic = true })
vim.o.background = "dark"
vim.cmd.colorscheme("everforest")
