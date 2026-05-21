return {
	"xero/miasma.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local group = vim.api.nvim_create_augroup("miasma-transparent-ui", { clear = true })
		local apply_transparent_highlights = function()
			local transparent = {
				"SignColumn",
				"LineNr",
				"LineNrAbove",
				"LineNrBelow",
				"CursorLineNr",
				"FoldColumn",
				"Directory",
			}

			for _, name in ipairs(transparent) do
				local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
				hl.bg = "NONE"
				vim.api.nvim_set_hl(0, name, hl)
			end

			for _, name in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
				vim.api.nvim_set_hl(0, name, {
					bg = "NONE",
					underline = false,
					undercurl = false,
				})
			end
		end

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = group,
			pattern = "miasma",
			callback = apply_transparent_highlights,
		})

		vim.cmd.colorscheme("miasma")
		apply_transparent_highlights()
	end,
}
