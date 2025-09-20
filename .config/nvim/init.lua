require("dusts.core")
require("dusts.lazy")

-- Manual Installation Codeium
vim.o.packpath = vim.o.packpath .. ",~/.config/nvim"
vim.cmd([[packadd codeium.vim]])

-- ===============================================
--              Codeium Keybindings
-- ===============================================
--
-- Accept Suggestion
vim.keymap.set("i", "<C-g>", function()
	return vim.fn["codeium#Accept"]()
end, { expr = true, silent = true })
-- vim.keymap.set("i", "<c-;>", function()
-- 	return vim.fn["codeium#CycleCompletions"](1)
-- end, { expr = true, silent = true })
--
-- Next Suggestion
vim.keymap.set("i", "<Leader><Tab>", function()
	return vim.fn["codeium#CycleCompletions"](1)
end, { expr = true, silent = true })
-- is this the correct syntax for Leader+Tab?
--vim.keymap.set("i", "<Leader><Tab>", function()
--
-- Previous Suggestion
vim.keymap.set("i", "<S-Tab>", function()
	return vim.fn["codeium#CycleCompletions"](-1)
end, { expr = true, silent = true })
--
-- Clear Suggestion
vim.keymap.set("i", "<c-x>", function()
	return vim.fn["codeium#Clear"]()
end, { expr = true, silent = true })
--
-- vim.keymap.set("i", "<c-,>", function()
-- 	return vim.fn["codeium#CycleCompletions"](-1)
-- end, { expr = true, silent = true })
vim.keymap.set("i", "<c-x>", function()
	return vim.fn["codeium#Clear"]()
end, { expr = true, silent = true })
