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

    -- Фон: загружаем изображение (важно освободить в exit)
    self.bgImage = love.graphics.newImage("assets/bg.jpg")
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
    -- Фон
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    if self.bgImage then
        local iw, ih = self.bgImage:getWidth(), self.bgImage:getHeight()
        local scale = math.max(w / iw, h / ih)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.bgImage, w * 0.5, h * 0.5, 0, scale, scale, iw * 0.5, ih * 0.5)
    else
        love.graphics.clear(0, 0, 0, 1)
    end

    -- Общая затемняющая вуаль
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, 1)

    -- Рисуем UI главного меню (включая затемнённую панель под кнопками)
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

function MainMenu:exit()
    -- Важно: удалить фон из памяти
    if self.bgImage and self.bgImage.release then
        self.bgImage:release()
        self.bgImage = nil
    end
end

return MainMenu
