-- ui/main_menu.lua
-- Main menu UI
-- Public API: MainMenu.new(), mainMenu:draw(assets), mainMenu:handleClick(x, y)
-- Dependencies: constants.lua, colors.lua

local Constants = require("src.constants")
local Colors = require("src.ui.colors")
local UIConstants = require("src.ui.constants")

local MainMenu = {}
MainMenu.__index = MainMenu

-- === CONSTRUCTOR ===

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    return self
end

-- === DRAW ===

function MainMenu:draw(assets)
    Colors.setColor(Colors.BACKGROUND_PRIMARY)
    love.graphics.clear()
    
    local bg = assets.getImage("menuBg")
    if bg then
        Colors.setColor(Colors.TEXT_PRIMARY)
        local scaleX = love.graphics.getWidth() / bg:getWidth()
        local scaleY = love.graphics.getHeight() / bg:getHeight()
        love.graphics.draw(bg, 0, 0, 0, scaleX, scaleY)
    end
    
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, UIConstants.START_Y * 6, love.graphics.getWidth(), "center")
    
    -- Draw clickable "Start Game" button
    local buttonWidth = UIConstants.MENU_BUTTON_WIDTH
    local buttonHeight = UIConstants.MENU_BUTTON_HEIGHT
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = (love.graphics.getHeight() - buttonHeight) / 2
    
    -- Check if mouse is hovering over button
    local mx, my = love.mouse.getPosition()
    local isHovering = mx >= buttonX and mx <= buttonX + buttonWidth and
                       my >= buttonY and my <= buttonY + buttonHeight
    
    -- Draw button background
    if isHovering then
        Colors.setColor(Colors.BUTTON_HOVER)
    else
        Colors.setColor(Colors.BUTTON_DEFAULT)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, UIConstants.BUTTON_BORDER_RADIUS, UIConstants.BUTTON_BORDER_RADIUS)
    
    -- Draw button border
    Colors.setColor(Colors.BUTTON_BORDER)
    love.graphics.setLineWidth(UIConstants.BUTTON_BORDER_WIDTH)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, UIConstants.BUTTON_BORDER_RADIUS, UIConstants.BUTTON_BORDER_RADIUS)
    love.graphics.setLineWidth(1)
    
    -- Draw button text
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("START GAME", buttonX, buttonY + buttonHeight / 2 - UIConstants.FONT_LARGE / 2, buttonWidth, "center")
    
    -- Draw instruction text below
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_DIM)
    -- love.graphics.printf("Click button or press SPACE", 0, buttonY + 80, love.graphics.getWidth(), "center")
end

-- === INPUT ===

function MainMenu:isButtonHovered()
    local buttonWidth = UIConstants.MENU_BUTTON_WIDTH
    local buttonHeight = UIConstants.MENU_BUTTON_HEIGHT
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = (love.graphics.getHeight() - buttonHeight) / 2
    
    local mx, my = love.mouse.getPosition()
    return mx >= buttonX and mx <= buttonX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight
end

return MainMenu

