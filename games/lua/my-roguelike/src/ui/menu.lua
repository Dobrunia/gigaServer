-- ui/menu.lua
-- Main menu and character selection UI
-- Public API: Menu.new(), menu:update(dt), menu:draw(), menu:handleClick(x, y)
-- Dependencies: constants.lua, assets.lua

local Constants = require("src.constants")

local Menu = {}
Menu.__index = Menu

-- === CONSTRUCTOR ===

function Menu.new()
    local self = setmetatable({}, Menu)
    
    self.buttons = {}
    self.hoveredButton = nil
    
    return self
end

-- === MAIN MENU ===

function Menu:createMainMenuButtons()
    self.buttons = {}
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Play button
    table.insert(self.buttons, {
        text = "PLAY",
        x = screenW / 2 - Constants.MENU_BUTTON_WIDTH / 2,
        y = screenH / 2,
        width = Constants.MENU_BUTTON_WIDTH,
        height = Constants.MENU_BUTTON_HEIGHT,
        action = "play"
    })
    
    -- Quit button
    table.insert(self.buttons, {
        text = "QUIT",
        x = screenW / 2 - Constants.MENU_BUTTON_WIDTH / 2,
        y = screenH / 2 + Constants.MENU_BUTTON_HEIGHT + 20,
        width = Constants.MENU_BUTTON_WIDTH,
        height = Constants.MENU_BUTTON_HEIGHT,
        action = "quit"
    })
end

function Menu:drawMainMenu(assets)
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    -- Background
    local bg = assets.getImage("menuBg")
    if bg then
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.draw(bg, 0, 0)
    end
    
    -- Title
    love.graphics.setFont(assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, 150, love.graphics.getWidth(), "center")
    
    -- Buttons
    love.graphics.setFont(assets.getFont("default"))
    for _, button in ipairs(self.buttons) do
        self:drawButton(button)
    end
end

-- === CHARACTER SELECT ===

function Menu:drawCharacterSelect(assets, heroes, selectedIndex)
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    -- Title
    love.graphics.setFont(assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Your Hero", 0, 50, love.graphics.getWidth(), "center")
    
    -- Hero card
    local hero = heroes[selectedIndex]
    if not hero then return end
    
    local cardX = love.graphics.getWidth() / 2 - Constants.CHAR_CARD_WIDTH / 2
    local cardY = 200
    
    -- Card background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", cardX, cardY, Constants.CHAR_CARD_WIDTH, Constants.CHAR_CARD_HEIGHT)
    
    -- Hero sprite (left side)
    local spriteSize = 128
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = assets.getImage("player")  -- TODO: Different sprites per hero
    if sprite then
        love.graphics.draw(sprite, cardX + 30, cardY + Constants.CHAR_CARD_HEIGHT / 2, 0, 4, 4, sprite:getWidth() / 2, sprite:getHeight() / 2)
    end
    
    -- Stats (right side)
    love.graphics.setFont(assets.getFont("default"))
    local textX = cardX + spriteSize + 60
    local textY = cardY + 20
    local lineHeight = 25
    
    love.graphics.print(hero.name, textX, textY)
    love.graphics.setFont(assets.getFont("small"))
    textY = textY + 30
    
    love.graphics.print("Max HP: " .. hero.baseHp .. " (+" .. hero.hpGrowth .. " per level)", textX, textY)
    textY = textY + lineHeight
    love.graphics.print("Armor: " .. hero.baseArmor .. " (+" .. hero.armorGrowth .. " per level)", textX, textY)
    textY = textY + lineHeight
    love.graphics.print("Move Speed: " .. hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. " per level)", textX, textY)
    textY = textY + lineHeight
    love.graphics.print("Cast Speed: " .. hero.baseCastSpeed .. " (+" .. hero.castSpeedGrowth .. " per level)", textX, textY)
    
    -- Navigation hint
    love.graphics.setFont(assets.getFont("default"))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("< LEFT   RIGHT >", 0, cardY + Constants.CHAR_CARD_HEIGHT + 40, love.graphics.getWidth(), "center")
    love.graphics.printf("SPACE / ENTER to select", 0, cardY + Constants.CHAR_CARD_HEIGHT + 70, love.graphics.getWidth(), "center")
    
    -- Page indicator
    love.graphics.printf(selectedIndex .. " / " .. #heroes, 0, cardY + Constants.CHAR_CARD_HEIGHT + 100, love.graphics.getWidth(), "center")
end

-- === BUTTON DRAWING ===

function Menu:drawButton(button)
    local isHovered = (self.hoveredButton == button)
    
    -- Button background
    if isHovered then
        love.graphics.setColor(0.4, 0.4, 0.5, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.3, 1)
    end
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    
    -- Button border
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
    love.graphics.setLineWidth(1)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(button.text, button.x, button.y + button.height / 2 - 12, button.width, "center")
end

-- === INPUT ===

function Menu:updateHover(mouseX, mouseY)
    self.hoveredButton = nil
    
    for _, button in ipairs(self.buttons) do
        if mouseX >= button.x and mouseX <= button.x + button.width and
           mouseY >= button.y and mouseY <= button.y + button.height then
            self.hoveredButton = button
            break
        end
    end
end

function Menu:handleClick(x, y)
    for _, button in ipairs(self.buttons) do
        if x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end
    return nil
end

return Menu

