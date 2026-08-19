-- Plugin to show a status line at the bottom of the screen
local colors = {
	red     = "#F7768E",
	green   = "#9ECE6A",
	blue    = "#7AA2F7",
	cyan    = "#7DCFFF",
	yellow  = "#E0AF68",
	purple  = "#BB9AF7",

	fg      = "#C0CAF5",
	muted   = "#565F89",
}

local custom_theme = {
	normal = {
		a = { fg = colors.red, bg = "NONE", gui = "bold" },
		b = { fg = colors.blue, bg = "NONE" },
		c = { fg = colors.fg, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.green, bg = "NONE" },
		z = { fg = colors.green, bg = "NONE" },
	},

	insert = {
		a = { fg = colors.green, bg = "NONE", gui = "bold" },
		b = { fg = colors.blue, bg = "NONE" },
		c = { fg = colors.fg, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.green, bg = "NONE" },
		z = { fg = colors.green, bg = "NONE" },
	},

	visual = {
		a = { fg = colors.purple, bg = "NONE", gui = "bold" },
		b = { fg = colors.blue, bg = "NONE" },
		c = { fg = colors.fg, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.green, bg = "NONE" },
		z = { fg = colors.green, bg = "NONE" },
	},

	replace = {
		a = { fg = colors.red, bg = "NONE", gui = "bold" },
		b = { fg = colors.blue, bg = "NONE" },
		c = { fg = colors.fg, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.green, bg = "NONE" },
		z = { fg = colors.green, bg = "NONE" },
	},

	command = {
		a = { fg = colors.yellow, bg = "NONE", gui = "bold" },
		b = { fg = colors.blue, bg = "NONE" },
		c = { fg = colors.fg, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.green, bg = "NONE" },
		z = { fg = colors.green, bg = "NONE" },
	},

	inactive = {
		a = { fg = colors.muted, bg = "NONE" },
		b = { fg = colors.muted, bg = "NONE" },
		c = { fg = colors.muted, bg = "NONE" },
		x = { fg = colors.muted, bg = "NONE" },
		y = { fg = colors.muted, bg = "NONE" },
		z = { fg = colors.muted, bg = "NONE" },
	},
}

return {
	'nvim-lualine/lualine.nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	init = function()
		vim.opt.laststatus = 3
	end,
	opts = {
		options = {
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			theme = custom_theme,
		},
		sections = {
			lualine_a = {
				{
					"mode",
					icon_enable = true,
					fmt = function()
						return vim.api.nvim_get_mode().mode == "t" and ""
								or ""
					end,
					separator = { left = "" }
				},
				{
					"mode",
					separator = { right = "" }
				}
			},
			lualine_b = {
				{
					"branch",
					icon = { "", align = "left" }
				},
				{
					"diff",
					separator = { right = "" }
				}
			},
			lualine_c = {
			},
			lualine_x = {
			},
			lualine_y = {
				{
					"filename",
					path = 1,
					fmt = function(filename)
						if filename == "" then
							return "[No Name]"
						end
						local parts = vim.split(filename, "/")
						if #parts > 1 then
							return parts[#parts - 1] .. "/" .. parts[#parts]
						else
							return filename
						end
					end,
				},
				{ "progress", icon_only = false, },
			},
			lualine_z = {
				{
					"selectioncount",
					fmt = function(count)
						if count == "" then
							return ""
						end
						return "[" .. count .. "]"
					end,
				},
				{
					"location",
					fmt = function(location)
						return location:gsub("%s+", "")
					end,
					separator = { right = "", left = "" }
				},
			},
		},
	}
}
