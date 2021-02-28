local core       = require('core')
local _doc       = require('core.doc')
local rootview   = require('core.rootview')
local docview    = require('core.docview')

local callback = {}
callback.root  = {}
callback.docv  = {}
callback.sttv  = {}

local _doc_new , doc_clean = {}, {}
local _doc_save, doc_input = {}, {}
local dcvw_step, root_step = {}, {}
local draw_body, draw_line = {}, {}
local mouse_whl, mousemove = {}, {}
local draw_dcvw, draw_root = {}, {}

local standby, sndby_n
local function call_fun(fun, def, ran, ...)

    if ran[def.wait] or def.wait == '' then

        local out = def.func(...)
        ran[fun] = true

        return out
    else
        sndby_n = def.wait
        standby = {func = def.func, name = fun}
    end

    if ran[sndby_n] or sndby_n == fun then

        local out = standby.func(...)
        ran[standby.name] = true

        standby = nil
        sndby_n = nil
        collectgarbage('collect')

        return out
    end
end

-- Other callbacks --
local old_doc_save = _doc.save
function _doc:save(...)

    local fran = {}
    local _tbl = {}

    for name, def in pairs(_doc_save) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    old_doc_save(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local old_doc_new = _doc.new
function _doc:new(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(_doc_new) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    old_doc_new(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local old_doc_clean = _doc.clean
function _doc:clean(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(doc_clean) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    old_doc_clean(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

-- updates --
local docviewupdate = docview.update
function docview:update(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(dcvw_step) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    docviewupdate(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

callback.__doc_input = docview.on_text_input
function docview:on_text_input(...)

    local rout
    local ccnt = 0

    local fran = {}
    local _tbl = {}
    for name, def in pairs(doc_input) do

        if def.doabove then

            rout = call_fun(name, def, fran, self, ...)
            ccnt = ccnt + 1

        else _tbl[name] = def end
    end

    -- Avoid multiple calls --
    if rout or ccnt == 0 then

        callback.__doc_input(self, rout)
        fran['self'] = true
    end

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local rootvw_update  = rootview.update
function rootview:update(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(root_step) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    rootvw_update(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

-- Graphics --
local draw_docview   = docview.draw
function docview:draw(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(draw_dcvw) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    draw_docview(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local draw_line_body = docview.draw_line_body
function docview:draw_line_body(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(draw_body) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    draw_line_body(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local draw_line_text = docview.draw_line_text
function docview:draw_line_text(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(draw_line) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    draw_line_text(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local on_mouse_wheel = docview.on_mouse_wheel
function docview:on_mouse_wheel(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(mouse_whl) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    on_mouse_wheel(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local on_mouse_moved = docview.on_mouse_moved
function docview:on_mouse_moved(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(mousemove) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    on_mouse_moved(self, ...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local draw_root_view = core.root_view.draw
function rootview.draw(...)

    local fran = {}
    local _tbl = {}
    for name, def in pairs(draw_root) do

        if def.doabove then

            call_fun(name, def, fran, ...)

        else _tbl[name] = def end
    end

    draw_root_view(...)
    fran['self'] = true

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, ...)
    end
end

-- callbacks --
function callback.docv.step(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    dcvw_step[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.input(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    doc_input[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.root.step(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    root_step[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.docv.draw(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_dcvw[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.docv.body(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_body[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.docv.line(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_line[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.docv.mouse_wheel(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    mouse_whl[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.docv.mouse_move(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    mousemove[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.root.draw(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_root[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.save(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    _doc_save[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.new_file(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    _doc_new[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.clean(name, def)
    -- validade parameters --
    assert(def.perform and type(def.perform) == 'function', 'invalid perform attribute')

    local fn = def.perform
    local wf = def.waitfor or ''

    doc_clean[name] = {func = fn, wait = wf, doabove = def.doabove}
end

return callback
