-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- ======================
-- dusts Custom Functions
-- ======================

-- Clean Markdown Citations Perplexity Deep Research
-- -------------------------------------------------

-- Function to clean up markdown citations and remove Perplexity footer
function CleanMarkdownCitations()
	-- Store cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	-- Get all lines
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- First pass: Remove Perplexity footer and identify reference section
	local filtered_lines = {}
	local ref_start_line = nil
	local in_code_block = false
	local i = 1

	while i <= #lines do
		local line = lines[i]

		-- Check for code block markers
		if line:match("^```") then
			in_code_block = not in_code_block
		end

		-- Check for Perplexity footer pattern (only outside code blocks)
		if
			not in_code_block
			and i + 2 <= #lines
			and line:match("^%-%-%-$")
			and lines[i + 1]:match("^%s*$")
			and lines[i + 2]:match("^Answer from Perplexity: pplx%.ai/share")
		then
			-- Skip these three lines
			i = i + 3
		else
			-- Find reference section start (if not already found)
			if not ref_start_line and not in_code_block and (line:match("^%[%d+%]:") or line:match("^Citations:")) then
				ref_start_line = #filtered_lines + 1
			end

			-- Keep this line
			table.insert(filtered_lines, line)
			i = i + 1
		end
	end

	-- If we didn't find the reference section, set it to the end
	if not ref_start_line then
		ref_start_line = #filtered_lines + 1
	end

	-- Second pass: Process content and references
	in_code_block = false
	for i = 1, #filtered_lines do
		-- Check for code block markers
		if filtered_lines[i]:match("^```") then
			in_code_block = not in_code_block
		end

		if not in_code_block then
			if i < ref_start_line then
				-- Content section
				local line = filtered_lines[i]

				-- Step 1: Separate adjacent bracketed numbers
				line = line:gsub("%]%[", "] [")

				-- Step 2: Add superscript tags to citations
				line = line:gsub("%[(%d%d?%d?)%]", "<sup>[[%1]][%1]</sup>")

				-- Step 3: Fix redundant superscript tags
				line = line:gsub("</sup> <sup>", ", ")

				filtered_lines[i] = line
			else
				-- Reference section
				local line = filtered_lines[i]

				-- Step 5: Remove "Citations:" heading
				if line:match("^Citations:$") then
					filtered_lines[i] = ""
				else
					-- Step 4: Add colon after reference numbers if missing
					line = line:gsub("^(%[%d+%])([^:])", "%1:%2")
					filtered_lines[i] = line
				end
			end
		end
	end

	-- Update buffer
	vim.api.nvim_buf_set_lines(0, 0, -1, false, filtered_lines)

	-- Restore cursor position (ensuring it's still valid)
	cursor_pos[1] = math.min(cursor_pos[1], #filtered_lines)
	pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)

	print("Markdown citations cleaned up!")
end

-- Markdown Only
-- Make command and mapping only available in markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		-- Create buffer-local command
		vim.api.nvim_buf_create_user_command(0, "CleanMarkdownCitations", CleanMarkdownCitations, {})

		-- Add buffer-local keybinding
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<leader>mx",
			":CleanMarkdownCitations<CR>",
			{ noremap = true, silent = true, desc = "Clean Perplexity Markdown Citations" }
		)
	end,
})

-- Convert To Title Case
-- ---------------------
local function titleCaseVisual()
	-- Get the start and end position of the visual selection
	local _, start_col = unpack(vim.fn.getpos("'<"), 2)
	local _, end_col = unpack(vim.fn.getpos("'>"), 2)
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	-- Iterate over the lines in the visual selection
	for line_num = start_line, end_line do
		local line = vim.fn.getline(line_num)
		local start = line_num == start_line and start_col or 1
		local end_pos = line_num == end_line and end_col or #line

		-- Select the substring within the visual range
		local selected_text = line:sub(start, end_pos)
		local title_cased_text = selected_text:gsub("(%a)(%w*)", function(first, rest)
			return first:upper() .. rest:lower()
		end)

		-- Replace the visual selection with the title-cased text
		line = line:sub(1, start - 1) .. title_cased_text .. line:sub(end_pos + 1)
		vim.fn.setline(line_num, line)
	end

	vim.cmd("nohlsearch")
end

-- Define the titleCaseVisual function in the global Lua environment
_G.titleCaseVisual = titleCaseVisual

local function quick_spell_correct()
	vim.cmd("set spell")
	vim.cmd("normal! gv")
	local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
	local word = vim.fn.expand("<cword>")
	local suggestions = vim.fn.spellsuggest(word, 1)

	if #suggestions == 0 then
		vim.notify("No misspelled word found.", vim.log.levels.INFO, { title = "Spell Check" })
	else
		-- Replace the word with the first suggestion
		vim.api.nvim_buf_set_text(0, line - 1, col - 1, line - 1, col + #word - 1, { suggestions[1] })
	end

	vim.cmd("set nospell")
	vim.cmd("normal! gv")
end

-- Define the quick_spell_correct function in the global Lua environment
_G.quick_spell_correct = quick_spell_correct

-- Set up the keybind for visual mode
vim.api.nvim_set_keymap(
	"v",
	"<leader>ss",
	-- ':lua require("quick_spell_correct").quick_spell_correct()<CR>',
	-- Should be either:
	":lua quick_spell_correct()<CR>", -- if using _G.quick_spell_correct
	{ noremap = true, silent = true }
)

-- Define the titleCaseVisual function in the global Lua environment
_G.titleCaseVisual = titleCaseVisual

-- Use convert-to-title-case function
vim.api.nvim_set_keymap("v", "<Leader>T", ":lua titleCaseVisual()<CR>", { noremap = true, silent = true })
--

-- dusts Custom Keymaps
-- Set up the key mapping for insert mode
vim.api.nvim_set_keymap("i", "jk", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "jkj", "<Esc>", { noremap = true, silent = true })

-- move up splits
vim.api.nvim_set_keymap("n", "<leader>k", "<C-w>k", { noremap = true, silent = true })

-- move down splits
vim.api.nvim_set_keymap("n", "<leader>j", "<C-w>j", { noremap = true, silent = true })

-- move left splits
vim.api.nvim_set_keymap("n", "<leader>h", "<C-w>h", { noremap = true, silent = true })

-- move right splits
vim.api.nvim_set_keymap("n", "<leader>l", "<C-w>l", { noremap = true, silent = true })

-- Change inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap("n", "ciw", '"_ciw', { noremap = true, silent = true })

-- Change inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap("n", 'ci"', '"_ci"', { noremap = true, silent = true })

-- Delete inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap("n", "diw", '"_diwh', { noremap = true, silent = true })

-- Delete inner word and save to custom register _ (black hole register)
vim.api.nvim_set_keymap("n", 'di"', '"_di"h', { noremap = true, silent = true })

-- Delete line and save to custom register _ (black hole register)
vim.api.nvim_set_keymap("n", "dd", '"_dd', { noremap = true, silent = true })

-- bullet lists
-- Add alpha format to nrformats
vim.opt.nrformats:append("alpha")

-- Helper function to find paragraph boundaries
local function get_paragraph_range()
	local current_line = vim.fn.line(".")
	local start_line = current_line
	local end_line = current_line
	local total_lines = vim.fn.line("$")

	-- Find start of paragraph (go up until we hit an empty line or start of buffer)
	while start_line > 1 do
		local line_content = vim.fn.getline(start_line - 1)
		if line_content:match("^%s*$") then -- empty or whitespace-only line
			break
		end
		start_line = start_line - 1
	end

	-- Find end of paragraph (go down until we hit an empty line or end of buffer)
	while end_line < total_lines do
		local line_content = vim.fn.getline(end_line + 1)
		if line_content:match("^%s*$") then -- empty or whitespace-only line
			break
		end
		end_line = end_line + 1
	end

	return start_line, end_line
end

-- Core function that does the formatting on a given range
local function format_range_as_list(start_line, end_line)
	-- Ensure start_line is always the smaller number
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	-- Get the lines in the range
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local char_code = string.byte("A")

	-- Format each line with a letter prefix
	for i, line_content in ipairs(lines) do
		-- Skip empty lines
		if not line_content:match("^%s*$") then
			local prefix = string.char(char_code) .. ". "
			lines[i] = prefix .. line_content
			char_code = char_code + 1
		end
	end

	-- Replace the original lines with the formatted ones
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)

	-- Position cursor at the end of the formatted list
	vim.api.nvim_win_set_cursor(0, { end_line, 0 })
end

-- Keymap for VISUAL mode
vim.keymap.set("v", "<leader>aa", function()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	format_range_as_list(start_line, end_line)
end, { desc = "Create lettered list from visual selection" })

-- Keymap for NORMAL mode - uses paragraph detection
vim.keymap.set("n", "<leader>aa", function()
	local start_line, end_line = get_paragraph_range()
	format_range_as_list(start_line, end_line)
end, { desc = "Create lettered list from current paragraph" })

-- delete all matching characters, visually selected
vim.keymap.set("x", "<leader>x", 'y:%s/<C-R>"//g<CR>', { desc = "Delete all matching characters" })

-- use convert-to-title-case function
-- vim.api.nvim_set_keymap("v", "<Leader>T", ":lua titleCaseVisual()<CR>", { noremap = true, silent = true })

local markdown_stripper = require("dusts.core.markdown_stripper")
vim.keymap.set("n", "<leader>ms", markdown_stripper.strip_formatting, {
	desc = "Strip unwanted markdown formatting",
	silent = true,
})

-- Create a group for our autocommands to keep things tidy
local obsidian_helpers = vim.api.nvim_create_augroup("ObsidianHelpers", { clear = true })

-- This autocommand runs whenever a markdown file is displayed in a window.
-- Using BufWinEnter as it fires later than FileType, giving plugins more time to load.
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*.md", -- Match all markdown files
  group = obsidian_helpers,
  callback = function(args)
    -- Defer the entire logic to push it to the end of the event queue.
    -- This is the most robust way to ensure all other startup/buffer-enter
    -- logic has completed.
    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      local path = vim.api.nvim_buf_get_name(args.buf)
      local workspace_path = "/home/dusts/aston/Notes/Obsidian/aston/"
      
      -- Check if the buffer's path is in our workspace
      if path:find(workspace_path, 1, true) then
        -- If it's in the vault, create the keymap only for this buffer
        vim.keymap.set("n", "<leader>to", function()
          require("custom.autotag").generate_and_apply_tags()
        end, { buffer = args.buf, desc = "Obsidian: Generate LLM Tags" })
      end
    end, 100) -- A 100ms delay for good measure.
  end,
})