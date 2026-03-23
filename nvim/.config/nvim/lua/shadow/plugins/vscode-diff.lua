return {
	"esmuellert/vscode-diff.nvim",
	dependencies = { "MunifTanjim/nui.nvim" },
	cmd = "CodeDiff",
	config = function()
		require("vscode-diff").setup({
			explorer = {
				view_mode = "tree"
			},
			keymaps = {
				close = "q",
				toggle_explorer = "<leader>e",
				switch_diff = "<tab>",
				next_file = "]f",
				prev_file = "[f",
				next_hunk = "]c",
				prev_hunk = "[c",
			},
		})
	end,
}
