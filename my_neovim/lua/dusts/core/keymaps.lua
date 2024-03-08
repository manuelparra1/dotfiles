-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

--------------------- General Keymaps -------------------
-- bullet lists
keymap.set(
	"n",
	"<leader>aa",
	"0<C-v>3j<S-I>A. <ESC>j<C-v>2jg<C-a>",
	{ desc = "Inserts letters and increments on 4 lines" }
)
-- delete all matching characters, visually selected
keymap.set("x", "<leader>x", 'y:%s/<C-R>"//g<CR>', { desc = "Delete all matching characters" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- use jkj to exit visual mode
vim.keymap.set("x", "jkj", "<ESC>", { noremap = true, silent = true, expr = false, desc = "Exit visual mode with jkj" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- close buffer
keymap.set("n", "<A-w>", ":bd<CR>", { desc = "Close buffer" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
keymap.set("n", "<leader>sr", "<C-w>r", { desc = "Rotate windows" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

keymap.set("n", "<leader>vrh", "<cmd>vertical resize +2<CR>", { desc = "Resize Vertical Split" })
keymap.set("n", "<leader>vrl", "<cmd>vertical resize -2<CR>", { desc = "Resize Vertical Split" })

keymap.set("n", "<leader>hrk", "<cmd>resize +2<CR>", { desc = "Resize Vertical Split" })
keymap.set("n", "<leader>hrj", "<cmd>resize -2<CR>", { desc = "Resize Vertical Split" })
keymap.set("n", "<leader>kk", "<cmd>lua dustPDF()<CR>", { desc = "Convert Markdown to PDF" })

--keymap.set("n", "<leader>ht", "<cmd>sp term://zsh<CR> <cmd>resize -6<CR>", { desc = "Resize Vertical Split" })
