local M = {}

-- Home-row priority key sequence
local HINT_KEYS = { "a", "s", "d", "f", "g", "h", "j", "k", "l", "e", "r", "u", "i", "o", "w", "t", "y", "p" }

local ns_id = nil

-- ─── Highlight groups ────────────────────────────────────────────────────────

local function setup_highlights()
	vim.api.nvim_set_hl(0, "HopHintsTyped", { bg = "#e0af68", fg = "#1F2335", bold = true, default = false })
	vim.api.nvim_set_hl(0, "HopHintsLabel", { bg = "#e0af68", fg = "#1a1b2e", bold = true, default = false })
end

-- ─── Label generation ────────────────────────────────────────────────────────

local function generate_labels(n)
	local labels = {}
	for i = 1, #HINT_KEYS do
		for j = 1, #HINT_KEYS do
			labels[#labels + 1] = HINT_KEYS[i] .. HINT_KEYS[j]
			if #labels >= n then return labels end
		end
	end
	return labels
end

-- ─── Symbol collection ───────────────────────────────────────────────────────

local function collect_positions(bufnr, winid)
	local positions = {}
	local seen = {}

	local function add(row, col, kind)
		local key = row .. ":" .. col
		if not seen[key] then
			seen[key] = true
			positions[#positions + 1] = { row = row, col = col, kind = kind }
		end
	end

	-- Strategy 1: Tree-sitter
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if ok and parser then
		local tree = parser:parse()[1]
		if tree then
			local type_set = {
				function_definition = true,
				function_declaration = true,
				method_definition = true,
				method_declaration = true,
				arrow_function = true,
				function_item = true,
				-- Classes / structs
				class_definition = true,
				class_declaration = true,
				struct_item = true,
				impl_item = true,
				interface_declaration = true,
				-- Variables
				variable_declarator = true,
				assignment_statement = true,
				let_declaration = true,
				const_declaration = true,
				lexical_declaration = true,
				-- Calls
				call_expression = true,
				call = true,
				-- Types
				type_alias_declaration = true,
				type_definition = true,
				-- Control flow
				if_statement = true,
				if_expression = true,
				for_statement = true,
				for_in_statement = true,
				for_expression = true,
				foreach_statement = true,
				while_statement = true,
				while_expression = true,
				loop_expression = true,
			}
			local function walk(node)
				if type_set[node:type()] then
					local row, col = node:start()
					add(row, col, node:type())
				end
				for child in node:iter_children() do walk(child) end
			end
			walk(tree:root())
		end
	end

	-- Strategy 2: Regex fallback
	if #positions == 0 then
		local patterns = {
			{ "^%s*function%s+",         "function" },
			{ "^%s*local%s+function%s+", "function" },
			{ "^%s*def%s+",              "function" },
			{ "^%s*fn%s+",               "function" },
			{ "^%s*func%s+",             "function" },
			{ "^%s*class%s+",            "class" },
			{ "^%s*local%s+%w+%s*=",     "variable" },
			{ "^%s*let%s+",              "variable" },
			{ "^%s*const%s+",            "variable" },
			{ "^%s*var%s+",              "variable" },
		}
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		for row0, line in ipairs(lines) do
			for _, pat in ipairs(patterns) do
				local s = line:find(pat[1])
				if s then add(row0 - 1, s - 1, pat[2]) end
			end
		end
	end

	-- Restrict to visible lines
	local top     = vim.fn.line("w0", winid) - 1
	local bottom  = vim.fn.line("w$", winid) - 1
	local visible = {}
	for _, p in ipairs(positions) do
		if p.row >= top and p.row <= bottom then
			visible[#visible + 1] = p
		end
	end

	table.sort(visible, function(a, b)
		if a.row ~= b.row then return a.row < b.row end
		return a.col < b.col
	end)

	return visible
end

-- ─── Rendering ───────────────────────────────────────────────────────────────

local function render(bufnr, hints, typed)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	for _, hint in ipairs(hints) do
		local chunks = {}
		if #typed > 0 then
			chunks[#chunks + 1] = { typed, "HopHintsTyped" }
		end
		local rest = hint.label:sub(#typed + 1)
		if #rest > 0 then
			chunks[#chunks + 1] = { rest, "HopHintsLabel" }
		end
		vim.api.nvim_buf_set_extmark(bufnr, ns_id, hint.row, hint.col, {
			virt_text     = chunks,
			virt_text_pos = "overlay",
			priority      = 200,
		})
	end
	vim.cmd("redraw") -- flush immediately, no waiting
end

local function clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	vim.cmd("redraw")
end

-- ─── Main ────────────────────────────────────────────────────────────────────

function M.open()
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.api.nvim_get_current_win()

	local positions = collect_positions(bufnr, winid)
	if #positions == 0 then
		vim.notify("hop-hints: no navigable symbols found", vim.log.levels.INFO)
		return
	end

	local labels = generate_labels(#positions)
	local hints  = {}
	for i, pos in ipairs(positions) do
		hints[i] = { label = labels[i], row = pos.row, col = pos.col }
	end

	render(bufnr, hints, "")

	-- ── Synchronous input loop ─────────────────────────────────────────────────
	-- getcharstr() blocks until a key is pressed — zero scheduling overhead,
	-- no event-loop round-trips, input feels completely instant.
	local typed = ""

	while true do
		local key = vim.fn.getcharstr()

		-- Escape → abort
		if key == "\27" then
			clear(bufnr)
			return
		end

		-- Backspace → pop last char and rebuild from original label list
		if key == "\08" or key == "\127" then
			if #typed > 0 then
				typed = typed:sub(1, -2)
				hints = {}
				for i, pos in ipairs(positions) do
					if vim.startswith(labels[i], typed) then
						hints[#hints + 1] = { label = labels[i], row = pos.row, col = pos.col }
					end
				end
				render(bufnr, hints, typed)
			end
			goto continue
		end

		-- Ignore non-hint keys silently
		do
			local valid = false
			for _, k in ipairs(HINT_KEYS) do
				if key == k then
					valid = true; break
				end
			end
			if not valid then goto continue end
		end

		typed = typed .. key

		-- Filter to still-matching hints
		do
			local remaining = {}
			for _, hint in ipairs(hints) do
				if vim.startswith(hint.label, typed) then
					remaining[#remaining + 1] = hint
				end
			end
			hints = remaining
		end

		if #hints == 0 then
			clear(bufnr)
			return
		end

		if #hints == 1 and hints[1].label == typed then
			-- Exact match — jump!
			clear(bufnr)
			vim.api.nvim_win_set_cursor(winid, { hints[1].row + 1, hints[1].col })
			return
		end

		render(bufnr, hints, typed)

		::continue::
	end
end

-- ─── Setup ───────────────────────────────────────────────────────────────────

function M.setup(opts)
	opts = opts or {}

	if opts.keys then
		HINT_KEYS = {}
		for i = 1, #opts.keys do
			HINT_KEYS[#HINT_KEYS + 1] = opts.keys:sub(i, i)
		end
	end

	ns_id = vim.api.nvim_create_namespace("hop_hints")
	setup_highlights()

	local keymap = opts.keymap ~= nil and opts.keymap or "ff"
	if keymap ~= false then
		vim.keymap.set("n", keymap, M.open, { desc = "hop-hints: jump to symbol", silent = true })
	end

	vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })
end

return M
