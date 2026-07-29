-- Treesitter here is used to provide better syntax highlighting and code parsing for various programming languages in Neovim. It allows for more accurate and efficient code analysis, which can enhance the overall coding experience.

return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	opts = {
		ensure_installed = { "java", "python", "c", "lua", "vim", "vimdoc", "javascript", "typescript", "dockerfile", "bash", "markdown", "tsx" },
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true,
		},
		indent = { enable = true },
	},
}
