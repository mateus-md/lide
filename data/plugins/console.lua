-- Original code by rxi --
-- Edited by mateus.mds --

local core    = require('core')
local keymap  = require('core.keymap')
local command = require('core.command')
local common  = require('core.common')
local config  = require('core.config')
local style   = require('core.style')
local view    = require('core.view')

config.console_size       = 250 * SCALE
config.max_console_lines  = 200
config.autoscroll_console = true

local files = {

    script   = core.temp_filename(PLATFORM == "Windows" and ".bat"),
    script2  = core.temp_filename(PLATFORM == "Windows" and ".bat"),
    output   = core.temp_filename(),
    complete = core.temp_filename(),
}

local console = {}

local views = {}
local pending_threads = {}
local thread_active = false
local output = nil
local output_id = 0
local visible = false

function console.clear()

    output = {{text = "", time = 0}}
end

local function read_file(filename, offset)

    local fp = io.open(filename, "rb")
    fp:seek("set", offset or 0)

    local res = fp:read("*a")
    fp:close()

    return res
end

local function write_file(filename, text)

    local fp = io.open(filename, 'w')
    fp:write(text)
    fp:close()
end

local function lines(text)

    return (text .. '\n'):gmatch('(.-)\n')
end

local function push_output(str, opt)

    local first = true
    for line in lines(str) do

        if first then

            line = table.remove(output).text .. line
        end

        line = line:gsub('\x1b%[[%d;]+m', '') -- strip ANSI colors
        table.insert(output, {

            file_pattern = opt.file_pattern,

            text = line,
            time = os.time(),
            icon = line:find(opt.error_pattern)   and "!"
                or line:find(opt.warning_pattern) and "i"
        })

        if #output > config.max_console_lines then

            table.remove(output, 1)
            for view in pairs(views) do

                view:on_line_removed()
            end
        end

        first = false
    end

    output_id   = output_id + 1
    core.redraw = true
end

local function init_opt(opt)

    local res = {

        command = "",
        file_pattern = "[^?:%s]+%.[^?:%s]+",
        error_pattern = "error",
        warning_pattern = "warning",
        on_complete = function() end,
    }

    for k, v in pairs(res) do

        res[k] = opt[k] or v

    end
    return res
end

function console.run(opt)

    opt = init_opt(opt)

    local function thread()

        -- init script file(s)
        if PLATFORM == "Windows" then

            write_file(files.script, opt.command .. "\n")
            write_file(files.script2, string.format([[

                @echo off
                call %q >%q 2>&1
                echo "" >%q
                exit
            ]], files.script, files.output, files.complete))

            system.exec(string.format("call %q", files.script2))

        else

            write_file(files.script, string.format([[
                %s
                touch %q
            ]], opt.command, files.complete))

            system.exec(string.format("bash %q >%q 2>&1", files.script, files.output))
        end

        -- checks output file for change and reads
        local last_size = 0
        local function check_output_file()
        if PLATFORM == "Windows" then

            local fp = io.open(files.output)
            if fp then fp:close() end
        end

            local info = system.get_file_info(files.output)
            if info and info.size > last_size then

                local text = read_file(files.output, last_size)
                push_output(text, opt)
                last_size = info.size
            end
        end

        -- read output file until we get a file indicating completion
        while not system.get_file_info(files.complete) do

            check_output_file()
            coroutine.yield(0.1)
        end

        check_output_file()
        if output[#output].text ~= "" then

            push_output("\n", opt)
        end

        push_output("!DIVIDER\n", opt)

        -- clean up and finish
        for _, file in pairs(files) do

            os.remove(file)
        end

        opt.on_complete()

        -- handle pending thread
        local pending = table.remove(pending_threads, 1)

        if pending then

            core.add_thread(pending)
        else

            thread_active = false
        end
    end

    -- push/init thread
    if thread_active then

        table.insert(pending_threads, thread)
    else

        core.add_thread(thread)
        thread_active = true
    end

    -- make sure static console is visible if it's the only ConsoleView
    local count = 0
    for _ in pairs(views) do count = count + 1 end
    if count == 1 then visible = true end
end

local consoleview = view:extend()

function consoleview:new()

    consoleview.super.new(self)
    self.scrollable = true
    self.hovered_idx = -1
    views[self] = true
end

function consoleview:try_close(...)

    consoleview.super.try_close(self, ...)
    views[self] = nil
end

function consoleview:get_name()

    return "console"
end

function consoleview:get_line_height()

    return style.code_font:get_height() * config.line_height
end

function consoleview:get_line_count()

    return #output - (output[#output].text == "" and 1 or 0)
end

function consoleview:get_scrollable_size()

    return self:get_line_count() * self:get_line_height() + style.padding.y * 2
end

function consoleview:get_visible_line_range()

    local lh = self:get_line_height()
    local min = math.max(1, math.floor(self.scroll.y / lh))
    return min, min + math.floor(self.size.y / lh) + 1
end

function consoleview:on_mouse_moved(mx, my, ...)

    consoleview.super.on_mouse_moved(self, mx, my, ...)
    self.hovered_idx = 0
    for i, item, x,y,w,h in self:each_visible_line() do

        if mx >= x and my >= y and mx < x + w and my < y + h then

            if item.text:find(item.file_pattern) then
                self.hovered_idx = i
            end

            break
        end
    end
end

local function resolve_file(name)

    if system.get_file_info(name) then

        return name
    end

    local filenames = {}

    for _, f in ipairs(core.project_files) do
        table.insert(filenames, f.filename)
    end

    local t = common.fuzzy_match(filenames, name)
    return t[1]
end

function consoleview:on_line_removed()

    local diff = self:get_line_height()
    self.scroll.y = self.scroll.y - diff
    self.scroll.to.y = self.scroll.to.y - diff
end

function consoleview:on_mouse_pressed(button, x, y, ...)

    local caught = consoleview.super.on_mouse_pressed(self, button, x, y, ...)

    if caught then return end

    local item = output[self.hovered_idx]

    if item then

        local file, line, col = item.text:match(item.file_pattern)
        local resolved_file = resolve_file(file)

        if not resolved_file then

            core.error("couldn't resolve file \"%s\"", file)
            return
        end

        core.try(function()

            core.set_active_view(core.last_active_view)

            local dv = core.root_view:open_doc(

                core.open_doc(resolved_file)
            )

            if line then

                dv.doc:set_selection(line, col or 0)
                dv:scroll_to_line(line, false, true)
            end
        end)
    end
end

function consoleview:each_visible_line()

    return coroutine.wrap(function()

        local x, y = self:get_content_offset()
        local lh = self:get_line_height()
        local min, max = self:get_visible_line_range()
        y = y + lh * (min - 1) + style.padding.y
        max = math.min(max, self:get_line_count())

        for i = min, max do

            local item = output[i]

            if not item then break end
            coroutine.yield(i, item, x, y, self.size.x, lh)

            y = y + lh
        end
    end)
end

function consoleview:update(...)

    if self.last_output_id ~= output_id then

        if config.autoscroll_console then

            self.scroll.to.y = self:get_scrollable_size()
        end

        self.last_output_id = output_id
    end

    consoleview.super.update(self, ...)
end

function consoleview:draw()

    self:draw_background(style.background)
    local icon_w = style.icon_font:get_width("!")

    for i, item, x, y, w, h in self:each_visible_line() do

        local tx = x + style.padding.x
        local time = os.date("%H:%M:%S", item.time)
        local color = style.text

        if self.hovered_idx == i then
            color = style.accent
            renderer.draw_rect(x, y, w, h, style.line_highlight)
        end

        if item.text == "!DIVIDER" then

            local w = style.font:get_width(time)
            renderer.draw_rect(tx, y + h / 2, w, math.ceil(SCALE * 1), style.dim)

        else

            tx = common.draw_text(style.font, style.dim, time, 'left', tx, y, w, h)
            tx = tx + style.padding.x

            if item.icon then

                common.draw_text(style.icon_font, color, item.icon, 'left', tx, y, w, h)
            end

            tx = tx + icon_w + style.padding.x
            common.draw_text(style.code_font, color, item.text, 'left', tx, y, w, h)
        end
    end

    self:draw_scrollbar(self)
end

-- init static bottom-of-screen console
local view = consoleview()
local node = core.root_view:get_active_node()
node:split('down', view, true)

function view:update(...)

    local dest = visible and config.console_size or 0
    self:move_towards(self.size, "y", dest)
    consoleview.update(self, ...)
end

local last_command = ""

command.add(nil, {

    ["console:reset-output"] = function()

        if visible then

            output = {

                {text = "", time = 0}
            }
        end
    end,

    ["console:open-console"] = function()

        local _node = core.root_view:get_active_node()
        _node:add_view(consoleview())
    end,

    ["console:close"] = function()

        if visible and not
        core.command_view.visible then

            visible = false
        end
    end,

    ["console:toggle"] = function()

        visible = not visible
        command.perform('console:show-line')
    end,

    ["console:show-line"] = function()

        if visible then

            core.command_view.visible =
            not core.command_view.visible

            if core.command_view.visible then

                local p_path = ARGS[2] or EXEDIR

                if #p_path > 20 then p_path = p_path:match('.+([/\\][^/\\]+[/\\][^/\\]+)$') end
                if #p_path > 20 then p_path = p_path:match('.+([/\\][^/\\]+)$') end

                local prefix = 'lite ~ ' .. p_path .. ' $'

                core.command_view:set_text(last_command, true)
                core.command_view:enter(prefix,
                function(cmd)

                    console.run({command = cmd})
                    last_command = cmd
                end)

                core.command_view.visible = false
            end
        end
    end
})

local oldk = keymap.on_key_pressed
function keymap.on_key_pressed(k, ...)

    if k == 'escape' then

        command.perform("console:close")
    end

    oldk(k, ...)
end

keymap.add({

    ["ctrl+shift+tab"] = "console:toggle",
    ["ctrl+tab"]       = "console:show-line",
    ["ctrl+l"]         = "console:reset-output",
})

-- for `workspace` plugin:
package.loaded["plugins.console.view"] = consoleview

console.clear()
return console
