vim.api.nvim_create_autocmd("FileType", {
	pattern = { "csv" },
	callback = function(args)
		local bufnr = args.buf
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
		local delimiters = { ",", ";", "\t", "|" }

		local function count_fields(line, delimiter)
			local count = 0

			for _ in line:gmatch(vim.pesc(delimiter)) do
				count = count + 1
			end

			return count + 1
		end

		local function detect_delimiter()
			local best_delimiter = ","
			local best_score = 0

			for _, delimiter in ipairs(delimiters) do
				local counts = {}

				for _, line in ipairs(lines) do
					if line ~= "" then
						table.insert(counts, count_fields(line, delimiter))
					end
				end

				if #counts > 0 then
					local frequency = {}

					for _, count in ipairs(counts) do
						frequency[count] = (frequency[count] or 0) + 1
					end

					local max_frequency = 0
					local fields = 0

					for field_count, freq in pairs(frequency) do
						if freq > max_frequency then
							max_frequency = freq
							fields = field_count
						end
					end

					if fields > 1 then
						local score = max_frequency * fields

						if score > best_score then
							best_score = score
							best_delimiter = delimiter
						end
					end
				end
			end

			return best_delimiter
		end

		local delimiter = detect_delimiter()

		vim.cmd(string.format(
			"CsvViewEnable delimiter=%s display_mode=border header_lnum=1",
			vim.fn.escape(delimiter, " ")
		))
	end,
})

return {
	"hat0uma/csvview.nvim",
	opts = {
		parser = { comments = { "#", "//" } },
		display_mode = "border",
		border = "│",
		keymaps = {
			textobject_field_inner = { "if", mode = { "o", "x" } },
			textobject_field_outer = { "af", mode = { "o", "x" } },
			jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
			jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
			jump_next_row = { "<Enter>", mode = { "n", "v" } },
			jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
		},
	},
	cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
}
