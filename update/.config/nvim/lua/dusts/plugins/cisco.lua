return {
	"momota/cisco.vim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("Comment").setup()
	end,
}
