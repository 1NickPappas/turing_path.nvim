-- lua/turing_path/utils.lua

local M = {}

-- Function to highlight the letter "G" in the buffer with a red background
function M.highlight_letter_G(buf)
	vim.cmd("highlight GHighlight guibg=Red ctermbg=Red")

	local function highlight_all_G()
		vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		for row, line in ipairs(lines) do
			for col = 1, #line do
				if line:sub(col, col) == "G" then
					vim.api.nvim_buf_add_highlight(buf, -1, "GHighlight", row - 1, col - 1, col)
				end
			end
		end
	end

	highlight_all_G()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = highlight_all_G,
	})
end

-- Function to clear all highlights
function M.clear_highlights(buf)
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
end

-- Function to show a popup message
function M.show_popup(message)
	local width = 50
	local height = 5
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local win_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(win_buf, 0, -1, false, { "", message, "", "" })
	vim.api.nvim_buf_add_highlight(win_buf, -1, "Title", 1, 0, -1)

	local win_id = vim.api.nvim_open_win(win_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win_id) then
			vim.api.nvim_win_close(win_id, true)
		end
	end, 3000)
end

-- Function to display the start window with Turing machine ASCII art and mode selection
M.display_start_window = function(start_callback)
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
		" Select Mode and Game: ",
		"  1. Easy",
		"  2. Medium",
		"  3. Hard",
		"",
		"  Game 0: Example",
		"  Game 1: Game 1",
		"  Game 2: Game 2",
		"  Game 3: Game 3",
		"",
		" Press 'q' to quit or 'Enter' to select mode and game.",
	}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, ascii_art)

	-- Highlight title or specific lines if desired
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 3, 0, -1) -- Highlight the 'Turing Machine'

	local width = 60
	local height = #ascii_art
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local win_id = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	-- Set up key mappings for quitting and starting the game
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = function()
			vim.api.nvim_win_close(win_id, true) -- Close the window
			start_callback() -- Proceed to the game setup
		end,
	})
end

-- Function to select mode and game
M.select_mode_and_game = function(callback)
	-- Modes to select from
	local modes = { "Easy", "Medium", "Hard" }
	local games = { "Game 0", "Game 1", "Game 2", "Game 3" }

	-- First, prompt for mode
	vim.ui.select(modes, { prompt = "Select a mode" }, function(selected_mode)
		if not selected_mode then
			vim.notify("Mode selection canceled.", vim.log.levels.WARN)
			return
		end

		-- Then, prompt for game
		vim.ui.select(games, { prompt = "Select a game" }, function(selected_game)
			if not selected_game then
				vim.notify("Game selection canceled.", vim.log.levels.WARN)
				return
			end

			-- Extract game number from the string (e.g., "Game 0" -> 0)
			local game_number = tonumber(selected_game:match("%d"))

			-- Call the callback with the selected mode and game number
			callback(selected_mode, game_number)
		end)
	end)
end

return M
