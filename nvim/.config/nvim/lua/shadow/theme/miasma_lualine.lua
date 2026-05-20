local colors = {
	base = "#222222",
	surface = "#1c1c1c",
	muted = "#666666",
	fg = "#c2c2b0",
	green = "#5f875f",
	olive = "#78824b",
	orange = "#bb7744",
	gold = "#c9a554",
	brown = "#b36d43",
}

local section = function(accent)
	return {
		a = { bg = accent, fg = colors.base, gui = "bold" },
		b = { bg = colors.surface, fg = colors.fg },
		c = { bg = colors.base, fg = colors.muted },
	}
end

return {
	normal = section(colors.olive),
	insert = section(colors.green),
	visual = section(colors.gold),
	replace = section(colors.brown),
	command = section(colors.orange),
	inactive = {
		a = { bg = colors.base, fg = colors.muted, gui = "bold" },
		b = { bg = colors.base, fg = colors.muted },
		c = { bg = colors.base, fg = colors.muted },
	},
}
