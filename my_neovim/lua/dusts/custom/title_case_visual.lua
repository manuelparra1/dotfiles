local function titleCaseVisual()
	-- Get the start and end lines of the visually selected area
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	-- Construct the range for the substitution command
	local range = string.format("%d,%ds", start_line, end_line)

	-- Execute the substitution command only for the selected range
	vim.cmd(range .. "/\\(\\w\\+\\)/\\u\\L\\1/g")

	-- Clear the highlighting of the last search pattern
	vim.cmd("nohlsearch")
end

-- Set up an autocmd to load the Lua script when editing Lua files
vim.cmd([[
augroup TitleCaseVisualAutocmd
    autocmd!
    autocmd FileType lua lua require("dusts.custom.title_case_visual").setup()
augroup END
]])

-- Set up the keybinding to trigger the function
vim.api.nvim_set_keymap(
	"v",
	"<Leader>T",
	':lua require("dusts.custom.title_case_visual").titleCaseVisual()<CR>',
	{ noremap = true, silent = true }
)

-- Return the function and setup function so it can be called from elsewhere if needed
return {
	titleCaseVisual = titleCaseVisual,
	setup = function()
		-- Additional setup can be added here if needed
	end,
}
