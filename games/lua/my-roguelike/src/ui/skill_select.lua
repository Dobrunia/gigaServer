-- ui/skill_select.lua
-- Starting skill selection UI
-- Public API: SkillSelect.new(), skillSelect:draw(assets, skills, selectedIndex), skillSelect:handleClick(x, y, skills)
-- Dependencies: constants.lua, colors.lua

local Constants = require("src.constants")
local Colors = require("src.ui.colors")

local SkillSelect = {}
SkillSelect.__index = SkillSelect

-- === CONSTRUCTOR ===

function SkillSelect.new()
    local self = setmetatable({}, SkillSelect)
    return self
end

-- === DRAW ===

function SkillSelect:draw(assets, skills, selectedIndex)
    Colors.setColor(Colors.BACKGROUND_PRIMARY)
    love.graphics.clear()
    
    -- Title
    love.graphics.setFont(assets.getFont("large"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("Choose Your Starting Skill", 0, 30, love.graphics.getWidth(), "center")
    
    -- Skill cards grid
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local cardWidth = 500
    local cardHeight = 280
    local cardSpacing = 40
    local cardsPerRow = 2
    local startY = 120
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, skill in ipairs(skills) do
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
        
        -- Skill name
        love.graphics.setFont(assets.getFont("large"))
        Colors.setColor(Colors.TEXT_PRIMARY)
        love.graphics.print(skill.name, cardX + 20, cardY + 20)
        
        -- Skill stats
        love.graphics.setFont(assets.getFont("default"))
        Colors.setColor(Colors.TEXT_SECONDARY)
        local yOffset = 70
        love.graphics.print("Type: " .. skill.type, cardX + 20, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Damage: " .. skill.damage, cardX + 20, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Cooldown: " .. skill.cooldown .. "s", cardX + 20, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Range: " .. skill.range, cardX + 20, cardY + yOffset)
        
        -- Skill sprite (aligned with stats horizontally) - use icon sprite from folder
        local spriteX = cardX + cardWidth - 120
        local spriteY = cardY + 70  -- Same Y as first stat line
        
        Colors.setColor(Colors.TEXT_PRIMARY)
        
        -- Load icon sprite from asset folder if needed
        if skill.assetFolder and not skill.loadedSprites then
            skill.loadedSprites = assets.loadFolderSprites("assets/" .. skill.assetFolder)
        end
        
        if skill.loadedSprites and skill.loadedSprites.icon then
            local icon = skill.loadedSprites.icon
            local iconW, iconH = icon:getDimensions()
            -- Scale icon to fit nicely in card
            local scale = 64 / math.max(iconW, iconH)
            love.graphics.draw(icon, spriteX, spriteY, 0, scale, scale, iconW / 2, iconH / 2)
        end
        
        -- Description background
        local descY = cardY + 190
        local descHeight = 70
        
        Colors.setColor(Colors.ZONE_PASSIVE)
        love.graphics.rectangle("fill", cardX + 20, descY, cardWidth - 40, descHeight, 8, 8)
        
        -- Description text
        love.graphics.setFont(assets.getFont("default"))
        Colors.setColor(Colors.TEXT_ACCENT)
        love.graphics.printf(skill.description, cardX + 30, descY + 15, cardWidth - 60, "left")
        
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
    love.graphics.printf("Click on a skill to select, then press SPACE/ENTER to start", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function SkillSelect:handleClick(x, y, skills)
    local screenW = love.graphics.getWidth()
    local cardWidth = 500
    local cardHeight = 280
    local cardSpacing = 40
    local cardsPerRow = 2
    local startY = 120
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, skill in ipairs(skills) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = ((i - 1) % cardsPerRow)
        
        local cardX = startX + col * (cardWidth + cardSpacing)
        local cardY = startY + row * (cardHeight + cardSpacing)
        
        -- Check if click is within this card
        if x >= cardX and x <= cardX + cardWidth and
           y >= cardY and y <= cardY + cardHeight then
            return i  -- Return skill index
        end
    end
    
    return nil
end

return SkillSelect

