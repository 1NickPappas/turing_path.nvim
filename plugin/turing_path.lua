-- Define a command that triggers the Turing Path functionality
vim.api.nvim_create_user_command("TuringPath", function()
	require("turing_path").run()
end, {})
