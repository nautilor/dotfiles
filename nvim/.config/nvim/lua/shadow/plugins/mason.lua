-- Mason is a plugin that manages external editor tooling such as LSP servers, DAP servers, linters, and formatters through a single interface.

return {
	"williamboman/mason.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
	},
	opts = {
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗"
			}
		}
	}
}
