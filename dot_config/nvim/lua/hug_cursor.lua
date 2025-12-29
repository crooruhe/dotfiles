-- lua/hug_cursor.lua
local M = {}

local current_image = nil
local gif_path = nil
local debounce_timer = nil
local debounce_ms = 50

local function get_cursor_pos()
	local win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(win)
	return cursor[1] - 1, cursor[2]
end

local function clear_image()
	if current_image then
		pcall(function()
			current_image:clear()
		end)
		current_image = nil
	end
end

local function render_gif()
	if not gif_path then
		return
	end

	clear_image()
	-- if current_image then
	-- 	current_image:clear()
	-- 	current_image = nil
	-- end

	local row, col = get_cursor_pos()
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	local ok, api = pcall(require, "image")
	if not ok then
		return
	end

	current_image = api.from_file(gif_path, {
		window = win,
		buffer = buf,
		x = col,
		y = row,
		width = 3,
		height = 2,
	})

	if current_image then
		current_image:render()
	end
end

local function show_gif()
	print("show_gif called")
	if debounce_timer then
		debounce_timer:stop()
	end

	debounce_timer = vim.defer_fn(render_gif, debounce_ms)
end

local function hide_gif()
	if debounce_timer then
		debounce_timer:stop()
		debounce_timer = nil
	end

	if current_image then
		current_image:clear()
		current_image = nil
	end
end

function M.setup(opts)
	opts = opts or {}
	gif_path = opts.gif_path
	debounce_ms = opts.debounce_ms or 50

	local group = vim.api.nvim_create_augroup("HugCursor", { clear = true })

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = show_gif,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = hide_gif,
	})

	vim.api.nvim_create_autocmd({ "CursorMovedI", "TextChangedI" }, {
		group = group,
		callback = show_gif,
	})
end

return M
