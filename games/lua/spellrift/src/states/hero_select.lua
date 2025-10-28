local UIHeroSelect = require("src.ui.ui_hero_select")
local Input = require("src.system.input")

local HeroSelect = {}
HeroSelect.__index = HeroSelect

function HeroSelect:enter()
    self.uiHeroSelect = UIHeroSelect.new()
    self.input = Input.new()
end

function HeroSelect:update(dt)
    self.input:update(dt)

    -- ESC → назад в главное меню
    if self.input:isEscapePressed() then
        if self.manager and self.manager.switch then
            self.manager:switch("main_menu")
        end
        return
    end

    -- ЛКМ → выбор героя и переход к выбору скилла
    if self.input:isLeftMousePressed() then
        local mx, my = self.input:getMousePosition()
        local heroId = self.uiHeroSelect:handleClick(mx, my)
        if heroId and self.manager and self.manager.switch then
            self.manager:switch("skill_select", heroId)
        end
    end
end

function HeroSelect:draw()
    self.uiHeroSelect:draw()
end

function HeroSelect:exit()
    self.uiHeroSelect = nil
    self.input = nil
end

return HeroSelect