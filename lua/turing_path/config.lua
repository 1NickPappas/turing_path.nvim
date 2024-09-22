-- lua/turing_path/config.lua

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

return M
