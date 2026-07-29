-- Plugin to view and compare code changes in Neovim

return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	config = function()
		require("codediff").setup({
			explorer = {
				view_mode = "tree"
			},
			keymaps = {
				view = {
					toggle_explorer = "<leader>e",
					focus_explorer = "<leader>b",
					close = "<leader>q",
					switch_diff = "<tab>",
					next_file = "]f",
					prev_file = "[f",
					next_hunk = "]c",
					prev_hunk = "[c",
				},
			},
		})
	end,
}
