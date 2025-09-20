return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	event = {
		"BufReadPre /home/dusts/aston/Notes/Obsidian/aston/**/*.md",
		"BufNewFile /home/dusts/aston/Notes/Obsidian/aston/**/*.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		ui = { enable = false },
		workspaces = {
			{
				name = "work",
				path = "/home/dusts/aston/Notes/Obsidian/aston",
			},
		},
		note_frontmatter_func = function(note)
			local frontmatter = {
				id = note.id,
				aliases = note.aliases,
				tags = note.tags,
			}
			if note.title then
				frontmatter.title = note.title
			end
			if note.metadata then
				for key, value in pairs(note.metadata) do
					frontmatter[key] = value
				end
			end
			if not frontmatter.created then
				frontmatter.created = os.date("%Y-%m-%dT%H:%M:%S", os.time())
			end
			return frontmatter
		end,
	},
}
