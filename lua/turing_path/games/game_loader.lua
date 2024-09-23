-- lua/turing_path/games/game_loader.lua

local M = {}

-- Get the path to the plugin root dynamically
local plugin_name = "turing_path.nvim" -- Replace with your actual plugin name if different
local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name

-- Define a table that maps each game to its corresponding file path and cursor position
local game_config = {
	[0] = { file = plugin_path .. "/games/game0.ts", cursor = { 5, 10 } },
	[1] = { file = plugin_path .. "/games/game1.ts", cursor = { 6, 45 } },
	[2] = { file = plugin_path .. "/games/game2.ts", cursor = { 7, 0 } },
	[3] = { file = plugin_path .. "/games/game3.ts", cursor = { 7, 0 } },
}

-- Import the game logic from utils
local utils = require("turing_path.utils")

-- Function to start the game and manage the game flow
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
		utils.highlight_letter_G(buf)

		-- Disable mouse events and arrow keys
		local function disable_controls()
			local mouse_events = {
				"<LeftMouse>",
				"<RightMouse>",
				"<MiddleMouse>",
				"<2-LeftMouse>",
				"<2-RightMouse>",
				"<2-MiddleMouse>",
				"<3-LeftMouse>",
				"<3-RightMouse>",
				"<3-MiddleMouse>",
				"<ScrollWheelUp>",
				"<ScrollWheelDown>",
			}
			for _, event in ipairs(mouse_events) do
				vim.api.nvim_buf_set_keymap(buf, "", event, "<Nop>", { noremap = true, silent = true })
			end

			local opts = { noremap = true, silent = true }
			for _, mode in ipairs({ "n", "v" }) do
				for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
					vim.api.nvim_buf_set_keymap(buf, mode, key, "<Nop>", opts)
				end
			end
		end

		disable_controls()

		-- Check if we are in the special game mode (game 0)
		if game_number == 0 then
			-- Import the function that handles the special mode for Game 0
			require("turing_path.games.special_mode").start_game_mode_0(buf)
		else
			-- For other games, start the normal game logic
			M.start_game(buf, game.cursor)
		end
	else
		vim.notify("Game file not found: " .. tutor_file, vim.log.levels.ERROR)
	end
end

-- Function to start the timer, check diagnostics, and restart the game
function M.start_game(buf, cursor_position)
	-- Create an autocmd group for diagnostics (if it doesn't exist)
	local diag_group = vim.api.nvim_create_augroup("TuringPathDiagnostics", { clear = true })

	-- Start the timer
	local start_time = vim.loop.hrtime()

	-- Set the cursor position inside start_game
	vim.defer_fn(function()
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_cursor(win, cursor_position)
	end, 100)

	-- Function to check diagnostics and handle game completion
	local function check_diagnostics()
		local diagnostics = vim.diagnostic.get(buf)
		if #diagnostics == 0 then
			local end_time = vim.loop.hrtime()
			local elapsed_ns = end_time - start_time
			local elapsed_sec = elapsed_ns / 1e9

			local minutes = math.floor(elapsed_sec / 60)
			local seconds = elapsed_sec % 60
			local time_msg =
				string.format("🎉 You fixed all errors in %d minutes and %.2f seconds!", minutes, seconds)

			local utils = require("turing_path.utils")
			utils.show_popup(time_msg)

			vim.api.nvim_clear_autocmds({ group = diag_group, buffer = buf })

			vim.defer_fn(function()
				utils.clear_highlights(buf)
				vim.cmd("edit!") -- Reload the buffer from disk
				vim.api.nvim_win_set_cursor(0, cursor_position)

				vim.defer_fn(function()
					utils.highlight_letter_G(buf)
					M.start_game(buf, cursor_position)
				end, 1000)
			end, 3000)
		end
	end

	vim.api.nvim_clear_autocmds({ group = diag_group, buffer = buf })

	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = diag_group,
		buffer = buf,
		callback = function()
			vim.defer_fn(check_diagnostics, 100)
		end,
	})
end

return M
