return {
	'neovim/nvim-lspconfig',
	dependencies = { 'saghen/blink.cmp', 'mfussenegger/nvim-jdtls' },
	config = function()
		local HOME = os.getenv("HOME")
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" }
					}
				}
			}
		})

		vim.lsp.config("dartls", {
			cmd = { HOME .. "/.local/flutter/bin/dart", "language-server", "--protocol=lsp" },
			filetypes = { "dart" },
			root_dir = vim.fs.dirname(vim.fs.find({ "pubspec.yaml", ".git" }, { upward = true })[1]),
		})

		vim.lsp.enable({
			"pyright",
			"ts_ls",
			"eslint",
			"clangd",
			"lua_ls",
			"copilot_language_server",
			"qmlls",
			"rust_analyzer",
			"dartls",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = function()
				local jdtls = require("jdtls")
				local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
				local workspace_dir = HOME .. "/.local/share/jdtls-workspace/" .. project_name

				-- Build bundles, filtering out non-OSGi JARs
				local bundles = {}

				-- Java debug adapter from Mason
				vim.list_extend(bundles,
					vim.split(vim.fn.glob(HOME .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/*.jar"),
						"\n"))

				-- Java test from Mason - filter out problematic JARs
				local test_bundles = vim.split(
					vim.fn.glob(HOME .. "/.local/share/nvim/mason/packages/java-test/extension/server/*.jar"), "\n")
				for _, bundle in ipairs(test_bundles) do
					-- Exclude JARs that aren't proper OSGi bundles
					if not bundle:match("com.microsoft.java.test.runner") and
							not bundle:match("jacocoagent") then
						table.insert(bundles, bundle)
					end
				end

				-- Filter out empty strings
				bundles = vim.tbl_filter(function(bundle)
					return bundle ~= ""
				end, bundles)

				local lombok_jar = HOME .. "/.local/share/nvim/mason/share/jdtls/lombok.jar"

				local config = {
					cmd = {
						'jdtls',
						"-configuration",
						HOME .. "/.local/share/nvim/mason/packages/jdtls/config_linux",
						'-data', workspace_dir,
						'--jvm-arg=-javaagent:' .. lombok_jar
					},
					root_dir = require('jdtls.setup').find_root({ 'gradlew', 'mvnw', '.git', 'pom.xml', 'build.gradle',
						'.classpath' }),
					settings = {
						java = {
							configuration = {
								runtimes = {
									{
										name = "JavaSE-21",
										path = "/usr/lib/jvm/java-21-openjdk",
									},
								},
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
					init_options = {
						bundles = bundles, -- Keybindings
					},
					on_attach = function(client, bufnr)
						require("jdtls.dap").setup_dap_main_class_configs()
						require("jdtls.setup").add_commands()
					end,
				}

				jdtls.start_or_attach(config)
			end,
		})
	end
}
