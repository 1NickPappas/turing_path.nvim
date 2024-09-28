-- lua/turing_path/games/special_mode.lua

local M = {}

-- Variables to hold the game buffer and window
local game_buf
local game_win

-- Constants for the square boundaries (will be set dynamically)
local square_top
local square_bottom
local square_left
local square_right

-- Maximum number of "G"s to be deleted before the game ends
local max_Gs_to_delete = 15

-- Variable to track the number of deleted "G"s
local deleted_G_count = 0

-- Function to randomly insert a "G" inside the inner square (excluding the edges)
local function add_random_G()
	-- Get random positions within the inner part of the square (excluding edges)
	local row = math.random(square_top + 1, square_bottom - 1)
	local col = math.random(square_left + 1, square_right - 1)

	-- Get the line at the random row
	local line = vim.api.nvim_buf_get_lines(game_buf, row - 1, row, false)[1]

	-- Ensure that the line exists and a space is at the random position before placing "G"
	if line and line:sub(col, col) == " " then
		local new_line = line:sub(1, col - 1) .. "G" .. line:sub(col + 1)
		vim.api.nvim_buf_set_lines(game_buf, row - 1, row, false, { new_line })
	else
		-- If the position is not empty or line is nil, try again
		add_random_G()
	end
end

-- Function to show the congratulations popup and handle game restart
local function show_congrats_popup()
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
			M.restart_game()
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
function M.handle_x()
	-- Get current cursor position
	local row, col = unpack(vim.api.nvim_win_get_cursor(game_win))
	-- Neovim uses 1-based indexing for rows and 0-based indexing for columns

	-- Adjust col for 1-based indexing in Lua strings
	local char_index = col + 1

	-- Get the current line
	local line = vim.api.nvim_buf_get_lines(game_buf, row - 1, row, false)[1]

	if not line then
		return
	end

	-- Get the character under the cursor
	local char_under_cursor = line:sub(char_index, char_index)

	if char_under_cursor == "G" then
		-- Replace the character at the cursor with a space
		local new_line = line:sub(1, char_index - 1) .. " " .. line:sub(char_index + 1)
		vim.api.nvim_buf_set_lines(game_buf, row - 1, row, false, { new_line })

		-- Increment deleted_G_count
		deleted_G_count = deleted_G_count + 1

		-- Check if the game has ended
		if deleted_G_count >= max_Gs_to_delete then
			-- Unmap the 'x' key
			vim.api.nvim_buf_del_keymap(game_buf, "n", "x")
			-- Show the congratulations popup
			show_congrats_popup()
		else
			-- Respawn a "G" at a random position
			add_random_G()
		end
	else
		-- If not "G", do nothing or handle accordingly
		vim.notify("You can only delete 'G's!", vim.log.levels.WARN)
	end
end

-- Function to start the special game mode for Game 0
function M.start_game_mode_0()
	-- Reset deleted_G_count
	deleted_G_count = 0

	-- Create a new buffer for the game
	game_buf = vim.api.nvim_create_buf(false, true)

	-- Disable LSP for this buffer
	vim.api.nvim_buf_set_option(game_buf, "filetype", "no_lsp")

	-- Create the game window as a popup occupying 80% of the editor
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}
	game_win = vim.api.nvim_open_win(game_buf, true, opts)

	-- Disable LSP for the game buffer
	vim.lsp.buf_detach_clients(game_buf)

	-- Set up the square boundaries based on the window size
	-- Adjust for the explanation text at the top
	local explanation_lines = 4 -- Number of lines used by the explanation
	square_top = explanation_lines + 1
	square_bottom = height - 2
	square_left = 4
	square_right = width - 4

	-- Draw the explanation and the square
	M.draw_square_with_explanation()

	-- Insert an initial "G" inside the square
	add_random_G()

	-- Map 'x' key in normal mode to our custom function using vim.keymap.set
	vim.keymap.set("n", "x", function()
		require("turing_path.games.special_mode").handle_x()
	end, { buffer = game_buf, silent = true, noremap = true })

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

-- Function to restart the game
function M.restart_game()
	-- Close the existing game window if it exists
	if vim.api.nvim_win_is_valid(game_win) then
		vim.api.nvim_win_close(game_win, true)
	end

	-- Start the game again
	M.start_game_mode_0()
end

-- Function to draw the explanation and the square
function M.draw_square_with_explanation()
	local lines = {}

	-- Add the explanation at the top
	lines[#lines + 1] = "Welcome to the G Deletion Game!"
	lines[#lines + 1] = "Objective: Delete 15 'G's by pressing 'x'."
	lines[#lines + 1] = ""
	lines[#lines + 1] = ""

	-- Calculate the total number of lines in the window
	local total_rows = vim.api.nvim_win_get_height(game_win)

	-- Calculate the vertical space available after the explanation
	local available_rows = total_rows - #lines

	-- Calculate the square dimensions
	local square_height = math.min(10, available_rows - 2) -- Leave at least 1 line padding
	local square_width = vim.api.nvim_win_get_width(game_win) - 8 -- Adjust for left/right padding

	-- Calculate vertical padding to center the square
	local vertical_padding = math.floor((available_rows - square_height) / 2)
	for _ = 1, vertical_padding do
		lines[#lines + 1] = ""
	end

	-- Calculate horizontal padding to center the square
	local horizontal_padding = math.floor((vim.api.nvim_win_get_width(game_win) - square_width) / 2)
	local left_padding = string.rep(" ", horizontal_padding)

	-- Draw the square
	for i = 1, square_height do
		local line = ""
		if i == 1 or i == square_height then
			-- Top or bottom edge of the square
			line = left_padding .. "+" .. string.rep("-", square_width - 2) .. "+"
		else
			-- Middle rows of the square
			line = left_padding .. "|" .. string.rep(" ", square_width - 2) .. "|"
		end
		lines[#lines + 1] = line
	end

	-- Fill the rest of the buffer with empty lines if needed
	while #lines < total_rows do
		lines[#lines + 1] = ""
	end

	-- Set the buffer lines
	vim.api.nvim_buf_set_lines(game_buf, 0, -1, false, lines)

	-- Update square boundaries based on the actual drawn square
	square_top = #lines - available_rows + vertical_padding + 1
	square_bottom = square_top + square_height - 1
	square_left = horizontal_padding + 1
	square_right = square_left + square_width - 1
end

return M
