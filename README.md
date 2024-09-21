# Turing Path Plugin

This plugin provides a simple command `:TuringPath` to test the functionality.

## Installation (with lazy.nvim)

```lua
return {
  {
    "1NickPappas/turing_path.nvim",  -- Replace with your GitHub username and repo name
    lazy = true,  -- Lazy load the plugin
    cmd = "TuringPath",  -- Load the plugin only when the :TuringPath command is called
    config = function()
      -- No need to manually require a module here, the command will handle it
    end,
  },
}


