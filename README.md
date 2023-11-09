# discord.nvim

## Installation

Lazy: 

```lua
{
    'lpturmel/discord.nvim',
    config = function()
        local discord = require('discord')

        discord.setup()
    end
}
```

This plugin requires the [rpc server](https://github.com/lpturmel/nvim-discord)
