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
    
    -- HUD background
    Colors.setColor(Colors.HUD_BACKGROUND)
    love.graphics.rectangle("fill", 0, screenH - UIConstants.HUD_HEIGHT, screenW, UIConstants.HUD_HEIGHT)
    
    -- Draw stats
    self:drawStats(player, assets)
    
    -- Draw skills
    self:drawSkills(player, assets)
    
    -- Draw timer (top center)
    self:drawTimer(gameTime, assets)
end

function HUD:drawStats(player, assets)
    local stats = player:getStats()
    
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
    Colors.setColor(Colors.TEXT_PRIMARY)
    
    local x = UIConstants.HUD_PADDING
    local y = love.graphics.getHeight() - UIConstants.HUD_HEIGHT + UIConstants.HUD_PADDING
    local lineHeight = UIConstants.HUD_ELEMENTS_OFFSET_Y
    
    -- Level (accent color)
    Colors.setColor(Colors.TEXT_ACCENT)
    love.graphics.print("Level: " .. stats.level, x, y)
    Colors.setColor(Colors.TEXT_PRIMARY)
    y = y + lineHeight
    
    -- HP bar with heart icon
    local hpIcon = Icons.getHP()
    Icons.drawWithText(hpIcon, nil, x, y, UIConstants.ICON_STAT_SIZE)
    local barX = x + UIConstants.CARD_ELEMENTS_OFFSET_X
    local barY = y
    local barWidth = UIConstants.CARD_DESCRIPTION_WIDTH
    local barHeight = UIConstants.HUD_ELEMENTS_OFFSET_Y
    
    -- HP bar background
    Colors.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- HP bar fill
    local hpPercent = stats.hp / stats.maxHp
    Colors.setColor(Colors.BAR_HP)
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    -- HP text with growth (current/max + growth)
    love.graphics.print(math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp), barX + barWidth + UIConstants.CARD_ELEMENTS_OFFSET_X, barY)
    Colors.setColor(Colors.TEXT_ACCENT)
    love.graphics.print(" + " .. Utils.round(stats.hpGrowth, 0), barX + barWidth + UIConstants.CARD_ELEMENTS_OFFSET_X + UIConstants.CARD_ELEMENTS_OFFSET_X, barY)
    Colors.setColor(Colors.TEXT_PRIMARY)
    
    y = y + lineHeight
    
    -- XP bar (no icon for XP yet)
    love.graphics.print("XP:", x, y)
    barY = y
    
    -- XP bar background
    Colors.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- XP bar fill
    local xpPercent = stats.xp / stats.xpToNext
    Colors.setColor(Colors.BAR_XP)
    love.graphics.rectangle("fill", barX, barY, barWidth * xpPercent, barHeight)
    
    -- XP text
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.print(math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext), barX + barWidth + UIConstants.CARD_ELEMENTS_OFFSET_X, barY)
    
    y = y + lineHeight
    
    -- Other stats (current + next level bonus) with icons
    -- Armor: current + growth (growth in accent color)
    local armorIcon = Icons.getArmor()
    Icons.drawWithText(armorIcon, nil, x, y, UIConstants.ICON_STAT_SIZE)
    Colors.setColor(Colors.TEXT_ACCENT)
    love.graphics.print(Utils.round(stats.armor, 1) .. " + " .. Utils.round(stats.armorGrowth, 1), x + UIConstants.CARD_ELEMENTS_OFFSET_X, y)
    Colors.setColor(Colors.TEXT_PRIMARY)
    y = y + lineHeight

    -- Speed: current + growth (growth in accent color)
    local speedIcon = Icons.getSpeed()
    Icons.drawWithText(speedIcon, nil, x, y, UIConstants.ICON_STAT_SIZE)
    Colors.setColor(Colors.TEXT_ACCENT)
    love.graphics.print(Utils.round(stats.speed, 0) .. " + " .. Utils.round(stats.speedGrowth, 0), x + UIConstants.CARD_ELEMENTS_OFFSET_X, y)
    Colors.setColor(Colors.TEXT_PRIMARY)
    y = y + lineHeight

    -- Cast Speed: current + growth (growth in accent color)
    local castIcon = Icons.getCastSpeed()
    Icons.drawWithText(castIcon, nil, x, y, UIConstants.ICON_STAT_SIZE)
    Colors.setColor(Colors.TEXT_ACCENT)
    love.graphics.print(Utils.round(stats.castSpeed, 2) .. "x + " .. Utils.round(stats.castSpeedGrowth, 2) .. "x", x + UIConstants.CARD_ELEMENTS_OFFSET_X, y)
    Colors.setColor(Colors.TEXT_PRIMARY)
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
                
                -- Circular cooldown indicator
                local centerX = x + skillSize / 2
                local centerY = y + skillSize / 2
                local radius = skillSize / 2 - UIConstants.SKILL_COOLDOWN_RADIUS_OFFSET
                
                -- Draw cooldown circle
                love.graphics.setColor(0.2, 0.2, 0.2, 0.8)  -- Dark circle
                love.graphics.circle("fill", centerX, centerY, radius)
                
                -- Draw progress arc
                love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- Light gray progress
                love.graphics.setLineWidth(UIConstants.CARD_ELEMENTS_OFFSET_X)
                local startAngle = -math.pi / 2  -- Start from top
                local endAngle = startAngle + (1 - cooldownPercent) * 2 * math.pi
                love.graphics.arc("line", centerX, centerY, radius - UIConstants.SKILL_COOLDOWN_RADIUS_OFFSET, startAngle, endAngle)
                love.graphics.setLineWidth(1)
                
                -- Cooldown text
                love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
                Colors.setColor(Colors.TEXT_PRIMARY)
                local timeText = string.format("%.1f", skill.cooldownTimer)
                love.graphics.printf(timeText, x, y + skillSize/2 - UIConstants.CARD_ELEMENTS_OFFSET_Y, skillSize, "center")
            end
            
            -- Skill level indicator (small number in corner)
            if skill.level and skill.level > 1 then
                love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
                Colors.setColor(Colors.TEXT_ACCENT)
                love.graphics.print(skill.level, x + skillSize - UIConstants.CARD_ELEMENTS_OFFSET_X, y + UIConstants.CARD_ELEMENTS_OFFSET_Y)
            end
        else
            -- Empty slot - draw black square
            Colors.setColor(Colors.OVERLAY_EMPTY)
            love.graphics.rectangle("fill", x + UIConstants.CARD_ELEMENTS_OFFSET_X, y + UIConstants.CARD_ELEMENTS_OFFSET_Y, skillSize - UIConstants.CARD_ELEMENTS_OFFSET_X * 2, skillSize - UIConstants.CARD_ELEMENTS_OFFSET_Y * 2)
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

