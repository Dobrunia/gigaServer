local UIConstants = require("src.ui.constants")

local MainMenu = {}
MainMenu.__index = MainMenu

local MENU_BUTTON_WIDTH = 200
local MENU_BUTTON_HEIGHT = 40

local COLOR_BUTTON_DEFAULT
local COLOR_BUTTON_HOVER
BUTTON_BORDER
BUTTON_BORDER_RADIUS

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    return self
end

-- === DRAW ===

function MainMenu:draw(assets)
    Colors.setColor(UIConstants.COLOR_BACKGROUND_PRIMARY)
    love.graphics.clear()
    
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(UIConstants.COLOR_TEXT_PRIMARY)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, UIConstants.START_Y * 6, love.graphics.getWidth(), "center")
    
    -- Draw button background
    if self:isButtonHovered() then
        Colors.setColor(COLOR_BUTTON_DEFAULT)
    else
        Colors.setColor(COLOR_BUTTON_DEFAULT)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    
    -- Draw button border
    Colors.setColor(BUTTON_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", buttonX, buttonY, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    love.graphics.setLineWidth(1)
    
    -- Draw button text
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("START GAME", buttonX, buttonY + MENU_BUTTON_HEIGHT / 2 - UIConstants.FONT_LARGE / 2, buttonWidth, "center")
    
    -- Draw instruction text below
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_DIM)
    -- love.graphics.printf("Click button or press SPACE", 0, buttonY + 80, love.graphics.getWidth(), "center")
end

-- === INPUT ===

function MainMenu:isButtonHovered()
    local buttonX = (love.graphics.getWidth() - MENU_BUTTON_WIDTH) / 2
    local buttonY = (love.graphics.getHeight() - MENU_BUTTON_HEIGHT) / 2
    
    local mx, my = love.mouse.getPosition()
    return mx >= buttonX and mx <= buttonX + MENU_BUTTON_WIDTH and
           my >= buttonY and my <= buttonY + MENU_BUTTON_HEIGHT
end

return MainMenu

