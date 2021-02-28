local common   = require('core.common')
local style    = require('core.style')
local callback = require('core.callback')

local white = {common.color('#ffffff')}
local black = {common.color('#000000')}

local function draw_color_previews(self, idx, x, y, ptn, base, nibbles)

    local text = self.doc.lines[idx]
    local e, s = 0

    while true do
        s, e = text:find(ptn, e + 1)
        if not s then break end

        do  -- Ignore non-code lines --
            local cmmnt = self.doc.syntax.comment
            local index

            -- Skip it if file doesn't have an comment --
            if cmmnt then index = text:find(cmmnt, math.min(s - #cmmnt - 1, 1), true) end

            -- Do this only it has an potential comment
            if index then

                local safec = text
                local strng = safec:match('.-(".-").-')
                -- Remove all strings to avoid missmatches --
                while strng do

                    safec = safec:gsub(strng, string.rep(" ", #strng))
                    strng = safec:match('.-(".-").-')
                end

                if safec:find(cmmnt, math.min(s - #cmmnt - 1, 1), true) then break end
            end
        end

        local str = text:sub(s, e)
        local r, g, b = str:match(ptn)
        r, g, b = tonumber(r, base), tonumber(g, base), tonumber(b, base)

        -- #123 becomes #112233
        if nibbles then

            r = r * 16
            g = g * 16
            b = b * 16
        end

        local x1 = x + self:get_col_x_offset(idx, s)
        local x2 = x + self:get_col_x_offset(idx, e + 1)
        local oy = self:get_line_text_y_offset()

        local text_color = math.max(r, g, b) < 128 and white or black

        local tmp = {}; tmp[1], tmp[2], tmp[3] = r, g, b
        local l1, _, l2 = self.doc:get_selection(true)

        local line, col = self.doc:get_selection()

        if not (self.doc:has_selection() and idx >= l1 and idx <= l2) then

            renderer.draw_rect(x1, y, x2 - x1, self:get_line_height(), tmp)
            renderer.draw_text(self:get_font(), str, x1, y + oy, text_color)

            -- redraw the caret --
            if idx == line and col >= s and col <= e + 1 then
                local lh = self:get_line_height()
                local cx = x + self:get_col_x_offset(line, col)
                renderer.draw_rect(cx, y, style.caret_width, lh, text_color)
            end
        end
    end
end

callback.docv.body('colorprev', {
    perform = function(self, idx, x, y)

        draw_color_previews(self, idx, x, y, '#(%x%x)(%x%x)(%x%x)%f[%W]',        16)
        draw_color_previews(self, idx, x, y, 'rgba?%((%d+)%D+(%d+)%D+(%d+).-%)', 10)
    end
})
