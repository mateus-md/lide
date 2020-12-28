local core    = require('core')
local keymap  = require('core.keymap')
local command = require ('core.command')

command.add(function() return true end, {

    ["root:next-tab"] = function()

        local node = core.root_view:get_active_node()
        local t = node:get_view_idx(core.active_view)

        if t == 1 then t = #node.views
        else t = t - 1 end

        command.perform('root:switch-to-tab-' .. t)
    end,

    ["root:prev-tab"] = function()

        local node = core.root_view:get_active_node()
        local t = node:get_view_idx(core.active_view)

        if t == #node.views then t = 1
        else t = t + 1 end

        command.perform('root:switch-to-tab-' .. t)
    end
})

for i = 1, 9 do

    command.add(function() return true end, {

        ["tab_close_" .. i] = function()

            local node = core.root_view:get_active_node()
            local ctab = node:get_view_idx(core.active_view)

            command.perform('root:switch-to-tab-' .. i)
            command.perform('root:close')

            command.perform('root:switch-to-tab-' .. ctab)
        end
    })

    keymap.add({

        ["ctrl+alt+" .. i] = "tab_close_" .. i
    })
end

keymap.add({

    ["alt+left"]   = "root:next-tab",
    ["alt+right"]  = "root:prev-tab",

    ["ctrl+shift+c"]     = "root:close",
    ["alt+shift+left"]   = "root:move-tab-left" ,
    ["alt+shift+right"]  = "root:move-tab-right",
})
