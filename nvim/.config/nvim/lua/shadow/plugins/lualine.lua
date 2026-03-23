return {
	'nvim-lualine/lualine.nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	init = function()
		vim.opt.laststatus = 3
	end,
	opts = {
		options = {
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			theme = "tokyonight",
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
					separator = { right = "" }
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
					separator = { right = "", left = "" }
				},
			},
		},
	}
}
