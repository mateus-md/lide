local core = require "core"
local translate = require "core.doc.translate"
local config = require "core.config"
local docview = require "core.docview"
local command = require "core.command"
local keymap = require "core.keymap"
local callback = require "core.callback"

config.autoinsert_map = {
    ["["] = "]",
    ["{"] = "}",
    ["("] = ")",
    ['"'] = '"',
    ["'"] = "'",
    ["`"] = "`",
}

local function is_closer(chr)

    for _, v in pairs(config.autoinsert_map) do

        if v == chr then return true end
    end
end

local function are_pairs(chr, otr)

    return chr == config.autoinsert_map[otr]
end


local function count_char(text, chr)
    local count = 0
    for _ in text:gmatch(chr) do
        count = count + 1
    end
    return count
end

callback.step.docv_input('autoin', {

    doabove = true,
    perform = function(self, text)

        do
            -- Ignore non-code lines --
            local _adoc = core.active_view.doc
            local cmmnt = _adoc.syntax.comment

            local line, col = _adoc:get_selection()
            local cntt = _adoc:get_text(line, 1, line, col)

            -- Skip it if file doesn't have an comment --
            local index
            if cmmnt then index = cntt:find(cmmnt, 1, true) end

            -- Do this only it has an potential comment
            if index then

                local safec = cntt
                local strng = safec:match('.-(".-").-')
                -- Remove all strings to avoid missmatches --
                while strng do

                    safec = safec:gsub(strng, string.rep(" ", #strng))
                    strng = safec:match('.-(".-").-')
                end

                local c = safec:find(cmmnt, 1, true)
                if c and col >= c then return text end
            end
        end

        local mapping = config.autoinsert_map[text]

        -- prevents plugin from operating on `CommandView`
        if getmetatable(self) ~= docview then

            return text
        end

        -- wrap selection if we have a selection
        if mapping and self.doc:has_selection() then

            local l1, c1, l2, c2, swap = self.doc:get_selection(true)

            self.doc:insert(l2, c2, mapping)
            self.doc:insert(l1, c1, text)
            self.doc:set_selection(l1, c1, l2, c2 + 2, swap)

            return
        end

        -- skip inserting closing text
        local chr = self.doc:get_char(self.doc:get_selection())
        if text == chr and is_closer(chr) then

            self.doc:move_to(1)
            return
        end

        -- don't insert closing quote if we have a non-even number on this line
        local line = self.doc:get_selection()
        if text == mapping and count_char(self.doc.lines[line], text) % 2 == 1 then

            return text
        end

        -- auto insert closing bracket
        if mapping and (chr:find('%s') or is_closer(chr) and chr ~= '"') then

            callback.__doc_input(self, text)
            callback.__doc_input(self, mapping)

            self.doc:move_to(-1)
            return
        end

        return text
    end
})

local function predicate()
    return getmetatable(core.active_view) == docview
        and not core.active_view.doc:has_selection()
end

command.add(predicate, {
    ["autoinsert:backspace"] = function()

        local doc  = core.active_view.doc
        local l, c = doc:get_selection()
        local char = doc:get_char(l, c)
        local othr = doc:get_char(l, c - 1)

        -- Only match with its respective pairs --
        if  is_closer(char)
        and are_pairs(char, othr) then

            doc:delete_to(1)
        end

        command.perform('doc:backspace')
    end,

    ["autoinsert:delete-to-previous-word-start"] = function()

        local doc = core.active_view.doc
        local le, ce = translate.previous_word_start(doc, doc:get_selection())

        while true do

            local l, c = doc:get_selection()

            if l == le and c == ce then break end
            command.perform('autoinsert:backspace')
        end
    end,
})

keymap.add {
    ["backspace"]            = "autoinsert:backspace",
    ["ctrl+backspace"]       = "autoinsert:delete-to-previous-word-start",
    ["ctrl+shift+backspace"] = "autoinsert:delete-to-previous-word-start",
}
