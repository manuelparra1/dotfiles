-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- dusts Custom Functions

-- Convert To Title Case
local function titleCaseVisual()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local range = string.format('%d,%ds', start_line, end_line)
  vim.cmd(range .. '/\\(\\w\\+\\)/\\u\\L\\1/g')
  vim.cmd 'nohlsearch'
end
-- Define the titleCaseVisual function in the global Lua environment
_G.titleCaseVisual = titleCaseVisual

-- dusts Custom Keymaps
-- Set up the key mapping for insert mode
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'jkj', '<Esc>', { noremap = true, silent = true })

-- move up splits
vim.api.nvim_set_keymap('n', '<leader>k', '<C-w>k', { noremap = true, silent = true })

-- move down splits
vim.api.nvim_set_keymap('n', '<leader>j', '<C-w>j', { noremap = true, silent = true })

-- move left splits
vim.api.nvim_set_keymap('n', '<leader>h', '<C-w>h', { noremap = true, silent = true })

-- move right splits
vim.api.nvim_set_keymap('n', '<leader>l', '<C-w>l', { noremap = true, silent = true })

-- Change inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap('n', 'ciw', '"_ciw', { noremap = true, silent = true })

-- Change inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap('n', 'ci"', '"_ci"', { noremap = true, silent = true })

-- Delete inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap('n', 'diw', '"_diwh', { noremap = true, silent = true })

-- Delete inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap('n', 'di"', '"_di"h', { noremap = true, silent = true })

-- Delete line and save to custom register _ (black hole register)
vim.api.nvim_set_keymap('n', 'dd', '"_dd', { noremap = true, silent = true })

-- bullet lists
-- Add alpha format to nrformats
vim.api.nvim_command 'set nrformats+=alpha'
vim.keymap.set('n', '<leader>aa', '0<C-v>3j<S-I>A. <ESC>j<C-v>2jg<C-a>', { desc = 'Inserts letters and increments on 4 lines' })

-- delete all matching characters, visually selected
vim.keymap.set('x', '<leader>x', 'y:%s/<C-R>"//g<CR>', { desc = 'Delete all matching characters' })

-- use convert-to-title-case function
vim.api.nvim_set_keymap('v', '<Leader>T', ':lua titleCaseVisual()<CR>', { noremap = true, silent = true })
