local style = require('core.style')
local view  = require('core.view')

local draw = view.draw_scrollbar

function view:draw_scrollbar()

    local color, is_hovered = draw(self)

    local x, y, w, h = self:get_scrollbar_rect()

    if is_hovered then

        renderer.draw_rect(x + w - (w * 3), 0, w * 3, self.size.y + h * 1.5, style.scrollbar3)
        renderer.draw_rect(x + w - (w * 3), y, w * 3, h, color)
    else

        renderer.draw_rect(x + w - (w * 2.5), 0, w * 2.5, self.size.y + h * 1.5, style.scrollbar3)
        renderer.draw_rect(x + w - (w * 2.5), y, w * 2.5, h, color)
    end
end
