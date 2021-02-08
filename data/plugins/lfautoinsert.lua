local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"

config.lfautoinsert_map = {
    ["{%s*\n"] = "}",
    ["%(%s*\n"] = ")",
    ["%f[[]%[%s*\n"] = "]",
    ["%[%[%s*\n"] = "]]",
    ["=%s*\n"] = false,
    [":%s*\n"] = false,
    ["^#if.*\n"] = "#endif",
    ["^#else.*\n"] = "#endif",
    ["%f[%w]do%s*\n"] = "end",
    ["%f[%w]then%s*\n"] = {"end", "else"},
    ["%f[%w]else%s*\n"] = "end",
    ["%f[%w]elseif%s*\n"] = {"end", "else"},
    ["%f[%w]repeat%s*\n"] = "until",
    ["%f[%w]function.*%)%s*\n"] = "end",
    ["^%s*<([^/][^%s>]*)[^>]*>%s*\n"] = "</$TEXT>",
}

local function indent_size(doc, line)

    local text = doc.lines[line] or ""
    local s, e = text:find("^[\t ]*")
    return e - s
end

command.add("core.docview", {

    ["autoinsert:newline"] = function()

        command.perform("doc:newline")

        local doc = core.active_view.doc
        local line, col = doc:get_selection()
        local text = doc.lines[line - 1]

        -- Ignore non-code lines --
        local cmmnt = doc.syntax.comment
        local index

        -- Skip it if file lang doesn't have an comment --
        if cmmnt then index = text:find(cmmnt, 1, true) end

        -- Do this only it has an potential comment
        if index then

            local safec = text
            local strng = safec:match('.-(".-").-')
            -- Remove all strings to avoid missmatches --
            while strng do

                safec = safec:gsub(strng, string.rep(" ", #strng))
                strng = safec:match('.-(".-").-')
            end

            local c = safec:find(cmmnt, 1, true)
            if c and col >= c then return end
        end

        for ptn, close in pairs(config.lfautoinsert_map) do

            local s, _, str = text:find(ptn)
            if s then

                local next = doc.lines[line + 1] or ''

                if  close and col == #doc.lines[line]
                and indent_size(doc, line + 1)
                 <= indent_size(doc, line - 1) then

                    close = str and type(close) == 'string' and close:gsub("$TEXT", str) or close

                    if type(close) == 'table' then

                        local tabsz = doc.lines[line - 1]:match('^(%s*)')
                        -- Only consider keywords of the same scope --
                        if not (next:match('^' .. tabsz .. '[^ ]')) then next = '' end

                        local nis_1 = next:match(tabsz .. close[1])
                        local nis_2 = next:match(tabsz .. close[2])

                        if not nis_1 and not nis_2 then

                            command.perform("doc:newline")
                            core.active_view:on_text_input(close[1])

                        elseif not nis_2 then

                            command.perform("doc:newline")
                            core.active_view:on_text_input(close[2])

                        else return end
                    else
                        command.perform("doc:newline")
                        core.active_view:on_text_input(close)
                    end

                    command.perform("doc:move-to-previous-line")

                    if doc.lines[line + 1] == doc.lines[line + 2] then

                        doc:remove(line + 1, 1, line + 2, 1)
                    end

                elseif col < #doc.lines[line] and str and text:find(str .. '$') then

                    command.perform("doc:newline")
                    command.perform("doc:move-to-previous-line")
                end

                command.perform("doc:indent")
            end
        end
    end
})

keymap.add({
    ["return"] = {"command:submit", "autoinsert:newline"}
})
