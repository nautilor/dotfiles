-- Timber.nvim is a logging plugin for Neovim that allows you to easily log messages to a file or the console. It provides a simple API for logging messages, and it can be configured to log messages to different targets (e.g., file, console, etc.).

-- glj -> insert log below
-- glk -> insert log above
-- glo -> insert plain log below
-- glp -> insert plain log above (fake but possible)
-- gla -> add a log target to the batch
-- glc -> print the batch

return {
	"Goose97/timber.nvim",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("timber").setup({})
	end
}
