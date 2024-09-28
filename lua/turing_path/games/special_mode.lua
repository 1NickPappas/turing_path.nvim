-- lua/turing_path/games/special_mode.lua

local M = {}

-- Constants for the square boundaries
local square_top = 4
local square_bottom = 12
local square_left = 3
local square_right = 36

-- Maximum number of "G"s to be deleted before the game ends
local max_Gs_to_delete = 15

-- Variable to track the number of deleted "G"s
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
function M.handle_x(buf)
	-- Get current cursor position
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	-- Neovim uses 1-based indexing for rows and 0-based indexing for columns

	-- Adjust col for 1-based indexing in Lua strings
	local char_index = col + 1

	-- Get the current line
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	-- Get the character under the cursor
	local char_under_cursor = line:sub(char_index, char_index)

	if char_under_cursor == "G" then
		-- Replace the character at the cursor with a space
		local new_line = line:sub(1, char_index - 1) .. " " .. line:sub(char_index + 1)
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })

		-- Increment deleted_G_count
		deleted_G_count = deleted_G_count + 1

		-- Check if the game has ended
		if deleted_G_count >= max_Gs_to_delete then
			-- Unmap the 'x' key
			vim.api.nvim_buf_del_keymap(buf, "n", "x")
			vim.notify("Congratulations! You have deleted all Gs!", vim.log.levels.INFO)
		else
			-- Respawn a "G" at a random position
			add_random_G(buf)
		end
	else
		-- If not "G", do nothing or handle accordingly
		vim.notify("You can only delete 'G's!", vim.log.levels.WARN)
	end
end

-- Function to start the special game mode for Game 0
function M.start_game_mode_0(buf)
	-- Clear any previous autocmd group to avoid stacking
	vim.api.nvim_create_augroup("GDeletionGame", { clear = true })

	-- Insert an initial "G" inside the square
	add_random_G(buf)

	-- Map 'x' key in normal mode to our custom function using vim.keymap.set
	vim.keymap.set("n", "x", function()
		require("turing_path.games.special_mode").handle_x(buf)
	end, { buffer = buf, silent = true, noremap = true })

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

return M
