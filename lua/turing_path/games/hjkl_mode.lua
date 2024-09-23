-- Define a new game mode for game 0 in the game loader

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

-- Function to randomly insert a "G" inside the square
local function add_random_G(buf)
	-- Get random positions within the square
	local row = math.random(square_top + 1, square_bottom - 1)
	local col = math.random(square_left + 1, square_right - 1)

	-- Insert "G" at the random position by replacing the space
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	local new_line = line:sub(1, col - 1) .. "G" .. line:sub(col + 1)
	vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
end

-- Function to check if a G was deleted and handle the game logic
local function check_deletion(buf, cursor_position)
	-- Get current line and column
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	-- If the deleted character was a "G", track it
	if line:sub(col, col) == "G" then
		deleted_G_count = deleted_G_count + 1

		-- Notify the user how many "G"s they have deleted
		vim.notify("Deleted " .. deleted_G_count .. " Gs out of " .. max_Gs_to_delete)

		-- Replace the "G" with a space
		local new_line = line:sub(1, col - 1) .. " " .. line:sub(col + 1)
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })

		-- Check if the game is completed
		if deleted_G_count >= max_Gs_to_delete then
			vim.notify("🎉 You have successfully deleted 15 Gs! Game Over!", vim.log.levels.INFO)
			-- Reset game state
			deleted_G_count = 0
			vim.api.nvim_clear_autocmds({ group = "GDeletionGame" })
			return
		end

		-- Add a new "G" after deletion
		add_random_G(buf)
	end
end

-- Function to start the special game mode for Game 0
function M.start_game_mode_0(buf)
	-- Clear any previous autocmd group to avoid stacking
	local game_group = vim.api.nvim_create_augroup("GDeletionGame", { clear = true })

	-- Insert an initial "G" inside the square
	add_random_G(buf)

	-- Create an autocmd to listen for the "x" key being pressed
	vim.api.nvim_create_autocmd("TextChanged", {
		group = game_group,
		buffer = buf,
		callback = function()
			-- Get the current cursor position
			local cursor_position = vim.api.nvim_win_get_cursor(0)
			-- Check if a "G" was deleted and update the game state
			check_deletion(buf, cursor_position)
		end,
	})

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

return M
