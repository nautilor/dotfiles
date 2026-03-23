local colors = require("tokyonight.colors").setup({
	style = "night",
})

return {
	'akinsho/toggleterm.nvim',
	version = "*",
	opts = {
		shade_terminal = false,
		highlights = {
			NormalFloat = {
				guifg = colors.fg_dark,
				guibg = colors.bg_float,
			},
		},
		float_opts = {
			border = "solid",
		}
	},
}
