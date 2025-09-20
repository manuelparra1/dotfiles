return { -- Floating Terminal
	"voldikss/vim-floaterm",
	event = "VimEnter",
	config = function()
		vim.keymap.set("n", "<leader>ft", "<cmd>FloatermToggle<cr>", { desc = "Toggle Floaterm" })
		vim.keymap.set("t", "<leader>ft", "<cmd>FloatermToggle<cr>", { desc = "Exit Floaterm" })
	end,
}
