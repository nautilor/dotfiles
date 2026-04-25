local M = {}

local state = {
	win = nil,
}

local function is_open()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function reset_if_closed(win)
	vim.api.nvim_create_autocmd("WinClosed", {
		once = true,
		callback = function(args)
			if tonumber(args.match) == win then
				state.win = nil
			end
		end,
	})
end

local function attach_float_keys(bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }
	vim.keymap.set("n", "<Esc>", M.close, opts)
	vim.keymap.set("n", "K", M.close, opts)
end

local function track_float(bufnr, win)
	state.win = win
	attach_float_keys(bufnr)
	reset_if_closed(win)
end

local function first_location(result)
	if not result then
		return nil
	end

	if result.uri or result.targetUri then
		return result
	end

	if vim.islist(result) and result[1] then
		return result[1]
	end

	return nil
end

local function count_pattern(text, pattern)
	local _, count = text:gsub(pattern, "")
	return count
end

local function get_location_parts(location)
	local uri = location.targetUri or location.uri
	local range = location.targetRange or location.range or location.targetSelectionRange

	if not uri or not range then
		return nil
	end

	return uri, range
end

local function expand_single_line_range(bufnr, start_line)
	local max_line = math.min(vim.api.nvim_buf_line_count(bufnr), start_line + 40)
	local lines = {}
	local curly, paren, square = 0, 0, 0
	local saw_delimiter = false

	for line_nr = start_line, max_line - 1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
		local trimmed = vim.trim(line)
		table.insert(lines, line)

		curly = curly + count_pattern(line, "{") - count_pattern(line, "}")
		paren = paren + count_pattern(line, "%(") - count_pattern(line, "%)")
		square = square + count_pattern(line, "%[") - count_pattern(line, "%]")

		if line:find("[{%(%[]") then
			saw_delimiter = true
		end

		if not saw_delimiter and trimmed:match(";$") then
			break
		end

		if saw_delimiter and curly <= 0 and paren <= 0 and square <= 0 and trimmed ~= "" then
			break
		end
	end

	return vim.lsp.util.trim_empty_lines(lines)
end

local function get_location_lines(location)
	local uri, range = get_location_parts(location)
	if not uri then
		return nil
	end

	local bufnr = vim.uri_to_bufnr(uri)
	vim.fn.bufload(bufnr)

	local start_line = range.start.line
	local end_line = range["end"].line
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

	if #lines <= 1 then
		lines = expand_single_line_range(bufnr, start_line)
	else
		lines = vim.lsp.util.trim_empty_lines(lines)
	end

	if vim.tbl_isempty(lines) then
		return nil
	end

	return lines, vim.bo[bufnr].filetype
end

local function request_first_result(method, callback)
	local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
	if #clients == 0 then
		callback(nil)
		return
	end

	vim.lsp.buf_request_all(0, method, vim.lsp.util.make_position_params(), function(results)
		for _, response in pairs(results) do
			local result = response and response.result
			local item = method == "textDocument/hover" and result or first_location(result)
			if item then
				callback(item)
				return
			end
		end

		callback(nil)
	end)
end

local function open_location_preview(location)
	local lines, filetype = get_location_lines(location)
	if not lines then
		return false
	end

	local bufnr, win = vim.lsp.util.open_floating_preview(lines, filetype or "text", {
		border = "solid",
		focusable = true,
	})

	if win and vim.api.nvim_win_is_valid(win) then
		track_float(bufnr, win)
		return true
	end

	return false
end

local function open_hover_preview(hover)
	local contents = hover.contents
	if not contents then
		return false
	end

	local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)
	lines = vim.lsp.util.trim_empty_lines(lines)
	if vim.tbl_isempty(lines) then
		return false
	end

	local bufnr, win = vim.lsp.util.open_floating_preview(lines, "markdown", {
		border = "solid",
		focusable = true,
	})

	if win and vim.api.nvim_win_is_valid(win) then
		track_float(bufnr, win)
		return true
	end

	return false
end

function M.close()
	if is_open() then
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
end

function M.toggle()
	if is_open() then
		M.close()
		return
	end

	request_first_result("textDocument/typeDefinition", function(type_definition)
		if type_definition and open_location_preview(type_definition) then
			return
		end

		request_first_result("textDocument/definition", function(definition)
			if definition and open_location_preview(definition) then
				return
			end

			request_first_result("textDocument/hover", function(hover)
				if hover and open_hover_preview(hover) then
					return
				end

				vim.notify("No type preview available for the symbol under cursor.", vim.log.levels.INFO)
			end)
		end)
	end)
end

function M.is_open()
	return is_open()
end

return M
