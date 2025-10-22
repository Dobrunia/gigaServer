-- ui/character_select.lua
-- Character selection UI
-- Public API: CharacterSelect.new(), characterSelect:draw(assets, heroes, selectedIndex), characterSelect:handleClick(x, y, heroes)

local Colors = require("src.ui.colors")
local Icons = require("src.ui.icons")
local UIConstants = require("src.ui.constants")

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
    
    local bg = assets.getImage("menuBg")
    if bg then
        Colors.setColor(Colors.TEXT_PRIMARY)
        local scaleX = love.graphics.getWidth() / bg:getWidth()
        local scaleY = love.graphics.getHeight() / bg:getHeight()
        love.graphics.draw(bg, 0, 0, 0, scaleX, scaleY)
    end
    
    -- Title
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("Choose Your Hero", 0, UIConstants.START_Y, love.graphics.getWidth(), "center")
    
    -- Hero cards grid
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local cardWidth = UIConstants.CARD_WIDTH
    local cardHeight = UIConstants.CARD_HEIGHT
    local cardSpacing = UIConstants.CARD_SPACING
    local cardsPerRow = UIConstants.CARDS_PER_ROW
    local startY = UIConstants.CARDS_START_Y
    
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
        -- Card background
        if isHovered then
            Colors.setColor(Colors.CARD_HOVER)
        else
            Colors.setColor(Colors.CARD_DEFAULT)
        end
        love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
        
        -- Card border
        Colors.setColor(Colors.BORDER_DEFAULT)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
        love.graphics.setLineWidth(1)
        
        -- Hero name
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
        Colors.setColor(Colors.TEXT_PRIMARY)
        local nameX = cardX + UIConstants.CARD_PADDING
        local nameY = cardY + UIConstants.CARD_PADDING
        love.graphics.print(hero.name, nameX, nameY)
        
        -- Hero sprite
        local spriteX = nameX + UIConstants.CARD_PADDING + UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local spriteY = nameY + UIConstants.CARD_ELEMENTS_OFFSET_Y 
        
        Colors.setColor(Colors.TEXT_PRIMARY)
        
        -- Load hero sprites from folder if needed
        if hero.assetFolder and not hero.loadedSprites then
            hero.loadedSprites = assets.loadHeroSprites("assets/heroes/" .. hero.assetFolder)
        end
        
        if hero.loadedSprites and hero.loadedSprites.idle then
            local sprite = hero.loadedSprites.idle
            local spriteW, spriteH = sprite:getDimensions()
            -- Scale sprite to fit configured size in card
            local targetSize = hero.spriteSize or UIConstants.CARD_MAIN_SPRITE_SIZE
            local scale = targetSize / math.max(spriteW, spriteH)
            love.graphics.draw(sprite, spriteX, spriteY, 0, scale, scale, spriteW/2, spriteH/2)
        else
            -- Fallback: draw placeholder with configured size
            local targetSize = hero.spriteSize or UIConstants.CARD_MAIN_SPRITE_SIZE
            Colors.setColor(Colors.TEXT_DIM)
            love.graphics.rectangle("fill", spriteX - targetSize/2, spriteY - targetSize/2, targetSize, targetSize)
        end
        
        -- Key stats with growth (moved to right side) with icons
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
        Colors.setColor(Colors.TEXT_SECONDARY)

        local statsX = spriteX + UIConstants.CARD_ELEMENTS_OFFSET_X
        local statsY = spriteY - UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local statsOffset = UIConstants.ICON_STAT_SIZE + 10

        -- HP with heart icon
        local hpIcon = Icons.getHP()
        Icons.drawWithText(hpIcon, hero.baseHp .. " (+" .. hero.hpGrowth .. ")", statsX, statsY, UIConstants.ICON_STAT_SIZE)
        
        -- Armor with shield icon
        local armorY = statsY + statsOffset
        local armorIcon = Icons.getArmor()
        Icons.drawWithText(armorIcon, hero.baseArmor .. " (+" .. hero.armorGrowth .. ")", statsX, armorY, UIConstants.ICON_STAT_SIZE)
        
        -- Speed with shoe icon
        local speedY = armorY + statsOffset
        local speedIcon = Icons.getSpeed()
        Icons.drawWithText(speedIcon, hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. ")", statsX, speedY, UIConstants.ICON_STAT_SIZE)
        
        -- Cast Speed with hourglass icon
        local castSpeedY = speedY + statsOffset
        local castIcon = Icons.getCastSpeed()
        Icons.drawWithText(castIcon, hero.baseCastSpeed .. "x (+" .. hero.castSpeedGrowth .. ")", statsX, castSpeedY, UIConstants.ICON_STAT_SIZE)
        
        -- Passive ability description with icon (description section)
        if hero.innateSkill and hero.innateSkill.description then
            local innateY = castSpeedY + UIConstants.CARD_ELEMENTS_OFFSET_Y - 60
            local innateX = cardX + UIConstants.CARD_PADDING
            
            Colors.setColor(Colors.ZONE_PASSIVE)
            love.graphics.rectangle("fill", innateX, innateY, cardWidth - UIConstants.CARD_PADDING * 2, UIConstants.CARD_DESCRIPTION_HEIGHT, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
            
            -- Draw innate skill icon (properly centered in panel)
            local iconX = innateX + UIConstants.CARD_PADDING + UIConstants.CARD_INNATE_SPRITE_SIZE / 2
            local iconY = innateY + UIConstants.CARD_PADDING + UIConstants.CARD_INNATE_SPRITE_SIZE / 2
            local iconSize = UIConstants.CARD_INNATE_SPRITE_SIZE
            local innateIcon = assets.getImage("innate_" .. hero.innateSkill.id)
            if innateIcon then
                love.graphics.setColor(1, 1, 1, 1)  -- White for sprites
                local iconW, iconH = innateIcon:getDimensions()
                local scale = iconSize / math.max(iconW, iconH)
                love.graphics.draw(innateIcon, iconX, iconY, 0, scale, scale, iconW/2, iconH/2)
            else
                -- Fallback: draw placeholder
                Colors.setColor(Colors.TEXT_DIM)
                love.graphics.rectangle("fill", iconX - iconSize/2, iconY - iconSize/2, iconSize, iconSize)
            end
            
            love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
            Colors.setColor(Colors.TEXT_ACCENT)
            local descriptionX = iconX + UIConstants.CARD_PADDING + iconSize / 2
            local descriptionY = iconY - 10
            love.graphics.printf(hero.innateSkill.description, descriptionX, descriptionY, cardWidth - UIConstants.CARD_ELEMENTS_OFFSET_X - UIConstants.CARD_PADDING, "left")
        end
        
    end
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_DIM)
    -- love.graphics.printf("Click on a hero to select, then press SPACE/ENTER to continue", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function CharacterSelect:handleClick(x, y, heroes)
    local screenW = love.graphics.getWidth()
    local cardWidth = UIConstants.CARD_WIDTH
    local cardHeight = UIConstants.CARD_HEIGHT
    local cardSpacing = UIConstants.CARD_SPACING
    local cardsPerRow = UIConstants.CARDS_PER_ROW
    local startY = UIConstants.CARDS_START_Y
    
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

