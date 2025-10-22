-- ui/hud.lua
-- In-game HUD (HP, XP, skills, timer)
-- Public API: HUD.new(), hud:draw(player, gameTime)
-- Dependencies: constants.lua, assets.lua, utils.lua, colors.lua

local Constants = require("src.constants")
local Utils = require("src.utils")
local Colors = require("src.ui.colors")
local Icons = require("src.ui.icons")
local UIConstants = require("src.ui.constants")

local HUD = {}
HUD.__index = HUD

-- === CONSTRUCTOR ===

function HUD.new()
    local self = setmetatable({}, HUD)
    
    return self
end

-- === DRAW ===

function HUD:draw(player, gameTime, assets)
    if not player then return end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    
    -- Draw player card (bottom left)
    self:drawPlayerCard(player, assets)
    
    -- Draw skills
    self:drawSkills(player, assets)
    
    -- Draw timer (top center)
    self:drawTimer(gameTime, assets)
end

function HUD:drawPlayerCard(player, assets)
    local stats = player:getStats()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Card dimensions and position (bottom left)
    local cardWidth = UIConstants.CARD_WIDTH / 2  -- Half size of character select cards
    local cardHeight = UIConstants.CARD_HEIGHT / 2
    local cardX = UIConstants.HUD_PADDING
    local cardY = screenH - UIConstants.HUD_HEIGHT - cardHeight - UIConstants.HUD_PADDING
    
    -- Card background
    Colors.setColor(Colors.CARD_DEFAULT)
    love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
    
    -- Card border
    Colors.setColor(Colors.BORDER_DEFAULT)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, UIConstants.CARD_BORDER_RADIUS, UIConstants.CARD_BORDER_RADIUS)
    love.graphics.setLineWidth(1)
    
    -- Level (top of card)
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_MEDIUM))
    Colors.setColor(Colors.TEXT_ACCENT)
    local levelX = cardX + UIConstants.CARD_PADDING
    local levelY = cardY + UIConstants.CARD_PADDING
    love.graphics.print("Level: " .. stats.level, levelX, levelY)
    
    -- HP bar
    local hpY = levelY + UIConstants.FONT_MEDIUM + UIConstants.HUD_ELEMENTS_OFFSET_Y
    self:drawHPBar(stats, levelX, hpY, cardWidth)
    
    -- XP bar
    local xpY = hpY + UIConstants.FONT_MEDIUM
    self:drawXPBar(stats, levelX, xpY, cardWidth)
end

function HUD:drawHPBar(stats, x, y, cardWidth)
    local barX = x
    local barY = y
    local barWidth = cardWidth - UIConstants.CARD_PADDING * 2
    local barHeight = UIConstants.HUD_ELEMENTS_OFFSET_Y
    
    -- HP bar background
    Colors.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- HP bar fill
    local hpPercent = stats.hp / stats.maxHp
    Colors.setColor(Colors.BAR_HP)
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    -- HP text centered in bar
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_PRIMARY)
    local hpText = math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp)
    love.graphics.printf(hpText, barX, barY + barHeight/2 - UIConstants.FONT_SMALL/2, barWidth, "center")
end

function HUD:drawXPBar(stats, x, y, cardWidth)
    local barX = x
    local barY = y
    local barWidth = cardWidth - UIConstants.CARD_PADDING * 2
    local barHeight = UIConstants.HUD_ELEMENTS_OFFSET_Y
    
    -- XP bar background
    Colors.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- XP bar fill
    local xpPercent = stats.xp / stats.xpToNext
    Colors.setColor(Colors.BAR_XP)
    love.graphics.rectangle("fill", barX, barY, barWidth * xpPercent, barHeight)
    
    -- XP text centered in bar
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_PRIMARY)
    local xpText = math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext)
    love.graphics.printf(xpText, barX, barY + barHeight/2 - UIConstants.FONT_SMALL/2, barWidth, "center")
end

function HUD:drawSkills(player, assets)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Skills display (center-bottom, Dota-style)
    local skillSize = UIConstants.SKILL_ICON_SIZE  -- Square skill slots
    local skillSpacing = UIConstants.SKILL_SPACING
    local totalWidth = (skillSize + skillSpacing) * Constants.MAX_ACTIVE_SKILLS - skillSpacing
    local startX = screenW / 2 - totalWidth / 2
    local startY = screenH - UIConstants.HUD_HEIGHT / 2 - skillSize / 2
    
    for i = 1, Constants.MAX_ACTIVE_SKILLS do
        local x = startX + (i - 1) * (skillSize + skillSpacing)
        local y = startY
        
        local skill = player.skills[i]
        
        -- Draw skill slot background (always visible)
        Colors.setColor(Colors.HUD_CARD_BG)
        love.graphics.rectangle("fill", x, y, skillSize, skillSize)
        
        -- Draw skill slot border
        Colors.setColor(Colors.HUD_CARD_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, skillSize, skillSize)
        love.graphics.setLineWidth(1)
        
        if skill then
            -- Draw skill icon
            local icon = nil
            if skill.assetFolder and skill.loadedSprites and skill.loadedSprites.icon then
                icon = skill.loadedSprites.icon
            else
                icon = assets.getImage("skillDefault")
            end
            
            if icon then
                love.graphics.setColor(1, 1, 1, 1)  -- White for sprites
                local iconW, iconH = icon:getDimensions()
                local scale = skillSize / math.max(iconW, iconH)
                local centerX = skillSize / 2
                local centerY = skillSize / 2
                love.graphics.draw(icon, x + centerX, y + centerY, 0, scale, scale, iconW/2, iconH/2)
            end
            
            -- Cooldown overlay and circular progress
            if skill.cooldownTimer and skill.cooldownTimer > 0 then
                local cooldownPercent = skill.cooldownTimer / skill.cooldown
                
                -- Dark overlay
                Colors.setColor(Colors.OVERLAY_COOLDOWN)
                love.graphics.rectangle("fill", x, y, skillSize, skillSize)
                
                -- -- Circular cooldown indicator
                -- local centerX = x + skillSize / 2
                -- local centerY = y + skillSize / 2
                -- local radius = skillSize / 2 - UIConstants.SKILL_COOLDOWN_RADIUS_OFFSET
                
                -- -- Draw cooldown circle (only darkening, no progress arc)
                -- love.graphics.setColor(0.2, 0.2, 0.2, 0.8)  -- Dark circle
                -- love.graphics.circle("fill", centerX, centerY, radius)
                
                -- Cooldown text
                love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
                love.graphics.setColor(1, 1, 1, 1)  -- White text, no background
                local timeText = string.format("%.1f", skill.cooldownTimer)
                love.graphics.printf(timeText, x, y + skillSize/2 - 8, skillSize, "center")
            end
            
            -- Skill level indicator (small number in corner)
            if skill.level and skill.level > 1 then
                love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
                Colors.setColor(Colors.TEXT_ACCENT)
                love.graphics.print(skill.level, x + skillSize - 8, y + 2)
            end
        else
            -- Empty slot - draw black square
            Colors.setColor(Colors.OVERLAY_EMPTY)
            love.graphics.rectangle("fill", x + 4, y + 4, skillSize - 8, skillSize - 8)
        end
    end
end

function HUD:drawTimer(gameTime, assets)
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(Colors.TEXT_PRIMARY)
    
    local timeStr = Utils.formatTime(gameTime)
    love.graphics.printf(timeStr, 0, UIConstants.START_Y, love.graphics.getWidth(), "center")
end

return HUD

