local core    = require('core')
local docview = require('core.docview')

local draw_line_text = docview.draw_line_text
local draw_line_body = docview.draw_line_body
local draw_root_view = core.root_view.draw

local draw = {}
local dwlt, db_lt = {}, {}
local dwlb, db_lb = {}, {}
local dwrv, db_rv = {}, {}

local function call_fun(fun, def, ran, ...)

    if ran[def.wait] or def.wait == '' then

        def.func(...)
        ran[fun] = true
    else

        call_fun(fun, dwlt[def.wait], ran, ...)

        def.func(...)
        ran[fun] = true
    end
end

function docview:draw_line_text(...)

    local fran = {}

    for name, def in pairs(db_lt) do

        call_fun(name, def, fran, self, ...)
    end

    draw_line_text(self, ...)

    for name, def in pairs(dwlt) do

        call_fun(name, def, fran, self, ...)
    end
end

function docview:draw_line_body(...)

    local fran = {}

    for name, def in pairs(db_lb) do

        call_fun(name, def, fran, self, ...)
    end

    draw_line_body(self, ...)

    for name, def in pairs(dwlb) do

        call_fun(name, def, fran, self, ...)
    end
end

core.root_view.draw = function(...)

    local fran = {}

    for name, def in pairs(db_rv) do

        call_fun(name, def, fran, ...)
    end

    draw_root_view(...)

    for name, def in pairs(dwrv) do

        call_fun(name, def, fran, ...)
    end
end

function draw.draw_line(name, def)

    assert(type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    if def.doabove then db_lt[name] = {func = fn, wait = wf}
    else dwlt[name] = {func = fn, wait = wf} end
end

function draw.line_body(name, def)

    assert(type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    if def.doabove then db_lb[name] = {func = fn, wait = wf}
    else dwlb[name] = {func = fn, wait = wf} end
end

function draw.root_view(name, def)

    assert(type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    if def.doabove then db_rv[name] = {func = fn, wait = wf}
    else dwrv[name] = {func = fn, wait = wf} end
end

return draw
