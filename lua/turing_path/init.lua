-- lua/turing_path/init.lua

local M = {}

-- Function to display the starter page with ASCII art and game selection prompt
function M.run()
	local ascii_art = {
		"  ____________________________ ",
		" |  _______                   |",
		" | |       |                  |",
		" | |       |     Turing        |",
		" | |_______|    Machine        |",
		" |     | |                     |",
		" |_____| |_____________________|",
		"       | |      | |      | |    ",
		"      [ ]      [ ]      [ ]     ",
		"",
		" Turing Path Game",
		" ========================",
		"",
		" Enter a game number (0-3):",
	}

	-- Create a buffer for the floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, ascii_art)

	-- Highlight the title of the game
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 9, 0, -1)

	-- Calculate the window size and position (center it)
	local width = 60
	local height = #ascii_art
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Open the floating window in the center
	local win_id = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	-- Create an input prompt at the bottom for game selection
	vim.ui.input({ prompt = "Select Game (0-3): " }, function(input)
		local game_number = tonumber(input)
		if game_number and game_number >= 0 and game_number <= 3 then
			vim.api.nvim_win_close(win_id, true) -- Close the starter window
			require("turing_path.games.game_loader").open_game(game_number)
		else
			vim.notify("Invalid game number. Please enter a number between 0 and 3.", vim.log.levels.ERROR)
			M.run() -- Restart the game selector if invalid input
		end
	end)
end

return M
