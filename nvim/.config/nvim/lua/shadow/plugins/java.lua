return {
	{
		"nvim-java/nvim-java",
		ft = "java",
		dependencies = {
			"neovim/nvim-lspconfig",
			"MunifTanjim/nui.nvim",
			"mfussenegger/nvim-dap",
			{
				"JavaHello/spring-boot.nvim",
				commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
			},
		},
		config = function()
			require("java").setup({
				jdk = {
					auto_install = false,
				},
				lombok = {
					enabled = true,
				},
				java_test = {
					enabled = true,
				},
				spring_boot_tools = {
					enabled = true,
				},
				java_debug_adapter = {
					enabled = true,
				},
			})

			vim.lsp.config("jdtls", {
				root_dir = function(bufnr, on_dir)
					local name = vim.api.nvim_buf_get_name(bufnr)

					local root = vim.fs.root(name, {
						".git",
						"mvnw",
						"gradlew",
						"pom.xml",
						"build.gradle",
						"build.gradle.kts",
					})

					if root then
						on_dir(root)
					end
				end,

				settings = {
					java = {
						autobuild = {
							enabled = true,
						},

						configuration = {
							updateBuildConfiguration = "automatic",

							runtimes = {
								{
									name = "JavaSE-21",
									path = "/usr/lib/jvm/java-21-openjdk",
									default = true,
								},
							},
						},

						import = {
							gradle = {
								annotationProcessing = {
									enabled = true,
								},
							},
						},

						symbols = {
							includeGeneratedCode = true,
						},

						gradle = {
							downloadSources = true,
						},

						eclipse = {
							downloadSources = true,
						},

						maven = {
							downloadSources = true,
						},
					},
				},
			})

			vim.lsp.enable("jdtls")
		end,
	},

	{
		"mfussenegger/nvim-dap",

		config = function()
			local dap = require("dap")

			dap.adapters.java_attach = function(callback)
				dap.adapters.java(function(adapter)
					adapter = vim.deepcopy(adapter)
					adapter.enrich_config = nil
					callback(adapter)
				end)
			end

			vim.keymap.set("n", "<F5>", function()
				dap.continue()
			end, { silent = true, desc = "Debug: continue" })

			vim.keymap.set("n", "<F9>", function()
				dap.toggle_breakpoint()
			end, { silent = true, desc = "Debug: toggle breakpoint" })

			vim.keymap.set("n", "<F10>", function()
				dap.step_over()
			end, { silent = true, desc = "Debug: step over" })

			vim.keymap.set("n", "<F11>", function()
				dap.step_into()
			end, { silent = true, desc = "Debug: step into" })

			vim.keymap.set("n", "<F12>", function()
				dap.step_out()
			end, { silent = true, desc = "Debug: step out" })
		end,
	},

	{
		"rcarriga/nvim-dap-ui",

		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},

		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({
				floating = {
					border = "solid",
				},
			})

			dap.listeners.before.attach.dapui = function()
				dapui.open()
			end

			dap.listeners.before.launch.dapui = function()
				dapui.open()
			end

			dap.listeners.before.event_terminated.dapui = function()
				dapui.close()
			end

			dap.listeners.before.event_exited.dapui = function()
				dapui.close()
			end

			vim.keymap.set("n", "<leader>du", function()
				dapui.toggle()
			end, { silent = true, desc = "Debug: toggle UI" })

			vim.keymap.set("n", "<leader>de", function()
				dapui.eval()
			end, { silent = true, desc = "Debug: eval" })
		end,
	},

	{
		"theHamsta/nvim-dap-virtual-text",

		dependencies = {
			"mfussenegger/nvim-dap",
		},

		opts = {},
	},
}
