return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type table
	opts = {
		input = { enabled = false },
		terminal = {
			enabled = true,
			win = {
				position = "float",
				border = "solid",
			},
		},
		notifier = { enabled = false },
		scope = { enabled = false },
		-- <-----------------------> --
		dashboard = {
			enabled = true,
			sections = {
				{ section = "header" },
				{ section = "keys",  gap = 1, padding = 1 },
				{
					title = "──────────────────────────────────────────────────────────────\n",
					section = "terminal",
					enabled = function()
						local Snacks = require("snacks")
						return Snacks.git.get_root() ~= nil
					end,
					cmd = "git status --short --branch",
					padding = 1,
					ttl = 5 * 60,
					indent = 3,
				},
			},
			preset = {
				header = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡶⠿⠿⠷⣶⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠁⠀  ⣠⣄⠙⣷⡀⠀⠀⠀
⠀⠀⠀⡀⠀⠀⠀⠀⠀⢠⣿⠁⠀⠀⠀ ⠙⠋⠀⢸⣿⣿⣿⣿
⠀⣠⡿⠛⢷⣦⡀⠀⠀⠈⣿⡄⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⠟
⢰⡿⠁⠀⠀⠙⢿⣦⣤⣤⣼⣿⣄⠀⠀⠀⠀⠀⢴⡟⠛⠋⠁⠀
⣿⠇⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠈⣿⡀⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀
⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡇⠀⠀⠀
⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⠀⠀⠀⠀
⠀⠹⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣰⡿⠁⠀⠀⠀⠀
⠀⠀⠀⠉⠙⠛⠿⠶⣶⣶⣶⣶⣶⠶⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀
 ]]
			}
		},
		animate = { enabled = true },
		indent = {
			enabled = true,
			animate = {
				enabled = false,
				style = "out",
				easing = "linear",
				duration = {
					step = 10,
					total = 250
				}
			}
		},
		picker = {
			actions = {
				java_explorer_add = function(picker)
					require("shadow.core.java_core").explorer_add(picker)
				end,
				smart_open = function(picker, item)
					if not item then return end
					if item.item == "Yes" then
						picker:action({ "confirm" })
						return
					end
					if not item.dir then
						local can_jump = item.file or item.buf or item.pos or item.search
						if item.file then
							-- bail out if the file no longer exists (e.g. just deleted)
							if not vim.uv.fs_stat(item.file) then return end
							-- if already visible in a window, focus it directly
							local bufnr = vim.fn.bufnr(item.file)
							if bufnr ~= -1 then
								local wins = vim.fn.win_findbuf(bufnr)
								if #wins > 0 then
									picker:close()
									vim.fn.win_gotoid(wins[1])
									return
								end
							end
						end
						if can_jump then
							local ok = picker:action({ "pick_win", "jump" })
							if ok then return end
						end
					end
					picker:action({ "confirm" })
				end
			},
			win = {
				input = {
					keys = {
						["<CR>"] = {
							{
								"smart_open"
							},
							mode = { "n", "i" }
						},
					},
				},
				list = {
					keys = {
						["<CR>"] = { "smart_open" }
					},
				},
			},
			enabled = true,
			sources = {
				explorer = {
					auto_close = true,
					win = {
						list = {
							keys = {
								["a"] = "java_explorer_add",
								["d"] = "explorer_del",
								["r"] = "explorer_rename",
								["c"] = "explorer_copy",
								["p"] = "explorer_paste",
								["u"] = "explorer_update",
								["x"] = "explorer_move",
								["y"] = "explorer_yank",
								["<CR>"] = "smart_open"
							}
						}
					}
				},
			},
		},
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		zen = {
			enabled = true,
			center = true,
			toggles = { dim = true }
		},
	},
}
