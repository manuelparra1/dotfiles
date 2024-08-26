return {
	{
		-- "folke/tokyonight.nvim",
		-- "catppuccin/nvim",
		"maxmx03/fluoromachine.nvim",
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			-- require("catppuccin").setup({
			-- 	flavour = "macchiato", -- latte, frappe, macchiato, mocha
			-- })
			-- vim.cmd.colorscheme("catppuccin")

			require("fluoromachine").setup({
				theme = "retrowave", -- fluoromachine, retrowave, delta
			})

			vim.cmd.colorscheme("fluoromachine")
		end,
	},
}
