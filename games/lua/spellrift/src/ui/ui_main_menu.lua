local UIConstants = require("src.ui.ui_constants")

local UIMainMenu = {}
UIMainMenu.__index = UIMainMenu

local MENU_BUTTON_WIDTH = 200
local MENU_BUTTON_HEIGHT = 40

local COLOR_BUTTON_DEFAULT = {0.2, 0.2, 0.2, 1}
local COLOR_BUTTON_HOVER = {0.4, 0.4, 0.4, 1}
local BUTTON_BORDER = {0.8, 0.8, 0.8, 1}
local BUTTON_BORDER_RADIUS = 8

function UIMainMenu.new()
    local self = setmetatable({}, UIMainMenu)
    
    -- Вычислим позицию кнопки один раз
    self.buttonX = (love.graphics.getWidth() - MENU_BUTTON_WIDTH) / 2
    self.buttonY = (love.graphics.getHeight() - MENU_BUTTON_HEIGHT) / 2
    
    return self
end

function UIMainMenu:isButtonHovered(x, y)
    return x >= self.buttonX and x <= self.buttonX + MENU_BUTTON_WIDTH
        and y >= self.buttonY and y <= self.buttonY + MENU_BUTTON_HEIGHT
end

function UIMainMenu:draw()
    love.graphics.setColor(COLOR_BUTTON_DEFAULT)
    love.graphics.clear()

    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, UIConstants.START_Y * 6, love.graphics.getWidth(), "center")

    -- Проверка наведения
    local mx, my = love.mouse.getPosition()
    local isHovered = self:isButtonHovered(mx, my)

    -- Кнопка
    love.graphics.setColor(isHovered and COLOR_BUTTON_HOVER or COLOR_BUTTON_DEFAULT)
    love.graphics.rectangle("fill", self.buttonX, self.buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)

    -- Обводка
    love.graphics.setColor(BUTTON_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.buttonX, self.buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    love.graphics.setLineWidth(1)

    -- Текст
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("START GAME", self.buttonX, self.buttonY + MENU_BUTTON_HEIGHT / 2 - UIConstants.FONT_LARGE / 2, MENU_BUTTON_WIDTH, "center")
end

return UIMainMenu
