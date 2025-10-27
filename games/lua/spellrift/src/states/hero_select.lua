local HeroSelect = {}
HeroSelect.__index = HeroSelect

local UIHeroSelect = require("src.ui.ui_hero_select")
local Input = require("src.system.input")

function HeroSelect:enter()
    -- UI выбора героя
    self.uiHeroSelect = UIHeroSelect.new()
    -- Ввод
    self.input = Input.new()
    -- Текущий выбор
    self.selectedHero = nil
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

    -- ЛКМ → выбор героя
    if self.input:isLeftMousePressed() then
        local mx, my = self.input:getMousePosition()
        self:handleMouseClick(mx, my)
    end
end

function HeroSelect:draw()
    self.uiHeroSelect:draw()
end

function HeroSelect:handleMouseClick(x, y)
    local selectedIndex = self.uiHeroSelect:handleClick(x, y)
    if selectedIndex then
        self.uiHeroSelect:selectByIndex(selectedIndex)
        self.selectedHero = self.uiHeroSelect:getSelectedHero()
        self:confirmSelection()
    end
end

function HeroSelect:confirmSelection()
    if self.selectedHero and self.manager and self.manager.switch then
        self.manager:switch("skill_select", self.selectedHero)
    end
end

function HeroSelect:exit()
    -- подчистка ссылок при выходе из состояния (по желанию)
    -- (ресурсы шрифтов/картинок UI обычно кэшируются менеджерами и не требуют явной выгрузки)
    self.uiHeroSelect = nil
    self.input = nil
    self.selectedHero = nil
end

return HeroSelect
