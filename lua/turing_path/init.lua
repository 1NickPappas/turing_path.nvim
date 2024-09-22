-- lua/turing_path/init.lua

local M = {}

-- Main function to run the TuringPath game
function M.run()
	vim.ui.input({ prompt = "Enter game number (0-3): " }, function(input)
		local game_number = tonumber(input)
		if game_number then
			require("turing_path.games.game_loader").open_game(game_number)
		else
			vim.notify("Invalid game number.", vim.log.levels.ERROR)
		end
	end)
end

return M
