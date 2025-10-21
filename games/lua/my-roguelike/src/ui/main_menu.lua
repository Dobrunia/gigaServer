-- ui/main_menu.lua
-- Main menu UI
-- Public API: MainMenu.new(), mainMenu:draw(assets), mainMenu:handleClick(x, y)
-- Dependencies: constants.lua, colors.lua

local Constants = require("src.constants")
local Colors = require("src.ui.colors")

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
        love.graphics.draw(bg, 0, 0)
    end
    
    love.graphics.setFont(assets.getFont("large"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, 200, love.graphics.getWidth(), "center")
    
    -- Draw clickable "Start Game" button
    local buttonWidth = 300
    local buttonHeight = 60
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = 400
    
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
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 10, 10)
    
    -- Draw button border
    Colors.setColor(Colors.BUTTON_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Draw button text
    love.graphics.setFont(assets.getFont("large"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("START GAME", buttonX, buttonY + 15, buttonWidth, "center")
    
    -- Draw instruction text below
    love.graphics.setFont(assets.getFont("small"))
    Colors.setColor(Colors.TEXT_DIM)
    love.graphics.printf("Click button or press SPACE", 0, buttonY + 80, love.graphics.getWidth(), "center")
end

-- === INPUT ===

function MainMenu:isButtonHovered()
    local buttonWidth = 300
    local buttonHeight = 60
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = 400
    
    local mx, my = love.mouse.getPosition()
    return mx >= buttonX and mx <= buttonX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight
end

return MainMenu

