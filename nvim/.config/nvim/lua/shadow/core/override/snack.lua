local palette = {
	-- Base (Tokyo Night Moon)
	bg       = 0x1A1B26, -- base background (Moon)
	surface1 = 0x16161F, -- inset / darker panels
	surface2 = 0x1F2030, -- raised surfaces
	surface3 = 0x25263A, -- active / hover

	-- Foregrounds
	fg       = 0xC8D3F5, -- Moon foreground
	fg_muted = 0x545C7E, -- comments / muted text

	-- Accents (Moon-tuned)
	primary  = 0x82AAFF, -- Moon blue
	fun      = 0x86E1FC, -- cyan (functions)
	special  = 0xFFC777, -- warm accent

	-- UI
	border   = 0x3B4261,
	black    = 0x13131B,
}


local sethl = function(...)
	vim.api.nvim_set_hl(0, ...)
end
local autocmd = vim.api.nvim_create_autocmd
local utils = {}

utils.blend = function(what, into, amount)
	amount = amount or 0.5
	amount = math.max(0, math.min(1, amount))

	-- Convert colors to numbers if they're strings
	if type(into) == "string" then
		into = tonumber(into:gsub("#", ""), 16) or 0
	elseif type(into) ~= "number" then
		into = 0
	end

	if type(what) == "string" then
		what = tonumber(what:gsub("#", ""), 16) or 0
	elseif type(what) ~= "number" then
		what = 0
	end

	-- Clamp to valid color range
	into = math.max(0, math.min(0xFFFFFF, into))
	what = math.max(0, math.min(0xFFFFFF, what))

	-- Extract RGB components
	local bg_r = math.floor(into / 65536) % 256
	local bg_g = math.floor(into / 256) % 256
	local bg_b = into % 256

	local fg_r = math.floor(what / 65536) % 256
	local fg_g = math.floor(what / 256) % 256
	local fg_b = what % 256

	-- Blend components
	local r = math.floor(bg_r + (fg_r - bg_r) * amount)
	local g = math.floor(bg_g + (fg_g - bg_g) * amount)
	local b = math.floor(bg_b + (fg_b - bg_b) * amount)

	-- Combine back to hex
	return r * 65536 + g * 256 + b
end

utils.gethl = function(name)
	local hl = vim.api.nvim_get_hl(0, { name = name })
	if hl.link then
		return utils.gethl(hl.link)
	end
	return hl
end

utils.adjust_brightness = function(color, amount)
	-- Convert string hex to number if needed
	if type(color) == "string" then
		color = tonumber(color:gsub("#", ""), 16) or 0
	elseif type(color) ~= "number" then
		color = 0
	end

	-- Clamp inputs to valid ranges
	color = math.max(0, math.min(0xFFFFFF, color))
	amount = math.max(0, math.min(10, amount or 1))

	-- Extract RGB components
	local r = math.floor(color / 65536) % 256
	local g = math.floor(color / 256) % 256
	local b = color % 256

	-- Apply brightness adjustment
	r = math.min(255, math.floor(r * amount))
	g = math.min(255, math.floor(g * amount))
	b = math.min(255, math.floor(b * amount))

	-- Combine back to hex
	return r * 65536 + g * 256 + b
end

local function augroup(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end


autocmd({ "ColorScheme", "VimEnter" }, {
	desc = "Borderless snacks picker look (Atom One Dark)",
	group = augroup("borderless-snacks"),
	callback = function()
		local colors         = {
			background = palette.bg,
			foreground = palette.fg,
			pmenu      = utils.adjust_brightness(palette.surface2, 0.95),
			fun        = palette.fun,
			special    = palette.special,
			identifier = palette.primary,
		}

		local lighter_pmenu  = utils.blend(colors.pmenu, colors.background, 0.9)
		local lighter_pmenu2 = utils.blend(colors.pmenu, colors.background, 0.25)

		sethl("SnacksPickerInput", {
			bg = lighter_pmenu,
			fg = colors.foreground,
		})
		sethl("SnacksPickerInputBorder", {
			bg = lighter_pmenu,
			fg = lighter_pmenu,
		})
		sethl("SnacksPickerInputTitle", {
			fg = palette.black,
			bg = colors.fun,
			bold = true,
		})

		sethl("SnacksPickerList", {
			bg = lighter_pmenu2,
		})
		sethl("SnacksPickerListBorder", {
			bg = lighter_pmenu2,
			fg = lighter_pmenu2,
		})
		sethl("SnacksPickerListTitle", {
			fg = colors.special,
			bg = lighter_pmenu2,
		})

		sethl("SnacksPickerPrompt", {
			bg = lighter_pmenu,
			fg = colors.special,
		})

		sethl("SnacksPickerPreviewTitle", {
			fg = palette.black,
			bg = colors.identifier,
			bold = true,
		})

		sethl("SnacksPicker", {
			bg = colors.pmenu,
			fg = colors.foreground,
		})
		sethl("SnacksPickerBorder", {
			bg = colors.pmenu,
			fg = colors.pmenu,
		})

		sethl("SnacksInputNormal", {
			bg = colors.pmenu,
			fg = colors.foreground,
		})
		sethl("SnacksInputBorder", {
			bg = colors.pmenu,
			fg = colors.pmenu,
		})

		sethl("SnacksPickerListCursorLine", {
			link = "SnacksPickerPreviewCursorLine",
		})
		sethl("SnacksPickerCursorLine", {
			link = "SnacksPickerPreviewCursorLine",
		})
	end,
})
