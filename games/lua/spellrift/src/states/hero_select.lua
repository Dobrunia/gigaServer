local HeroSelect = {}
HeroSelect.__index = HeroSelect

local UIHeroSelect = require("src.ui.ui_hero_select")
local StateManager = require("src.states.state-manager")
local Input = require("src.system.input")

function HeroSelect:enter()
    -- Создаем UI для выбора персонажа
    self.uiHeroSelect = UIHeroSelect.new()
    
    -- Создаем систему ввода
    self.input = Input.new()
    
    -- Выбранный персонаж
    self.selectedCharacter = nil
end

function HeroSelect:update(dt)
    -- Обновляем ввод
    self.input:update(dt)
    
    -- Обработка ESC - возврат в меню
    if self.input:isEscapePressed() then
        StateManager:switch("menu")
    end
    
    -- Обработка ЛКМ - выбор персонажа
    if self.input:isLeftMousePressed() then
        local mouseX, mouseY = self.input:getMousePosition()
        self:handleMouseClick(mouseX, mouseY)
    end
end

function HeroSelect:draw()
    -- Рисуем UI выбора персонажа
    self.uiHeroSelect:draw()
end

function HeroSelect:handleMouseClick(x, y)
    -- Обработка клика мыши по карточке персонажа
    local selectedIndex = self.uiHeroSelect:handleClick(x, y, self.uiHeroSelect.heroes)
    
    if selectedIndex then
        self.uiHeroSelect:selectByIndex(selectedIndex)
        self.selectedHero = self.uiHeroSelect:getSelectedHero()
        
        -- Автоматически переходим в игру после выбора
        self:confirmSelection()
    end
end

function HeroSelect:confirmSelection()
    if self.selectedHero then
        -- Переходим в игру с выбранным персонажем
        print("dfdfdf")
    end
end

return HeroSelect