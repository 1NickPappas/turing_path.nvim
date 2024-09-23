-- lua/turing_path/games/special_mode.lua

local M = {}

-- Constants for the square boundaries
local square_top = 4
local square_bottom = 12
local square_left = 3
local square_right = 36

-- Maximum number of "G"s to be deleted before the game ends
local max_Gs_to_delete = 15

-- Function to track G deletions
local deleted_G_count = 0

-- Function to randomly insert a "G" inside the inner square (excluding the edges)
local function add_random_G(buf)
	-- Get random positions within the inner part of the square (excluding edges)
	local row = math.random(square_top + 1, square_bottom - 1)
	local col = math.random(square_left + 1, square_right - 1)

	-- Insert "G" at the random position by replacing the space
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	-- Ensure that a space exists at the random position before placing "G"
	if line:sub(col, col) == " " then
		local new_line = line:sub(1, col - 1) .. "G" .. line:sub(col + 1)
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
	else
		-- If the position is not empty, try again
		add_random_G(buf)
	end
end

-- Function to handle 'x' keypress in normal mode
function M.handle_x()
	local buf = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	local char_index = col -- In Lua strings, indexing starts at 1

	local char = line:sub(char_index, char_index)

	if char == "G" then
		-- Replace 'G' with a space
		local new_line = line:sub(1, char_index - 1) .. " " .. line:sub(char_index + 1)
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })

		-- Increment counter
		deleted_G_count = deleted_G_count + 1
		vim.notify("Deleted " .. deleted_G_count .. " Gs out of " .. max_Gs_to_delete)

		-- Check if the game is completed
		if deleted_G_count >= max_Gs_to_delete then
			vim.notify(
				"🎉 You have successfully deleted " .. max_Gs_to_delete .. " Gs! Game Over!",
				vim.log.levels.INFO
			)
			deleted_G_count = 0
			vim.api.nvim_clear_autocmds({ group = "GDeletionGame" })
			-- Unmap the 'x' key to end the game
			vim.api.nvim_buf_del_keymap(buf, "n", "x")
			return
		end

		-- Add a new "G" after deletion
		add_random_G(buf)
	else
		-- Do nothing or prevent deletion to maintain square shape
		-- Optionally, you could notify the user that only 'G's can be deleted
		-- vim.notify("You can only delete 'G's!", vim.log.levels.WARN)
	end
end

-- Function to start the special game mode for Game 0
function M.start_game_mode_0(buf)
	-- Clear any previous autocmd group to avoid stacking
	local game_group = vim.api.nvim_create_augroup("GDeletionGame", { clear = true })

	-- Insert an initial "G" inside the square
	add_random_G(buf)

	-- Map 'x' key in normal mode to our custom function
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"x",
		'<Cmd>lua require("turing_path.games.special_mode").handle_x()<CR>',
		{ noremap = true, silent = true }
	)

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

return M
