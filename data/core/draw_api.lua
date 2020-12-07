local docview = require('core.docview')

local draw_line_text = docview.draw_line_text

local draw = {}
local maps = {}

local function call_fun(fun, def, ran, ...)

    if ran[def.wait] or def.wait == '' then

        def.func(...)
        ran[fun] = true
    else

        call_fun(fun, maps[def.wait], ran, ...)

        def.func(...)
        ran[fun] = true
    end
end

function docview:draw_line_text(idx, x, y)

    draw_line_text(self, idx, x, y)
    local fran = {}

    for name, def in pairs(maps) do

        call_fun(name, def, fran, self, idx, x, y)
    end
end

function draw.addfn(name, def)

    assert(type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.afterdo or ''

    maps[name] = {func = fn, wait = wf}
end

return draw