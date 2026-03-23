return {
	"folke/tokyonight.nvim",
	priority = 1000,
	opts = {
		colorscheme = "tokyonight-night",
		transparent = true,
		on_colors = function(colors)
			colors.border = "#7AA2F7"
		end,
		styles = {
			sidebars = "transparent",
			floats = "dark",
		},
	},

	config = function(_, opts)
		require("tokyonight").setup(opts)
		vim.cmd.colorscheme(opts.colorscheme)
	end,

}
