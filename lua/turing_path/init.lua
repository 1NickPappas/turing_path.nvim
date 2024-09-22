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

	-- Create buffer for the floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, ascii_art)

	-- Add highlights for the title and instructions
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 1, 0, -1) -- Highlight the title
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 9, 0, -1) -- Highlight the subtitle

	-- Window size and position (centered)
	local width = 60
	local height = #ascii_art + 2 -- Leave space for game selection prompt
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
		border = "rounded", -- Rounded border for modern look
	})

	-- Instructions for user
	vim.api.nvim_buf_set_lines(buf, height - 1, height, false, { "Select Game (0-3): " })
	vim.api.nvim_buf_add_highlight(buf, -1, "Comment", height - 1, 0, -1) -- Highlight instructions

	-- Keyboard Navigation: Allow ESC to close the window
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<Esc>",
		"<cmd>lua vim.api.nvim_win_close(" .. win_id .. ", true)<CR>",
		{ noremap = true, silent = true }
	)

	-- Input for game selection
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
