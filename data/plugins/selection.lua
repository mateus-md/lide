local style    = require('core.style')
local docview  = require('core.docview')
local callback = require('core.callback')

-- originally written by luveti
-- modified by mateus.md

callback.docv.line('select_hgtlgt', {

    doabove = true,
    perform = function(self, idx, x, y)

        local line1, col1, line2, col2 = self.doc:get_selection(true)
        if line1 == line2 and col1 ~= col2 then

            local lh = self:get_line_height()
            local selected_text = self.doc.lines[line1]:sub(col1, col2 - 1)
            local current_line_text = self.doc.lines[idx]
            local last_col = 1
            while true do

                local start_col, end_col = current_line_text:find(selected_text, last_col, true)
                if start_col == nil then break end

                local x1 = x + self:get_col_x_offset(idx, start_col)
                local x2 = x + self:get_col_x_offset(idx, end_col + 1)

                -- Ignore whitespace selections --
                if not selected_text:match('^[ \t]+\n?$') then

                    renderer.draw_rect(x1, y, x2 - x1, lh, style.selection)
                end

                last_col = end_col + 1
            end
        end
    end
})
