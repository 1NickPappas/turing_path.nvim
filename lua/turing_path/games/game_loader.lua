-- lua/turing_path/games/game_loader.lua

local M = {}

-- Get the path to the plugin root dynamically
local plugin_name = "turing_path.nvim" -- Replace with your actual plugin name if different
local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name

-- Define a table that maps each game to its corresponding file path and cursor position
local game_config = {
	[0] = { file = plugin_path .. "/games/example_game.ts", cursor = { 5, 10 } },
	[1] = { file = plugin_path .. "/games/game1.ts", cursor = { 6, 45 } },
	[2] = { file = plugin_path .. "/games/game2.ts", cursor = { 7, 0 } },
	[3] = { file = plugin_path .. "/games/game3.ts", cursor = { 7, 0 } },
}

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
		require("turing_path.utils").highlight_letter_G(buf)

		-- Function to disable mouse events and arrow keys
		local function disable_controls()
			-- Disable mouse events
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

			-- Disable arrow keys in normal and visual modes
			local opts = { noremap = true, silent = true }
			local function disable_key(mode, key)
				vim.api.nvim_buf_set_keymap(buf, mode, key, "<Nop>", opts)
			end
			for _, mode in ipairs({ "n", "v" }) do
				for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
					disable_key(mode, key)
				end
			end
		end

		disable_controls()

		-- Start the game logic (diagnostics, timer, etc.)
		M.start_game(buf, game.cursor)
	else
		vim.notify("Game file not found: " .. tutor_file, vim.log.levels.ERROR)
	end
end

-- Function to start the timer, check diagnostics, and restart the game
-- Function to start the timer, check diagnostics, and restart the game
function M.start_game(buf, cursor_position)
	-- Start the timer
	local start_time = vim.loop.hrtime()

	-- Set the cursor position inside start_game
	vim.defer_fn(function()
		local win = vim.api.nvim_get_current_win()
		-- Set the cursor to the provided position (line and column)
		vim.api.nvim_win_set_cursor(win, cursor_position)
	end, 100) -- Add a small delay to ensure the file is fully loaded

	-- Function to check diagnostics and handle game completion
	local function check_diagnostics()
		local diagnostics = vim.diagnostic.get(buf)
		if #diagnostics == 0 then
			-- Stop the timer
			local end_time = vim.loop.hrtime()
			local elapsed_ns = end_time - start_time
			local elapsed_sec = elapsed_ns / 1e9 -- Convert nanoseconds to seconds

			local minutes = math.floor(elapsed_sec / 60)
			local seconds = elapsed_sec % 60
			local time_msg =
				string.format("🎉 You fixed all errors in %d minutes and %.2f seconds!", minutes, seconds)

			-- Create a floating popup window to display the message
			local utils = require("turing_path.utils")
			utils.show_popup(time_msg)

			-- Clear the diagnostics autocmd group to avoid multiple triggers
			vim.api.nvim_clear_autocmds({ group = "TuringPathDiagnostics", buffer = buf })

			-- Clear highlights and reset the game after 3 seconds
			vim.defer_fn(function()
				utils.clear_highlights(buf)

				-- Undo all changes
				vim.cmd("edit!") -- Reloads the buffer from disk, discarding unsaved changes

				-- Set cursor back to the starting position
				vim.api.nvim_win_set_cursor(0, cursor_position)

				-- Reapply highlights and restart the game after a delay
				vim.defer_fn(function()
					-- Reapply the "G" highlights after restarting the game
					utils.highlight_letter_G(buf)

					-- Restart the game
					M.start_game(buf, cursor_position)
				end, 1000) -- Wait 1 second before restarting
			end, 3000) -- 3-second delay before resetting the game
		end
	end

	-- Clear any previous diagnostics autocmds to avoid stacking triggers
	vim.api.nvim_clear_autocmds({ group = "TuringPathDiagnostics", buffer = buf })

	-- Create a new autocmd group for diagnostics check
	local diag_group = vim.api.nvim_create_augroup("TuringPathDiagnostics", { clear = true })

	-- Set up autocmd to check diagnostics whenever they change
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = diag_group,
		buffer = buf,
		callback = function()
			-- Check diagnostics after LSP updates
			vim.defer_fn(check_diagnostics, 100) -- Slight delay to allow diagnostics to update
		end,
	})
end

return M
