-- ui/skill_select.lua
-- Starting skill selection UI
-- Public API: SkillSelect.new(), skillSelect:draw(assets, skills, selectedIndex), skillSelect:handleClick(x, y, skills)

local Colors = require("src.ui.colors")
local Icons = require("src.ui.icons")
local UIConstants = require("src.ui.constants")

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
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("Choose Your Starting Skill", 0, UIConstants.START_Y, love.graphics.getWidth(), "center")
    
    -- Skill cards grid
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
        love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
        
        -- Card border
        Colors.setColor(Colors.BORDER_DEFAULT)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
        love.graphics.setLineWidth(1)
        
        -- Skill name
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
        Colors.setColor(Colors.TEXT_PRIMARY)
        local nameX = cardX + UIConstants.CARD_PADDING
        local nameY = cardY + UIConstants.CARD_PADDING
        love.graphics.print(skill.name, nameX, nameY)
        
        -- Skill sprite (moved to left side)
        local spriteX = nameX + UIConstants.CARD_PADDING + UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local spriteY = nameY + UIConstants.CARD_ELEMENTS_OFFSET_Y
        
        Colors.setColor(Colors.TEXT_PRIMARY)
        
        -- Load icon sprite from asset folder if needed
        if skill.assetFolder and not skill.loadedSprites then
            skill.loadedSprites = assets.loadFolderSprites("assets/" .. skill.assetFolder)
        end
        
        if skill.loadedSprites and skill.loadedSprites.icon then
            local icon = skill.loadedSprites.icon
            local iconW, iconH = icon:getDimensions()
            -- Scale icon to fit nicely in card
            local scale = UIConstants.CARD_MAIN_SPRITE_SIZE / math.max(iconW, iconH)
            love.graphics.draw(icon, spriteX, spriteY, 0, scale, scale, iconW / 2, iconH / 2)
        end
        
        -- Skill stats (moved to right side) with icons
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
        Colors.setColor(Colors.TEXT_SECONDARY)
        
        local statsX = spriteX + UIConstants.CARD_ELEMENTS_OFFSET_X
        local statsY = spriteY - UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local statsOffset = UIConstants.ICON_STAT_SIZE + 10
        
        -- Type with melee icon (if applicable)
        if skill.type == "melee" then
            local meleeIcon = Icons.getSkillMelee()
            Icons.drawWithText(meleeIcon, skill.type, statsX, statsY, UIConstants.ICON_STAT_SIZE)
        else
            love.graphics.print("Type: " .. skill.type, statsX, statsY)
        end
        
        -- Damage (no specific icon yet, keep as text)
        local damageY = statsY + statsOffset
        love.graphics.print("Damage: " .. skill.damage, statsX, damageY)
        
        -- Cooldown (no specific icon yet, keep as text)
        local cooldownY = damageY + statsOffset
        love.graphics.print("Cooldown: " .. skill.cooldown .. "s", statsX, cooldownY)
        
        -- Range (no specific icon yet, keep as text)
        local rangeY = cooldownY + statsOffset
        love.graphics.print("Range: " .. skill.range, statsX, rangeY)
        
        -- Description background
        local descY = rangeY + UIConstants.CARD_ELEMENTS_OFFSET_Y - 60
        local descX = cardX + UIConstants.CARD_PADDING
        local descHeight = UIConstants.CARD_DESCRIPTION_HEIGHT
        
        Colors.setColor(Colors.ZONE_PASSIVE)
        love.graphics.rectangle("fill", descX, descY, cardWidth - UIConstants.CARD_PADDING * 2, descHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
        
        -- Effect display (if skill has effect)
        if skill.effect then
            local effectX = descX + UIConstants.CARD_PADDING
            local effectY = descY + UIConstants.CARD_PADDING
            love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
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
            
            love.graphics.printf(effectText, effectX, effectY, cardWidth - UIConstants.CARD_ELEMENTS_OFFSET_X - UIConstants.CARD_PADDING, "left")
        end
        
    end
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_DIM)
    -- love.graphics.printf("Click on a skill to select, then press SPACE/ENTER to start", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function SkillSelect:handleClick(x, y, skills)
    local screenW = love.graphics.getWidth()
    local cardWidth = UIConstants.CARD_WIDTH
    local cardHeight = UIConstants.CARD_HEIGHT
    local cardSpacing = UIConstants.CARD_SPACING
    local cardsPerRow = UIConstants.CARDS_PER_ROW
    local startY = UIConstants.CARDS_START_Y
    
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

