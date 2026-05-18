return {
	'stevearc/conform.nvim',
	opts = {
		formatters = {
			intellij_java = {
				inherit = false,
				command = function()
					return vim.fn.exepath("idea") ~= "" and "idea" or "idea.sh"
				end,
				args = { "format", "-allowDefaults", "$FILENAME" },
				stdin = false,
				cwd = function(_, ctx)
					return vim.fs.root(ctx.filename, { ".idea", ".editorconfig", ".git", "mvnw", "gradlew" })
				end,
				require_cwd = false,
				condition = function()
					return vim.fn.executable("idea") == 1 or vim.fn.executable("idea.sh") == 1
				end,
			},
		},
		formatters_by_ft = {
			java = { "intellij_java", lsp_format = "fallback" },
			python = { "black" },
			typescript = { 'prettierd', "prettier", stop_after_first = true },
			typescriptreact = { 'prettierd', "prettier", stop_after_first = true },
			javascript = { 'prettierd', "prettier", stop_after_first = true },
			javascriptreact = { 'prettierd', "prettier", stop_after_first = true },
			json = { 'prettierd', "prettier", stop_after_first = true },
			html = { 'prettierd', "prettier", stop_after_first = true },
			css = { 'prettierd', "prettier", stop_after_first = true },
		},
		format_on_save = {
			lsp_fallback = true,
			timeout_ms = 500
		}
	}
}
