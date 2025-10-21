-- ui/character_select.lua
-- Character selection UI
-- Public API: CharacterSelect.new(), characterSelect:draw(assets, heroes, selectedIndex), characterSelect:handleClick(x, y, heroes)
-- Dependencies: constants.lua, colors.lua

local Constants = require("src.constants")
local Colors = require("src.ui.colors")

local CharacterSelect = {}
CharacterSelect.__index = CharacterSelect

-- === CONSTRUCTOR ===

function CharacterSelect.new()
    local self = setmetatable({}, CharacterSelect)
    return self
end

-- === DRAW ===

function CharacterSelect:draw(assets, heroes, selectedIndex)
    Colors.setColor(Colors.BACKGROUND_PRIMARY)
    love.graphics.clear()
    
    -- Title
    love.graphics.setFont(assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Your Hero", 0, 30, love.graphics.getWidth(), "center")
    
    -- Hero cards grid
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
        
        -- Hero name
        love.graphics.setFont(assets.getFont("large"))
        Colors.setColor(Colors.TEXT_PRIMARY)
        love.graphics.print(hero.name, cardX + 20, cardY + 30)
        
        -- Key stats with growth
        love.graphics.setFont(assets.getFont("default"))
        Colors.setColor(Colors.TEXT_SECONDARY)
        love.graphics.print("HP: " .. hero.baseHp .. " (+" .. hero.hpGrowth .. ")", cardX + 20, cardY + 70)
        love.graphics.print("Armor: " .. hero.baseArmor .. " (+" .. hero.armorGrowth .. ")", cardX + 20, cardY + 100)
        love.graphics.print("Speed: " .. hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. ")", cardX + 20, cardY + 130)
        love.graphics.print("Cast: " .. hero.baseCastSpeed .. "x (+" .. hero.castSpeedGrowth .. ")", cardX + 20, cardY + 160)
        
        -- Hero sprite
        local spriteX = cardX + cardWidth - 120
        local spriteY = cardY + 100
        
        love.graphics.setColor(1, 1, 1, 1)
        local spritesheet = assets.getSpritesheet("rogues")
        local quad = assets.getQuad("rogues", hero.spriteIndex)
        if spritesheet and quad then
            love.graphics.draw(spritesheet, quad, spriteX, spriteY, 0, 4, 4, 16, 16)
        end
        
        -- Passive ability description
        if hero.innateSkill and hero.innateSkill.description then
            local passiveY = cardY + 200
            local passiveHeight = 70
            
            Colors.setColor(Colors.ZONE_PASSIVE)
            love.graphics.rectangle("fill", cardX + 20, passiveY, cardWidth - 40, passiveHeight, 8, 8)
            
            love.graphics.setFont(assets.getFont("default"))
            Colors.setColor(Colors.TEXT_ACCENT)
            love.graphics.printf("Passive: " .. hero.innateSkill.description, cardX + 30, passiveY + 15, cardWidth - 60, "left")
        end
        
        -- Selection indicator
        if isSelected then
            Colors.setColor(Colors.ACCENT)
            love.graphics.setFont(assets.getFont("small"))
            love.graphics.printf("SELECTED", cardX, cardY + cardHeight - 20, cardWidth, "center")
        end
    end
    
    -- Instructions
    love.graphics.setFont(assets.getFont("default"))
    Colors.setColor(Colors.TEXT_DIM)
    love.graphics.printf("Click on a hero to select, then press SPACE/ENTER to continue", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function CharacterSelect:handleClick(x, y, heroes)
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

return CharacterSelect

