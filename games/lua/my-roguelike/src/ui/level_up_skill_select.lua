-- ui/level_up_skill_select.lua
-- Level up skill selection UI
-- Shows 3 skill choices: new skills or upgrades to existing skills
-- Public API: LevelUpSkillSelect.new(), skillSelect:draw(assets, choices, selectedIndex), skillSelect:handleClick(x, y, choices)

local Colors = require("src.ui.colors")
local Icons = require("src.ui.icons")
local UIConstants = require("src.ui.constants")

local LevelUpSkillSelect = {}
LevelUpSkillSelect.__index = LevelUpSkillSelect

-- === CONSTRUCTOR ===

function LevelUpSkillSelect.new()
    local self = setmetatable({}, LevelUpSkillSelect)
    return self
end

-- === DRAW ===

function LevelUpSkillSelect:draw(assets, choices, selectedIndex)
    -- Dark overlay
    Colors.setColor(Colors.OVERLAY_PAUSE)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Title
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("LEVEL UP! Choose a Skill", 0, 100, screenW, "center")
    
    -- Subtitle
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_SECONDARY)
    love.graphics.printf("Select one of the following options:", 0, 140, screenW, "center")
    
    -- Skill choices (3 cards in a row)
    local cardWidth = UIConstants.CARD_WIDTH
    local cardHeight = UIConstants.CARD_HEIGHT
    local cardSpacing = UIConstants.CARD_SPACING
    local cardsPerRow = 3
    local startY = UIConstants.CARDS_START_Y
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, choice in ipairs(choices) do
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
        
        -- Choice type indicator
        local typeY = cardY + UIConstants.CARD_PADDING
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
        if choice.isUpgrade then
            Colors.setColor(Colors.ACCENT)  -- Gold for upgrades
            love.graphics.printf("UPGRADE", cardX + UIConstants.CARD_PADDING, typeY, cardWidth - UIConstants.CARD_PADDING * 2, "left")
        else
            Colors.setColor(Colors.PRIMARY)  -- Blue for new skills
            love.graphics.printf("NEW SKILL", cardX + UIConstants.CARD_PADDING, typeY, cardWidth - UIConstants.CARD_PADDING * 2, "left")
        end
        
        -- Skill name
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
        Colors.setColor(Colors.TEXT_PRIMARY)
        local nameY = typeY + 25
        love.graphics.printf(choice.skill.name, cardX + UIConstants.CARD_PADDING, nameY, cardWidth - UIConstants.CARD_PADDING * 2, "left")
        
        -- Skill level (for upgrades)
        if choice.isUpgrade then
            love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
            Colors.setColor(Colors.TEXT_SECONDARY)
            love.graphics.printf("Level " .. (choice.skill.level + 1), cardX + UIConstants.CARD_PADDING, nameY + 25, cardWidth - UIConstants.CARD_PADDING * 2, "left")
        end
        
        -- Skill sprite
        local spriteX = cardX + UIConstants.CARD_PADDING + UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local spriteY = nameY + UIConstants.CARD_ELEMENTS_OFFSET_Y
        
        Colors.setColor(Colors.TEXT_PRIMARY)
        
        -- Load icon sprite from asset folder if needed
        if choice.skill.assetFolder and not choice.skill.loadedSprites then
            choice.skill.loadedSprites = assets.loadFolderSprites("assets/" .. choice.skill.assetFolder)
        end
        
        if choice.skill.loadedSprites and choice.skill.loadedSprites.icon then
            local icon = choice.skill.loadedSprites.icon
            local iconW, iconH = icon:getDimensions()
            local scale = UIConstants.CARD_MAIN_SPRITE_SIZE / math.max(iconW, iconH)
            love.graphics.draw(icon, spriteX, spriteY, 0, scale, scale, iconW / 2, iconH / 2)
        end
        
        -- Skill stats
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
        Colors.setColor(Colors.TEXT_SECONDARY)
        
        local statsX = spriteX + UIConstants.CARD_ELEMENTS_OFFSET_X
        local statsY = spriteY - UIConstants.CARD_MAIN_SPRITE_SIZE / 2
        local statsOffset = UIConstants.ICON_STAT_SIZE + 10
        
        -- Show current vs new stats for upgrades
        if choice.isUpgrade then
            -- Show upgrade comparison
            local upgradeData = choice.skill.upgrades[choice.skill.level]
            if upgradeData then
                if upgradeData.damage then
                    love.graphics.print("Damage: " .. choice.skill.damage .. " → " .. upgradeData.damage, statsX, statsY)
                    statsY = statsY + statsOffset
                end
                if upgradeData.cooldown then
                    love.graphics.print("Cooldown: " .. choice.skill.cooldown .. "s → " .. upgradeData.cooldown .. "s", statsX, statsY)
                    statsY = statsY + statsOffset
                end
                if upgradeData.range then
                    love.graphics.print("Range: " .. choice.skill.range .. " → " .. upgradeData.range, statsX, statsY)
                    statsY = statsY + statsOffset
                end
                if upgradeData.radius then
                    love.graphics.print("Radius: " .. choice.skill.radius .. " → " .. upgradeData.radius, statsX, statsY)
                    statsY = statsY + statsOffset
                end
            end
        else
            -- Show new skill stats
            if choice.skill.damage then
                love.graphics.print("Damage: " .. choice.skill.damage, statsX, statsY)
                statsY = statsY + statsOffset
            end
            if choice.skill.cooldown then
                love.graphics.print("Cooldown: " .. choice.skill.cooldown .. "s", statsX, statsY)
                statsY = statsY + statsOffset
            end
            if choice.skill.range then
                love.graphics.print("Range: " .. choice.skill.range, statsX, statsY)
                statsY = statsY + statsOffset
            end
            if choice.skill.radius then
                love.graphics.print("Radius: " .. choice.skill.radius, statsX, statsY)
                statsY = statsY + statsOffset
            end
        end
        
        -- Description
        if choice.skill.description then
            local descY = cardY + cardHeight - 40
            love.graphics.printf(choice.skill.description, cardX + UIConstants.CARD_PADDING, descY, cardWidth - UIConstants.CARD_PADDING * 2, "left")
        end
    end
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_DIM)
    love.graphics.printf("Click on a skill to select it", 0, screenH - 40, screenW, "center")
end

-- === INPUT ===

function LevelUpSkillSelect:handleClick(x, y, choices)
    local screenW = love.graphics.getWidth()
    local cardWidth = UIConstants.CARD_WIDTH
    local cardHeight = UIConstants.CARD_HEIGHT
    local cardSpacing = UIConstants.CARD_SPACING
    local cardsPerRow = 3
    local startY = UIConstants.CARDS_START_Y
    
    -- Calculate grid positioning
    local totalWidth = (cardWidth * cardsPerRow) + (cardSpacing * (cardsPerRow - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, choice in ipairs(choices) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = ((i - 1) % cardsPerRow)
        
        local cardX = startX + col * (cardWidth + cardSpacing)
        local cardY = startY + row * (cardHeight + cardSpacing)
        
        -- Check if click is within this card
        if x >= cardX and x <= cardX + cardWidth and
           y >= cardY and y <= cardY + cardHeight then
            return i  -- Return choice index
        end
    end
    
    return nil
end

return LevelUpSkillSelect
