-- lua/turing_path/init.lua

local M = {}

-- Function to display the starter page with ASCII art and game selection prompt
function M.run()
	-- ASCII Art
	local ascii_art = {
		"  _______                 _        _____      _   _     _    ",
		" |__   __|               (_)      |  __ \\    | | | |   (_)   ",
		"    | | ___ _ __ _ __ ___ _  ___  | |__) |__ | |_| |__  _ ___ ",
		"    | |/ _ \\ '__| '__/ _ \\ |/ __| |  _  // _` | __| '_ \\| / __|",
		"    | |  __/ |  | | |  __/ | (__  | | \\ \\ (_| | |_| | | | \\__ \\",
		"    |_|\\___|_|  |_| |_|\\___|_|\\___| |_|  \\_\\__,_|\\__|_| |_|___/",
		"                                                              ",
		"   Learn Fast. Code Faster!",
		"   Master nvim motions in style.",
	}

	-- Get screen size
	local screen_width = vim.o.columns
	local screen_height = vim.o.lines

	-- Set the window size to 60% of the screen and make it a bit wider
	local width = math.floor(screen_width * 0.7) -- Increase width to 70% of screen
	local height = math.floor(screen_height * 0.6)

	-- Ensure the window remains square-like by slightly adjusting the smaller dimension
	if width > height then
		height = width
	else
		width = height
	end

	-- Calculate the position (center the window)
	local col = math.floor((screen_width - width) / 2)
	local row = math.floor((screen_height - height) / 2)

	-- Create buffer for the floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, ascii_art)

	-- Add highlights for the title and instructions
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 1, 0, -1) -- Highlight the title
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 9, 0, -1) -- Highlight the subtitle

	-- Open the floating window
	local win_id = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded", -- Rounded border for a modern look
	})

	-- Display game selection prompt in the same window
	vim.api.nvim_buf_set_lines(buf, #ascii_art + 1, #ascii_art + 1, false, { "Select Game (0-3): " })
	vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #ascii_art + 1, 0, -1) -- Highlight the input prompt

	-- Get user input within the floating window (not separate)
	vim.cmd("augroup GameSelectionInput")
	vim.cmd("autocmd!")
	vim.cmd("autocmd WinClosed " .. win_id .. " stopinsert")

	vim.api.nvim_input("i") -- Automatically enter insert mode for input
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", false)

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

	vim.cmd("augroup END") -- Close input once user presses ESC or enters a value
end

return M
