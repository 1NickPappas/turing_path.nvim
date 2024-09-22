-- lua/turing_path/games/game_loader.lua

local utils = require("turing_path.utils")

local M = {}

-- Get the path to the plugin root dynamically
local plugin_name = "turing_path.nvim" -- Replace with your actual plugin name if different
local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name

-- Define a table that maps each game to its corresponding file path and cursor position
local game_config = {
	[0] = { file = plugin_path .. "/games/example_game.ts", cursor = { 5, 10 } },
	[1] = { file = plugin_path .. "/games/game1.ts", cursor = { 8, 45 } },
	[2] = { file = plugin_path .. "/games/game2.ts", cursor = { 10, 5 } },
	[3] = { file = plugin_path .. "/games/game3.ts", cursor = { 3, 0 } },
}

-- Main function to start the Turing Path game
function M.run()
	-- First, display the ASCII art window
	utils.display_start_window(function()
		-- After closing the start window, select mode and game
		utils.select_mode_and_game(function(mode, game_number)
			-- Here you can handle the mode (e.g., apply difficulty logic)
			vim.notify("Starting game in " .. mode .. " mode.")

			-- Proceed to open the selected game
			M.open_game(game_number)
		end)
	end)
end

-- Function to open the selected game and manage the game flow
function M.open_game(game_number)
	local game = game_config[game_number]
	if not game then
		vim.notify("Game " .. game_number .. " not found.", vim.log.levels.ERROR)
		return
	end

	-- Define the path to your game file
	local tutor_file = game.file

	if vim.fn.filereadable(tutor_file) == 1 then
		-- Open the game file in a new tab
		vim.cmd("tabedit " .. vim.fn.fnameescape(tutor_file))

		-- Get the buffer number of the newly opened file
		local buf = vim.api.nvim_get_current_buf()

		-- Set the filetype to 'typescript' for syntax highlighting and LSP
		vim.api.nvim_buf_set_option(buf, "filetype", "typescript")

		-- Highlight all "G" in the buffer with a red background
		require("turing_path.utils").highlight_letter_G(buf)

		-- Proceed with other game logic (e.g., starting the game, disabling keys)
		M.start_game(buf, game.cursor)
	else
		vim.notify("Game file not found: " .. tutor_file, vim.log.levels.ERROR)
	end
end

return M
