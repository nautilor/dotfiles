-- Plugin to highlight color codes in the buffer
-- If the plugin is working you should see this #FF0000 highlighted in red in the buffer

return {
	'brenoprata10/nvim-highlight-colors',
	opts = {
		render = 'background',
		enable_hex = true,
		enable_short_hex = true,
		enable_rgb = true,
		enable_hsl = true,
		enable_css_variables = false,
		enable_named_colors = false,
	},
}
