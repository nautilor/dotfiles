return {
	'neovim/nvim-lspconfig',
	dependencies = { 'saghen/blink.cmp' },
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
	end
}
