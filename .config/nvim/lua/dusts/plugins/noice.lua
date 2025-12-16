return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		-- add any options here
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},

	require("noice").setup({
		routes = {
			-- Force show "recording @" messages in the Noice commandline
			{
				filter = {
					event = "msg_show",
					kind = "",
					find = "recording @",
				},
				view = "cmdline", -- or "notify" if you want a popup
			},
		},
	}),
}
