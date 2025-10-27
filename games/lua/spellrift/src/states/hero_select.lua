local HeroSelect = {}
HeroSelect.__index = HeroSelect

local UIHeroSelect = require("src.ui.ui_hero_select")
local StateManager = require("src.states.state_manager") -- поправлено имя файла (в Lua обычно без дефиса)
local Input = require("src.system.input")

function HeroSelect:enter()
    -- Создаем UI для выбора персонажа
    self.uiHeroSelect = UIHeroSelect.new()
    
    -- Создаем систему ввода
    self.input = Input.new()
    
    -- Текущий выбор
    self.selectedHero = nil
end

function HeroSelect:update(dt)
    -- Обновляем ввод
    self.input:update(dt)
    
    -- ESC → возврат в главное меню
    if self.input:isEscapePressed() then
        if StateManager and StateManager.switch then
            StateManager:switch("main_menu")
        end
        return
    end
    
    -- ЛКМ → выбор персонажа
    if self.input:isLeftMousePressed() then
        local mouseX, mouseY = self.input:getMousePosition()
        self:handleMouseClick(mouseX, mouseY)
    end
end

function HeroSelect:draw()
    self.uiHeroSelect:draw()
end

function HeroSelect:handleMouseClick(x, y)
    -- Получаем индекс выбранного героя
    local selectedIndex = self.uiHeroSelect:handleClick(x, y)
    
    if selectedIndex then
        self.uiHeroSelect:selectByIndex(selectedIndex)
        self.selectedHero = self.uiHeroSelect:getSelectedHero()
        self:confirmSelection()
    end
end

function HeroSelect:confirmSelection()
    if self.selectedHero then
        -- TODO: переход в игру, передача выбранного героя
        print("Selected hero:", self.selectedHero.config.name)
        -- if StateManager and StateManager.switch then
        --     StateManager:switch("game", self.selectedHero)
        -- end
    end
end

return HeroSelect
