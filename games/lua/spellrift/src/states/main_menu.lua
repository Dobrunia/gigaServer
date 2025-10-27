local MainMenu = {}
MainMenu.__index = MainMenu

local UIMainMenu = require("src.ui.ui_main_menu")
local Input = require("src.system.input")

function MainMenu:enter()
    -- Создаем UI главного меню
    self.ui = UIMainMenu.new()

    -- Создаем систему ввода
    self.input = Input.new()
end

function MainMenu:update(dt)
    -- Обновляем ввод
    self.input:update(dt)

    -- Обработка ЛКМ - клик по кнопке "START GAME"
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
    -- Проверяем клик по кнопке "START GAME"
    if self.ui:isButtonHovered(x, y) then
        -- Меняем состояние через локальный менеджер
        if self.manager then
            self.manager:switch("hero_select")
        else
            print("[WARN] No state manager linked to MainMenu")
        end
    end
end

return MainMenu
