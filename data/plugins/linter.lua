-- original code by drmargarido --
-- reimplemented by mateus.md --

local core    = require('core')
local style   = require('core.style')
local command = require('core.command')
local config  = require('core.config')

local callback   = require('core.callback')
local statusview = require('core.statusview')

config.linter_box_line_limit = 80
config.linter_scan_interval = 0.1 -- scan every 100 ms

-- environments --
local is_windows   = PATHSEP == "\\"
local command_sep  = is_windows and "&" or ";"
local exitcode_cmd = is_windows and "echo %errorlevel%" or "echo $?"

local current_doc = nil
local cache = setmetatable({}, { __mode = "k" })
local hover_boxes = setmetatable({}, { __mode = "k" })
local linter_queue = {}
local linters = {}

local function completed(proc)
  local current_time = os.time()
  local diff = os.difftime(proc.start, current_time)
  if diff > proc.timeout then
    proc.fun_cllbck(nil, "timeout reached")
    return true
  end

  if not proc.doc.ref then -- if the doc is destroyed, delete the item too
    proc.fun_cllbck(nil, "weak reference destroyed")
    return true
  end

  local fp = io.open(proc.status)
  if io.type(fp) == "file" then
    local output = ""
    local exitcode = fp:read("*n")
    fp:close()
    os.remove(proc.status)

    fp = io.open(proc.output, "r")
    if io.type(fp) == "file" then
      output = fp:read("*a")
      fp:close()
      os.remove(proc.output)
    end

    proc.fun_cllbck({ output = output, exitcode = exitcode })
    return true
  end
  return false
end

local function lint_completion_thread()
  while true do
    coroutine.yield(config.linter_scan_interval)

    local j, n = 1, #linter_queue
    for i = 1, n, 1 do
      if not completed(linter_queue[i]) then
        -- move i to j since we want to keep it
        if i ~= j then
          linter_queue[j] = linter_queue[i]
          linter_queue[i] = nil
        end
        j = j + 1
      else
        -- remove i
        linter_queue[i] = nil
      end
    end
  end
end
core.add_thread(lint_completion_thread)

local function async_run_lint_cmd(_doc, path, linter, fun_cllbck, timeout)
  timeout = timeout or 10
  local cmd = linter.command:gsub("$FILENAME", path)
  local args = table.concat(linter.args or {}, " ")
  cmd = cmd:gsub("$ARGS", args)

  local output_file = core.temp_filename()
  local status_file = core.temp_filename()
  local start_time = os.time()
  cmd = string.format("%s > %q 2>&1 %s %s > %q",
                      cmd,
                      output_file,
                      command_sep,
                      exitcode_cmd,
                      status_file)
  system.exec(cmd)

  table.insert(linter_queue, {
    output = output_file,
    status = status_file,
    start = start_time,
    timeout = timeout,
    fun_cllbck = fun_cllbck,
    doc = setmetatable({ ref = _doc }, { __mode = 'v' })
  })
end

local function match_pattern(text, pattern, order, filename)
  if type(pattern) == "function" then
    return coroutine.wrap(function()
      pattern(text, filename)
    end)
  end

  if order == nil then
    return text:gmatch(pattern)
  end

  return coroutine.wrap(function()
    for one, two, three in text:gmatch(pattern) do
      local fields = {one, two, three}
      local ordered = {line = 1, col = 1, message = "syntax error"}
      for field,position in pairs(order) do
        ordered[field] = fields[position] or ordered[field]
        if
          field == "line"
          and current_doc ~= nil
          and tonumber(ordered[field]) > #current_doc.lines
        then
          ordered[field] = #current_doc.lines
        end
      end
      coroutine.yield(ordered.line, ordered.col, ordered.message)
    end
  end)
end


local function is_duplicate(line_warns, col, warn)
  for _, w in ipairs(line_warns) do
    if w.col == col and w.text == warn then
      return true
    end
  end
  return false
end

-- Escape string so it can be used in a lua pattern
local to_escape = {
  ["%"] = true,
  ["("] = true,
  [")"] = true,
  ["."] = true,
  ["+"] = true,
  ["-"] = true,
  ["*"] = true,
  ["["] = true,
  ["]"] = true,
  ["?"] = true,
  ["^"] = true,
  ["$"] = true
}
local function escape_to_pattern(text, count)
  count = count or 1
  local escaped = {}
  for char in text:gmatch(".") do
    if to_escape[char] then
      for _=1,count do
        table.insert(escaped, "%")
      end
    end
    table.insert(escaped, char)
  end
  return table.concat(escaped, "")
end

local err_data = {}
local function async_get_file_warnings(_doc, warnings, linter, fun_cllbck)

    local path = system.absolute_path(_doc.filename)
    local double_escaped = escape_to_pattern(path, 2)
    local pattern = linter.warning_pattern

    if type(pattern) == "string" then
        pattern = pattern:gsub("$FILENAME", double_escaped)
    end

    local function on_linter_completion(data, error)

        if data == nil then
            return fun_cllbck(nil, error)
        end

        local text = data.output
        if linter.expected_exitcodes then

            local valid_code = false
            for _, exitcode in ipairs(linter.expected_exitcodes) do

                if data.exitcode == exitcode then
                    valid_code = true
                    err_data.err = false
                end
            end

            if not valid_code then
                local l, c, e = text:match(pattern)

                err_data.lin = tonumber(l)
                err_data.col = tonumber(c)
                err_data.err = true
                err_data.msg = e
                -- store the text of the line with errors --
                err_data.text = core.active_view.doc.lines[err_data.lin]

                return fun_cllbck(nil, e, l)
            end
        end

        local order = linter.warning_pattern_order
        for line, col, warn in match_pattern(text, pattern, order, path) do

            line = tonumber(line)
            col = tonumber(col)
            if linter.column_starts_at_zero then
                col = col + 1
            end

            if not warnings[line] then
                warnings[line] = {}
            end

            local deduplicate = linter.deduplicate or false
            local exists = deduplicate and is_duplicate(warnings[line], col, warn)
            if not exists then
                table.insert(warnings[line], {col = col, text = warn})
            end
        end
        fun_cllbck(true)
    end

  async_run_lint_cmd(_doc, path, linter, on_linter_completion)
end

local function matches_any(filename, patterns)
  for _, ptn in ipairs(patterns) do
    if filename:find(ptn) then return true end
  end
end


local function matching_linters(filename)
  local matched = {}
  for _, l in ipairs(linters) do
    if matches_any(filename, l.file_patterns) then
      table.insert(matched, l)
    end
  end
  return matched
end


local function update_cache(_doc)
    local lints = matching_linters(_doc.filename or '')
    if not lints[1] then return end

    local d = {}
    for _, l in ipairs(lints) do
        async_get_file_warnings(_doc, d, l, function(success, error, line)

            if not success then
                core.log("found an error in %s at line %d: %s", _doc.filename, line, error)
                print(error)
                return
            end

            local i = 0
            for idx, t in pairs(d) do
                t.line_text = _doc.lines[idx] or ""
                i = i + 1
            end

            cache[_doc] = d
            if i > 1 then
                core.log("[%s] found %d warnings.", _doc.filename, i)
            elseif i == 1 then
                core.log("[%s] found one warning.", _doc.filename)
            end
        end)
    end
end


local function get_word_limits(v, line_text, x, col)
  if col == 0 then col = 1 end
  local _, e = line_text:sub(col):find(config.symbol_pattern)
  if not e or e <= 0 then e = 1 end
  e = e + col - 1

  local font = v:get_font()
  local x1 = x + font:get_width(line_text:sub(1, col - 1))
  local x2 = x + font:get_width(line_text:sub(1, e))
  return x1, x2
end

callback.clean('linter_cache', {
    doabove = true,
    perform = function(self)
        current_doc = self
        update_cache(self)
    end
})

callback.new_file('linter_cache', {
    doabove = true,
    perform = function(self)
        current_doc = self
        update_cache(self)
    end
})

callback.docv.mouse_wheel('linter_onmousewheel', {
    perform = function(self)
        hover_boxes[self] = nil
    end
})

callback.docv.mouse_move('linter_onmousemove', {
    perform = function(self, px, py)

        local hovered = {}
        if err_data.err then
            local x, y = self:get_line_screen_position(err_data.lin)
            local h    = self:get_line_height()

            local x1, x2 = get_word_limits(self, err_data.text, x, err_data.col)
            if px > x1 and px <= x2 and py > y and py <= y + h then

                hovered.x = px
                hovered.y = y + h

                hovered.error = err_data.msg
                hover_boxes[self] = hovered
                return
            else
                hovered.error = nil
                hover_boxes[self] = nil
            end
        end

        local _doc = self.doc
        local cached = cache[_doc]
        if not (cached) then return end

        -- check mouse is over this view
        local x, y, w, h = self.position.x, self.position.y, self.size.x, self.size.y
        if px < x or px > x + w or py < y or py > y + h then
            hover_boxes[self] = nil
            return
        end
        -- detect if any warning is hovered
        local hovered_w = {}
        for line, warnings in pairs(cached) do

            local text = _doc.lines[line]
            if text == warnings.line_text then

                for _, warning in ipairs(warnings) do
                    x, y = self:get_line_screen_position(line)
                    h    = self:get_line_height()

                    local x1, x2 = get_word_limits(self, text, x, warning.col)
                    if px > x1 and px <= x2 and py > y and py <= y + h then

                        table.insert(hovered_w, warning.text)
                        hovered.x = px
                        hovered.y = y + h
                    end
                end
            end
        end

        hovered.warnings = hovered_w
        hover_boxes[self] = hovered.warnings[1] and hovered
    end
})

callback.docv.line('linter_underliner', {
    perform = function(self, idx, x, y)

        local _doc = self.doc
        local text = _doc.lines[idx]

        -- if the code has an error and the index of --
        -- the current line to render is the same as --
        -- the error --
        if err_data.err and idx == err_data.lin then

            if text == err_data.text then
                local x1, x2 = get_word_limits(self, text, x, err_data.col)
                local color  = style.linter.error or style.syntax['keyword']
                local h      = style.divider_size
                local line_h = self:get_line_height()

                renderer.draw_rect(x1, y + line_h - h, x2 - x1, h, color)
            else
                err_data = {}
                hover_boxes[self] = nil
            end
        end

        local cached = cache[_doc]
        if not cached then return end

        local line_warnings = cached[idx]
        if not line_warnings then return end

        -- don't draw underlines if line text has changed
        if line_warnings.line_text ~= _doc.lines[idx] then
            return
        end

        -- draws lines in linted places --
        for _, warning in ipairs(line_warnings) do

            local x1, x2 = get_word_limits(self, text, x, warning.col)
            local color  = style.linter.warning or style.syntax.literal
            local h      = style.divider_size
            local line_h = self:get_line_height()
            renderer.draw_rect(x1, y + line_h - h, x2 - x1, h, color)
        end
    end
})


local function text_in_lines(text, max_len)
  local text_lines = {}
  local line = ""
  for word, seps in text:gmatch("([%S]+)([%c%s]*)") do
    if #line + #word > max_len then
      table.insert(text_lines, line)
      line = ""
    end
    line=line..word
    for sep in seps:gmatch(".") do
      if sep == "\n" then
        table.insert(text_lines, line)
        line = ""
      else
        line=line..sep
      end
    end
  end
  if #line > 0 then
    table.insert(text_lines, line)
  end
  return text_lines
end


local function draw_warning_box(hovered_item)
    local font = style.font
    local th = font:get_height()
    local pad = style.padding

    local max_len = config.linter_box_line_limit
    local full_text

    if hovered_item.error then full_text = hovered_item.error
    else
        full_text = table.concat(hovered_item.warnings, "\n\n")
    end
    local lines = text_in_lines(full_text, max_len)

    -- draw background rect
    local rx = hovered_item.x - pad.x
    local ry = hovered_item.y
    local text_width = 0
    for _, line in ipairs(lines) do
        local w = font:get_width(line)
        text_width = math.max(text_width, w)
    end

    local rw = text_width + pad.x * 2
    local rh = (th * #lines) + pad.y * 2
    renderer.draw_rect(rx, ry, rw, rh, style.background3)

    -- draw text
    local color = style.text
    local x = rx + pad.x
    for i, line in ipairs(lines) do
        local y = ry + pad.y + th * (i - 1)
        renderer.draw_text(font, line, x, y, color)
    end
end

callback.docv.draw('linter_warningbox', {
    perform = function(self)
        if hover_boxes[self] then
            core.root_view:defer_draw(draw_warning_box, hover_boxes[self])
        end
    end
})

local get_items = statusview.get_items
function statusview:get_items()
  local left, right  = get_items(self)

  local _doc = core.active_view.doc
  local cached = cache[_doc or ""]
  if cached then
    local count = 0
    for _, v in pairs(cached) do
      count = count + #v
    end
    table.insert(left, statusview.separator)
    if not _doc:is_dirty() and count > 0 then
      table.insert(left, style.text)
    else
      table.insert(left, style.dim)
    end
    table.insert(left, "warnings: " .. count)
  end

  return left, right
end


local function has_cached()
  return core.active_view.doc and cache[core.active_view.doc]
end

command.add(has_cached, {
  ["linter:move-to-next-warning"] = function()
    local _doc = core.active_view.doc
    local line = _doc:get_selection()
    local cached = cache[_doc]
    local idx, min = math.huge, math.huge
    for k in pairs(cached) do
      if type(k) == "number" then
        min = math.min(k, min)
        if k < idx and k > line then idx = k end
      end
    end
    idx = (idx == math.huge) and min or idx
    if idx == math.huge then
      core.error("document does not contain any warnings")
      return
    end
    if cached[idx] then
      _doc:set_selection(idx, cached[idx][1].col)
      core.active_view:scroll_to_line(idx, true)
    end
  end,
})


return {
  add_language = function(lang)
    table.insert(linters, lang)
  end,
  escape_to_pattern = escape_to_pattern
}
