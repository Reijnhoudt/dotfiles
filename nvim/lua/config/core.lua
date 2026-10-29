-- ============================================================================
-- General Settings
-- ============================================================================
vim.o.termguicolors = true         -- Enable true colour support
vim.o.mouse = "a"                  -- Enable mouse in all modes
vim.o.number = true                -- Show absolute line numbers
vim.o.relativenumber = true        -- Show relative line numbers
vim.o.cursorline = true            -- Highlight the line the cursor is on
vim.o.tabstop = 4                  -- Number of spaces a <Tab> counts for
vim.o.shiftwidth = 4               -- Number of spaces for (auto)indent
vim.o.expandtab = true             -- Use spaces instead of tabs
vim.o.encoding = "utf-8"           -- Default encoding
vim.g.terminal_italic = true       -- Enable italics in the terminal

-- Folding settings
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- File Explorer Style
vim.g.netrw_liststyle = 3
vim.g.netrw_altfile = 1 -- Lets ctrl-^ ignore netrw when jumping between files

-- ============================================================================
-- Mappings
-- ============================================================================
-- Leader key (default is backslash, but you can change it: vim.g.mapleader = " ")
-- Toggle fold under cursor with <Space>
vim.keymap.set("n", "<Space>", "za", { noremap = true, silent = true })

-- Split navigation (Ctrl + H/J/K/L)
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", { noremap = true, silent = true })

-- Open diagnostics using <leader>d
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic' })

-- Autocompletion using C-Space
vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', { desc = "Omnicomplete" })

-- Open file explorer
vim.keymap.set('n', '<S-e>', '<Cmd>Explore<CR>', { desc = 'Toggle file explorer' })

-- Surround selection in brackets when pressing ([{<"' in visual mode
local function surround_visual(open, close)
  vim.keymap.set("x", open, function()
    -- Do nothing in Visual Line mode
    if vim.fn.mode() == "V" then
      return "<Ignore>"
    end

    return "c" .. open .. close .. "<Esc>P"
  end, {
    expr = true,
    noremap = true,
    silent = true,
  })
end

surround_visual("(", ")")
surround_visual("[", "]")
surround_visual("{", "}")
surround_visual("<", ">")
surround_visual('"', '"')
surround_visual("'", "'")

-- ============================================================================
-- Custom Commands
-- ============================================================================
-- Diff current buffer against the original file on disk
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis")
end, {})

