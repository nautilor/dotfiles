return {
	"saghen/blink.cmp",
	dependencies = { 'rafamadriz/friendly-snippets' },
	event = { "LspAttach" },
	version = '*',
	opts = {
		keymap = { preset = 'super-tab' },
		signature = { enabled = true },
		sources = {
			default = {
				"lsp",
				"path",
				"buffer",
			}
		},
		completion = {
			menu = {
				auto_show = true,
				draw = {
					columns = {
						{ "label",     "label_description", gap = 1 },
						{ "kind_icon", "kind" }
					}
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
			},
			ghost_text = { enabled = false },
		}
	}
}
