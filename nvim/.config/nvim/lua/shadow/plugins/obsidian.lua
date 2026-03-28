return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	---@module 'obsidian'
	---@type table
	opts = {
		note_id_func = function(title)
			return title
		end,
		legacy_commands = false,
		workspaces = {
			{
				name = "Notes",
				path = "~/.obsidian/Notes",
			}
		},
	},
}
