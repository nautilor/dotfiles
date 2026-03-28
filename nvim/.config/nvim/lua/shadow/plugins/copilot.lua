return {
	"github/copilot.vim",
	config = function()
		-- Disable copilot.vim tab/ghost-text since completions are handled
		-- by copilot_language_server via blink.cmp
		-- vim.g.copilot_no_tab_map = true
		-- vim.g.copilot_assume_mapped = true
	end,
}
