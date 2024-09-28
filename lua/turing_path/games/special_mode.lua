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

-- Function to show the congratulations popup and handle game restart
local function show_congrats_popup(buf)
	-- Create a new buffer for the popup
	local popup_buf = vim.api.nvim_create_buf(false, true)

	-- Set the popup message
	local message = {
		"Congratulations!",
		"You have deleted all Gs!",
		"",
		"Press 'r' to play again.",
	}
	vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, message)

	-- Define popup window options
	local width = 40
	local height = 6
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		style = "minimal",
		border = "rounded",
	}

	-- Create the popup window
	local popup_win = vim.api.nvim_open_win(popup_buf, true, opts)

	-- Map 'r' to restart the game
	vim.api.nvim_buf_set_keymap(popup_buf, "n", "r", "", {
		noremap = true,
		silent = true,
		callback = function()
			-- Close the popup window
			vim.api.nvim_win_close(popup_win, true)
			-- Restart the game
			M.restart_game(buf)
		end,
	})

	-- Disable other keys in the popup
	vim.api.nvim_buf_set_keymap(popup_buf, "n", "<ESC>", "", {
		noremap = true,
		silent = true,
		callback = function()
			-- Do nothing
		end,
	})

	-- Set the buffer to not be modifiable
	vim.api.nvim_buf_set_option(popup_buf, "modifiable", false)
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
			-- Show the congratulations popup
			show_congrats_popup(buf)
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
	-- Reset deleted_G_count
	deleted_G_count = 0

	-- Clear any previous autocmd group to avoid stacking
	vim.api.nvim_create_augroup("GDeletionGame", { clear = true })

	-- Clear the buffer and redraw the square (assuming you have a function to draw the square)
	if M.draw_square then
		M.draw_square(buf)
	end

	-- Insert an initial "G" inside the square
	add_random_G(buf)

	-- Map 'x' key in normal mode to our custom function using vim.keymap.set
	vim.keymap.set("n", "x", function()
		require("turing_path.games.special_mode").handle_x(buf)
	end, { buffer = buf, silent = true, noremap = true })

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

-- Function to restart the game
function M.restart_game(buf)
	-- Reset the game state
	M.start_game_mode_0(buf)
end

-- Optional: Function to draw the square (if needed)
function M.draw_square(buf)
	-- Define the square lines
	local lines = {}

	for row = 1, square_bottom do
		if row == square_top or row == square_bottom then
			lines[row] = string.rep("-", square_right)
		elseif row > square_top and row < square_bottom then
			lines[row] = "|" .. string.rep(" ", square_right - 2) .. "|"
		else
			lines[row] = ""
		end
	end

	-- Set the buffer lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

return M
