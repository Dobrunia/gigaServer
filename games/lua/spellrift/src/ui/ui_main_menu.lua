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
    return self
end

-- === DRAW ===

function UIMainMenu:draw()
    love.graphics.setColor(COLOR_BUTTON_DEFAULT)
    love.graphics.clear()
    
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, UIConstants.START_Y * 6, love.graphics.getWidth(), "center")
    
    -- Получаем позицию кнопки
    local buttonX = (love.graphics.getWidth() - MENU_BUTTON_WIDTH) / 2
    local buttonY = (love.graphics.getHeight() - MENU_BUTTON_HEIGHT) / 2
    local mx, my = love.mouse.getPosition()
    local isHovered = mx >= buttonX and mx <= buttonX + MENU_BUTTON_WIDTH and my >= buttonY and my <= buttonY + MENU_BUTTON_HEIGHT
    -- Draw button background
    if isHovered then
        love.graphics.setColor(COLOR_BUTTON_HOVER)
    else
        love.graphics.setColor(COLOR_BUTTON_DEFAULT)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    
    -- Draw button border
    love.graphics.setColor(BUTTON_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", buttonX, buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    love.graphics.setLineWidth(1)
    
    -- Draw button text
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("START GAME", buttonX, buttonY + MENU_BUTTON_HEIGHT / 2 - UIConstants.FONT_LARGE / 2, MENU_BUTTON_WIDTH, "center")
end

return UIMainMenu