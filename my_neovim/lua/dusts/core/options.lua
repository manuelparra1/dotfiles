vim.opt.autoindent = true -- copy indent from current line when starting new one
vim.opt.background = "dark" -- colorschemes that can be light or dark will be made dark
vim.opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position
vim.opt.backup = true -- automatically save a backup file
vim.opt.backupdir:remove(".") -- keep backups out of the current directory
vim.opt.breakindent = true -- maintain indent when wrapping indented lines
vim.opt.nrformats:append("alpha")
vim.opt.clipboard = "unnamedplus" -- Use Linux system clipboard
vim.opt.clipboard:append("unnamedplus") -- use system clipboard as default register
vim.opt.completeopt = "menuone,longest,preview"
vim.opt.confirm = true -- ask for confirmation instead of erroring
vim.opt.cursorline = true -- highlight the current cursor line
vim.opt.expandtab = true -- expand tab to spaces
vim.opt.exrc = true
vim.opt.fillchars:append({ eob = " " }) -- remove the ~ from end of buffer
vim.opt.ignorecase = true -- ignore case when searching
--vim.opt.list = true -- enable the below listchars
--vim.opt.listchars = { tab = "▸ ", trail = "·" }
vim.opt.mouse = "a" -- enable mouse for all modes
vim.opt.number = true -- shows absolute line number on cursor line (when relative number is on)
vim.opt.redrawtime = 10000 -- Allow more time for loading syntax on large files
vim.opt.relativenumber = false -- show relative line numbers
vim.opt.scrolloff = 8
vim.opt.secure = true
vim.opt.shiftwidth = 4
vim.opt.shortmess:append({ I = true }) -- disable the splash screen
vim.opt.showmode = false
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes" -- show sign column so that text doesn't shift
--vim.opt.signcolumn = "yes:2"
vim.opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.spell = false
vim.opt.splitbelow = true -- split horizontal window to the bottom
vim.opt.splitright = true -- split vertical window to the right
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.title = true
vim.opt.undofile = true -- persistent undo
vim.opt.updatetime = 4001 -- Set updatime to 1ms longer than the default to prevent polyglot from changing it
vim.opt.wildmode = "longest:full,full" -- complete the longest common match, and allow tabbing the results to fully complete them
vim.opt.wrap = true -- disable line wrapping
vim.g.tokyonight_style = "storm" -- available: night, storm
vim.g.tokyonight_enable_italic = 1

function dustPDF()
	local filepath = vim.fn.expand("%:p:h") -- Get the path of the current file
	local filename = vim.fn.expand("%:t:r") -- Get the filename without extension
	local output_path = filepath .. "/" .. filename .. ".pdf"
	vim.cmd(":w | !pandoc % -o " .. output_path)
end
