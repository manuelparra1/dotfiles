return {
	"akinsho/bufferline.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	version = "*",
	opts = {
		options = {
			buffer_close_icon = "",
			show_buffer_close_icons = true,
			indicator = {
				icon = "▎", -- this should be omitted if indicator style is not 'icon'
			},
			close_icon = "",
			mode = "buffers",
			separator_style = "slant",
		},
		highlights = {
			fill = {
				--bg = "#101019",
				bg = "#1a1c27",
				fg = "#1a1c27",
				--fg = "#101019",
			},
		},
	},
}
