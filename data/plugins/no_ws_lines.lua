local style    = require('core.style')
local config   = require('core.config')
local callback = require('core.callback')

callback.docv.body('no-whitespaces', {

    perform = function(self, idx, x, y)

        local text   = self.doc.lines[idx]
        local tx, ty = x, y + self:get_line_text_y_offset()
        local font   = self:get_font()

        if text:match('^[ \t]+\n?$') then

            local _, t = text:gsub('\t', '')
            t = t * config.indent_size

            local _, o = text:gsub(' ', '')
            t = t + o

            for c = 1, t do

                local color = style.selection
                renderer.draw_text(font, '.', tx, ty, color)
                tx = tx + font:get_width(' ')
            end

        elseif text:match('.+[ \t]+\n?$') then

            local i = text:find('[ \t]+\n?$')
            local m = text:sub(i, -1)

            local _, t = m:gsub('\t', '')
            t = t * config.indent_size

            local _, o = m:gsub(' ', '')
            t = t + o

            -- Fix offset to end of line --
            tx = x + (i - 1) * font:get_width(' ')

            for c = i, i - 1 + t do

                local color = style.guide or style.highlight_select
                renderer.draw_text(font, '.', tx, ty, color)
                tx = tx + font:get_width('.')
            end
        end
    end
})
