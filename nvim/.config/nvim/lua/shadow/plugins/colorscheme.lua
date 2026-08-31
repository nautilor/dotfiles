-- Colorscheme configuration for Neovim

return {
	"nautilor/onedark.nvim",
	priority = 1000,
	opts = {
		colorscheme = "onedark",
		style = "darker",
		transparent = true,
	},

	config = function(_, opts)
		require("onedark").setup(opts)
		vim.cmd.colorscheme(opts.colorscheme)
	end,

}
