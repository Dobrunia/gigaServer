-- ui/hud.lua
-- In-game HUD (HP, XP, skills, timer)
-- Public API: HUD.new(), hud:draw(player, gameTime)
-- Dependencies: constants.lua, assets.lua, utils.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

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
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, screenH - Constants.HUD_HEIGHT, screenW, Constants.HUD_HEIGHT)
    
    -- Draw stats
    self:drawStats(player, assets)
    
    -- Draw skills
    self:drawSkills(player, assets)
    
    -- Draw timer (top center)
    self:drawTimer(gameTime, assets)
end

function HUD:drawStats(player, assets)
    local stats = player:getStats()
    
    love.graphics.setFont(assets.getFont("small"))
    love.graphics.setColor(1, 1, 1, 1)
    
    local x = Constants.HUD_PADDING
    local y = love.graphics.getHeight() - Constants.HUD_HEIGHT + Constants.HUD_PADDING
    local lineHeight = 18
    
    -- Level
    love.graphics.print("Level: " .. stats.level, x, y)
    y = y + lineHeight
    
    -- HP bar
    love.graphics.print("HP:", x, y)
    local barX = x + 40
    local barY = y
    local barWidth = 150
    local barHeight = 14
    
    -- HP bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- HP bar fill
    local hpPercent = stats.hp / stats.maxHp
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    -- HP text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp), barX + barWidth + 10, barY)
    
    y = y + lineHeight
    
    -- XP bar
    love.graphics.print("XP:", x, y)
    barY = y
    
    -- XP bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- XP bar fill
    local xpPercent = stats.xp / stats.xpToNext
    love.graphics.setColor(0.3, 0.5, 1, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * xpPercent, barHeight)
    
    -- XP text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext), barX + barWidth + 10, barY)
    
    y = y + lineHeight
    
    -- Other stats
    love.graphics.print("Armor: " .. Utils.round(stats.armor, 1), x, y)
    y = y + lineHeight
    love.graphics.print("Speed: " .. Utils.round(stats.speed, 0), x, y)
    y = y + lineHeight
    love.graphics.print("Cast Speed: " .. Utils.round(stats.castSpeed, 2) .. "x", x, y)
end

function HUD:drawSkills(player, assets)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    love.graphics.setFont(assets.getFont("small"))
    
    -- Skills display (center-bottom)
    local skillIconSize = Constants.SKILL_ICON_SIZE
    local skillSpacing = 10
    local totalWidth = (skillIconSize + skillSpacing) * Constants.MAX_ACTIVE_SKILLS
    local startX = screenW / 2 - totalWidth / 2
    local startY = screenH - Constants.HUD_HEIGHT / 2 - skillIconSize / 2
    
    for i = 1, Constants.MAX_ACTIVE_SKILLS do
        local x = startX + (i - 1) * (skillIconSize + skillSpacing)
        local y = startY
        
        local skill = player.skills[i]
        
        if skill then
            -- Draw skill icon
            local icon = assets.getImage("skillDefault")
            if icon then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(icon, x, y, 0, skillIconSize / icon:getWidth(), skillIconSize / icon:getHeight())
            end
            
            -- Cooldown overlay
            if skill.cooldownTimer and skill.cooldownTimer > 0 then
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("fill", x, y, skillIconSize, skillIconSize)
                
                -- Cooldown text
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(string.format("%.1f", skill.cooldownTimer), x, y + skillIconSize / 2 - 8, skillIconSize, "center")
            end
            
            -- Skill name
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(assets.getFont("debug"))
            love.graphics.printf(skill.name:sub(1, 8), x, y + skillIconSize + 2, skillIconSize, "center")
        else
            -- Empty slot
            local emptyIcon = assets.getImage("skillEmpty")
            if emptyIcon then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                love.graphics.draw(emptyIcon, x, y, 0, skillIconSize / emptyIcon:getWidth(), skillIconSize / emptyIcon:getHeight())
            end
        end
    end
end

function HUD:drawTimer(gameTime, assets)
    love.graphics.setFont(assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    
    local timeStr = Utils.formatTime(gameTime)
    love.graphics.printf(timeStr, 0, 20, love.graphics.getWidth(), "center")
end

return HUD

