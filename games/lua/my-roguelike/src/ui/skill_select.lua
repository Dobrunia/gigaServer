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
    
    local bg = assets.getImage("menuBg")
    if bg then
        Colors.setColor(Colors.TEXT_PRIMARY)
        local scaleX = love.graphics.getWidth() / bg:getWidth()
        local scaleY = love.graphics.getHeight() / bg:getHeight()
        love.graphics.draw(bg, 0, 0, 0, scaleX, scaleY)
    end
    
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
    local startY = 100
    
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
        -- Card background
        if isHovered then
            Colors.setColor(Colors.CARD_HOVER)
        else
            Colors.setColor(Colors.CARD_DEFAULT)
        end
        love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 8, 8)
        
        -- Card border
        Colors.setColor(Colors.BORDER_DEFAULT)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, 8, 8)
        love.graphics.setLineWidth(1)
        
        -- Skill name
        love.graphics.setFont(assets.getFont("large"))
        Colors.setColor(Colors.TEXT_PRIMARY)
        love.graphics.print(skill.name, cardX + 20, cardY + 20)
        
        -- Skill sprite (moved to left side)
        local spriteX = cardX + 80
        local spriteY = cardY + 110
        
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
        
        -- Skill stats (moved to right side)
        love.graphics.setFont(assets.getFont("default"))
        Colors.setColor(Colors.TEXT_SECONDARY)
        local yOffset = 70
        love.graphics.print("Type: " .. skill.type, cardX + 200, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Damage: " .. skill.damage, cardX + 200, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Cooldown: " .. skill.cooldown .. "s", cardX + 200, cardY + yOffset)
        yOffset = yOffset + 30
        love.graphics.print("Range: " .. skill.range, cardX + 200, cardY + yOffset)
        
        -- Description background
        local descY = cardY + 190
        local descHeight = 70
        
        Colors.setColor(Colors.ZONE_PASSIVE)
        love.graphics.rectangle("fill", cardX + 20, descY, cardWidth - 40, descHeight, 8, 8)
        
        -- Description text
        -- love.graphics.setFont(assets.getFont("default"))
        -- Colors.setColor(Colors.TEXT_ACCENT)
        -- love.graphics.printf(skill.description, cardX + 30, descY + 15, cardWidth - 60, "left")
        
        -- Effect display (if skill has effect)
        if skill.effect then
            local effectY = descY + 15
            love.graphics.setFont(assets.getFont("small"))
            Colors.setColor(Colors.TEXT_ACCENT)
            
            local effectText = ""
            if skill.effect.type == "burning" then
                effectText = "Effect: " .. skill.effect.damage .. " damage/sec for " .. skill.effect.duration .. "s"
            elseif skill.effect.type == "poison" then
                effectText = "Effect: " .. skill.effect.damage .. " poison/sec for " .. skill.effect.duration .. "s"
            elseif skill.effect.type == "slow" then
                effectText = "Effect: " .. (skill.effect.slowPercent or 50) .. "% slow for " .. skill.effect.duration .. "s"
            elseif skill.effect.type == "root" then
                effectText = "Effect: Root for " .. skill.effect.duration .. "s"
            elseif skill.effect.type == "stun" then
                effectText = "Effect: Stun for " .. skill.effect.duration .. "s"
            else
                effectText = "Effect: " .. skill.effect.type .. " for " .. skill.effect.duration .. "s"
            end
            
            love.graphics.printf(effectText, cardX + 30, effectY, cardWidth - 60, "left")
        end
        
    end
    
    -- Instructions
    love.graphics.setFont(assets.getFont("default"))
    Colors.setColor(Colors.TEXT_DIM)
    -- love.graphics.printf("Click on a skill to select, then press SPACE/ENTER to start", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function SkillSelect:handleClick(x, y, skills)
    local screenW = love.graphics.getWidth()
    local cardWidth = 500
    local cardHeight = 280
    local cardSpacing = 40
    local cardsPerRow = 2
    local startY = 100
    
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

