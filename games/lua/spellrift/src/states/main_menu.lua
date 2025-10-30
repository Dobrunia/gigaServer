local MainMenu = {}
MainMenu.__index = MainMenu

local UIMainMenu = require("src.ui.ui_main_menu")
local Input = require("src.system.input")

function MainMenu:enter()
    -- Создаем UI главного меню
    self.ui = UIMainMenu.new()

    -- Создаем систему ввода
    self.input = Input.new()
    self.input:snapshotNow()
end

function MainMenu:update(dt)
    -- Обновляем ввод
    self.input:update(dt)

    -- Обработка ЛКМ - клики по кнопкам меню
    if self.input:isLeftMousePressed() then
        local mouseX, mouseY = self.input:getMousePosition()
        self:handleMouseClick(mouseX, mouseY)
    end

    -- Обработка ESC - выход из игры
    if self.input:isEscapePressed() then
        love.event.quit()
    end
end

function MainMenu:draw()
    -- Рисуем UI главного меню
    self.ui:draw()
end

function MainMenu:handleMouseClick(x, y)
    local hit = (self.ui.hitTest and self.ui:hitTest(x, y)) or (self.ui:isButtonHovered(x, y) and "start")
    if hit == "start" then
        if self.manager then
            self.manager:switch("hero_select")
        end
    elseif hit == "almanac" then
        -- Заглушка: позже добавить экран альманаха
        -- Пока просто печатаем в консоль, оставляем в main menu
        print("[INFO] Almanac is not implemented yet")
    end
end

return MainMenu
