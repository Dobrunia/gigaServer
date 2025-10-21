-- ui/menu.lua
-- Main menu and character selection UI
-- Public API: Menu.new(), menu:update(dt), menu:draw(), menu:handleClick(x, y)
-- Dependencies: constants.lua, assets.lua

local Constants = require("src.constants")
local Colors = require("src.ui.colors")

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
    love.graphics.printf("Choose Your Hero", 0, 30, love.graphics.getWidth(), "center")
    
    -- Hero cards grid (doubled sizes)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local cardWidth = 500
    local cardHeight = 320
    local cardSpacing = 40
    local cardsPerRow = 3
    local startY = 80
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, hero in ipairs(heroes) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = ((i - 1) % cardsPerRow)
        
        local cardX = startX + col * (cardWidth + cardSpacing)
        local cardY = startY + row * (cardHeight + cardSpacing)
        
        -- Check if mouse is hovering over this card
        local mx, my = love.mouse.getPosition()
        local isHovered = mx >= cardX and mx <= cardX + cardWidth and
                         my >= cardY and my <= cardY + cardHeight
        local isSelected = (i == selectedIndex)
        
        -- Card background
        if isSelected then
            Colors.setColor(Colors.CARD_SELECTED)
        elseif isHovered then
            Colors.setColor(Colors.CARD_HOVER)
        else
            Colors.setColor(Colors.CARD_DEFAULT)
        end
        love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 8, 8)
        
        -- Card border
        if isSelected then
            Colors.setColor(Colors.BORDER_SELECTED)
            love.graphics.setLineWidth(3)
        else
            Colors.setColor(Colors.BORDER_DEFAULT)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, 8, 8)
        love.graphics.setLineWidth(1)
        
        -- Hero name (doubled font size)
        love.graphics.setFont(assets.getFont("large"))
        Colors.setColor(Colors.TEXT_PRIMARY)
        love.graphics.print(hero.name, cardX + 20, cardY + 30)
        
        -- Key stats with growth (doubled font size)
        love.graphics.setFont(assets.getFont("default"))
        Colors.setColor(Colors.TEXT_SECONDARY)
        love.graphics.print("HP: " .. hero.baseHp .. " (+" .. hero.hpGrowth .. ")", cardX + 20, cardY + 70)
        love.graphics.print("Armor: " .. hero.baseArmor .. " (+" .. hero.armorGrowth .. ")", cardX + 20, cardY + 100)
        love.graphics.print("Speed: " .. hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. ")", cardX + 20, cardY + 130)
        love.graphics.print("Cast: " .. hero.baseCastSpeed .. "x (+" .. hero.castSpeedGrowth .. ")", cardX + 20, cardY + 160)
        
        -- Hero sprite (aligned with text horizontally)
        local spriteX = cardX + cardWidth - 120
        local spriteY = cardY + 100  -- Same Y as first stat line
        
        love.graphics.setColor(1, 1, 1, 1)
        local spritesheet = assets.getSpritesheet("rogues")
        local quad = assets.getQuad("rogues", hero.spriteIndex)
        if spritesheet and quad then
            love.graphics.draw(spritesheet, quad, spriteX, spriteY, 0, 4, 4, 16, 16)  -- Doubled sprite size
        end
        
        -- Dark background for passive ability description (with more padding)
        if hero.innateSkill and hero.innateSkill.description then
            local passiveY = cardY + 200
            local passiveHeight = 70
            
            -- Dark background for passive text (with more padding)
            Colors.setColor(Colors.ZONE_PASSIVE)
            love.graphics.rectangle("fill", cardX + 20, passiveY, cardWidth - 40, passiveHeight, 8, 8)
            
            -- Passive ability description (with more padding)
            love.graphics.setFont(assets.getFont("default"))
            Colors.setColor(Colors.TEXT_ACCENT)
            love.graphics.printf("Passive: " .. hero.innateSkill.description, cardX + 30, passiveY + 15, cardWidth - 60, "left")
        end
        
        -- Selection indicator (moved to bottom)
        if isSelected then
            Colors.setColor(Colors.ACCENT)
            love.graphics.setFont(assets.getFont("small"))
            love.graphics.printf("SELECTED", cardX, cardY + cardHeight - 20, cardWidth, "center")
        end
    end
    
    -- Instructions
    love.graphics.setFont(assets.getFont("default"))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Click on a hero to select, then press SPACE/ENTER to start", 0, screenH - 40, screenW, "center")
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

function Menu:handleHeroCardClick(x, y, heroes)
    local screenW = love.graphics.getWidth()
    local cardWidth = 500
    local cardHeight = 320
    local cardSpacing = 40
    local cardsPerRow = 3
    local startY = 80
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, hero in ipairs(heroes) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = ((i - 1) % cardsPerRow)
        
        local cardX = startX + col * (cardWidth + cardSpacing)
        local cardY = startY + row * (cardHeight + cardSpacing)
        
        -- Check if click is within this card
        if x >= cardX and x <= cardX + cardWidth and
           y >= cardY and y <= cardY + cardHeight then
            return i  -- Return hero index
        end
    end
    
    return nil
end

return Menu

