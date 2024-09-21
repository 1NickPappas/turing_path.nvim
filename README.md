# Turing Path Plugin

This plugin provides a simple command `:TuringPath` to test the functionality.

## Installation (with lazy.nvim)

```lua
require('lazy').setup({
    {
        "1NickPappas/turing_path",  -- Replace with your GitHub repo URL
        lazy = true,  -- Lazy load the plugin
        cmd = "TuringPath",  -- Load plugin when :TuringPath is called
        config = function()
            -- Plugin setup will happen when the command is triggered
        end,
    },
})

