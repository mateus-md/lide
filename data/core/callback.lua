local core     = require('core')
local _doc     = require('core.doc')
local rootview = require('core.rootview')
local docview  = require('core.docview')

local callback = {}
callback.step  = {}
callback.draw  = {}

local _doc_save            = {}
local dcvw_step            = {}
local text_inpt, root_step = {}, {}
local draw_dcvw, draw_line = {}, {}
local draw_root            = {}

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

-- Other callbacks --
local doc_save = _doc.save
function _doc:save(...)

    local fran = {}
    local _tbl = {}

    for name, def in pairs(_doc_save) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    doc_save(self, ...)

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

-- Updates --
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

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local rootvw_update  = rootview.update
function rootview.update(...)

    local fran = {}
    local _tbl = {}

    for name, def in pairs(root_step) do

        if def.doabove then

            call_fun(name, def, fran, ...)

        else _tbl[name] = def end
    end

    rootvw_update(...)

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, ...)
    end
end

local on_text_input  = rootview.on_text_input
function rootview.on_text_input(...)

    local fran = {}
    local _tbl = {}

    for name, def in pairs(text_inpt) do

        if def.doabove then

            call_fun(name, def, fran, ...)

        else _tbl[name] = def end
    end

    on_text_input(...)

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, ...)
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

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, self, ...)
    end
end

local draw_line_body = docview.draw_line_body
local draw_line_text = docview.draw_line_text

function docview:draw_line_text() end
function docview:draw_line_body(...)

    local fran = {}
    local _tbl = {}

    for name, def in pairs(draw_line) do

        if def.doabove then

            call_fun(name, def, fran, self, ...)

        else _tbl[name] = def end
    end

    draw_line_body(self, ...)
    draw_line_text(self, ...)

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

    for name, def in pairs(_tbl) do

        call_fun(name, def, fran, ...)
    end
end

-- Callbacks --
function callback.step.docv(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    dcvw_step[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.step.root(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    root_step[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.step.text_input(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    text_inpt[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.draw.docv(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_dcvw[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.draw.line(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_line[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.draw.root(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    draw_root[name] = {func = fn, wait = wf, doabove = def.doabove}
end

function callback.save(name, def)

    assert(def.perform and type(def.perform) == 'function')

    local fn = def.perform
    local wf = def.waitfor or ''

    _doc_save[name] = {func = fn, wait = wf, doabove = def.doabove}
end

return callback
