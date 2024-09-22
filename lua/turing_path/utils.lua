-- lua/turing_path/utils.lua

local M = {}

-- Function to highlight the letter "G" in the buffer with a red background
function M.highlight_letter_G(buf)
	vim.cmd("highlight GHighlight guibg=Red ctermbg=Red")

	local function highlight_all_G()
		vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		for row, line in ipairs(lines) do
			for col = 1, #line do
				if line:sub(col, col) == "G" then
					vim.api.nvim_buf_add_highlight(buf, -1, "GHighlight", row - 1, col - 1, col)
				end
			end
		end
	end

	highlight_all_G()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = highlight_all_G,
	})
end

-- Function to clear all highlights
function M.clear_highlights(buf)
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
end

-- Function to show a popup message
function M.show_popup(message)
	local width = 50
	local height = 5
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local win_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(win_buf, 0, -1, false, { "", message, "", "" })
	vim.api.nvim_buf_add_highlight(win_buf, -1, "Title", 1, 0, -1)

	local win_id = vim.api.nvim_open_win(win_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win_id) then
			vim.api.nvim_win_close(win_id, true)
		end
	end, 3000)
end

return M
