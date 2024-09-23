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

-- Function to check if a G was deleted and handle the game logic
local function check_deletion(buf)
	-- Get the current cursor position
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	-- The deleted character is the one at the previous cursor position
	if col > 1 then
		local previous_char = line:sub(col - 1, col - 1)
		if previous_char == "G" then
			deleted_G_count = deleted_G_count + 1
			vim.notify("Deleted " .. deleted_G_count .. " Gs out of " .. max_Gs_to_delete)

			-- Replace the previous "G" with a space
			local new_line = line:sub(1, col - 2) .. " " .. line:sub(col)
			vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })

			-- Check if the game is completed
			if deleted_G_count >= max_Gs_to_delete then
				vim.notify("🎉 You have successfully deleted 15 Gs! Game Over!", vim.log.levels.INFO)
				deleted_G_count = 0
				vim.api.nvim_clear_autocmds({ group = "GDeletionGame" })
				return
			end

			-- Add a new "G" after deletion
			add_random_G(buf)
		end
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
			-- Check if a "G" was deleted and update the game state
			check_deletion(buf)
		end,
	})

	-- Notify the user about the game objective
	vim.notify("Game started: Delete 15 Gs by pressing 'x'!", vim.log.levels.INFO)
end

return M
