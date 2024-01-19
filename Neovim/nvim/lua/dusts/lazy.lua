require("lazy").setup({ { import = "dusts.plugins" }, { import = "dusts.plugins.lsp" } }, {
	install = {
		colorscheme = { "catppuccin-frappe" },
	},
	checker = {
		enabled = true,
		notify = false,
	},
	change_detection = {
		notify = false,
	},
})
