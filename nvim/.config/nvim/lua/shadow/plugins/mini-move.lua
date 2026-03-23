return {
	'nvim-mini/mini.move',
	version = '*',
	config = function()
		require('mini.move').setup({
			mappings = {
				left = '<C-Left>',
				right = '<C-Right>',
				down = '<C-Down>',
				up = '<C-Up>',
				line_left = '<C-Left>',
				line_right = '<C-Right>',
				line_down = '<C-Down>',
				line_up = '<C-Up>',
			},
		})
	end
}
