--------------------------------------------------------------------------------------------------
-- Tiny plugin to show memory usage for the `lite` text editor (https://github.com/rxi/lite)    --
-- Made with <3 by Tmpod                                                                        --
-- Original drawing logic by rxi (https://github.com/rxi/lite/issues/98#issuecomment-643753039) --
--------------------------------------------------------------------------------------------------

-- Imports --
local core = require "core"
local command = require "core.command"
local style = require "core.style"
local config = require "core.config"
local callback = require "core.callback"

-- Function taking no arguments that returns two ints for the text's x and y position.
function config.memusage_coords()
  return core.root_view.size.x - 90, 4
end

-- Logic --
callback.draw.root('draw_memusage', {

    perform = function()

        if config.memusage_active then
            local str = string.format('%.2f MB', collectgarbage('count') / 1024)
            local x, y = config.memusage_coords()
            renderer.draw_text(style.font, str, x + 30, y + 5, style.text)
        end
    end
})

-- And add a command for toggling too
local function toggle_memusage()
  config.memusage_active = not config.memusage_active
  local state = config.memusage_active and "ON" or "OFF"
  core.log("Toggled memusage display " .. state)
end

command.add(
  nil,
  {
    ["memusage:toggle"] = toggle_memusage
  }
)
