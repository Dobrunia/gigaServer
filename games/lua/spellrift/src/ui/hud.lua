-- src/ui/hud.lua
local Constants = require("src.constants")
local MathUtils = require("src.utils.math_utils")
local SpriteManager = require("src.utils.sprite_manager")

-- HUD константы
local HUD_CONSTANTS = {
    HUD_HEIGHT = 120,
    CARD_WIDTH = 300,
    CARD_PADDING = 10,
    CARD_BORDER_RADIUS = 8,
    HUD_ELEMENTS_OFFSET_Y = 20,
    ICON_STAT_SIZE = 16,
    SKILL_ICON_SIZE = 64,
    SKILL_SPACING = 12,
    SKILL_COOLDOWN_RADIUS_OFFSET = 4,
    MAX_ACTIVE_SKILLS = 4,
    FONT_MEDIUM = 24,
    FONT_SMALL = 18,
    FONT_LARGE = 30,
    START_Y = 20
}

-- Простые цвета для HUD
local Colors = {
    CARD_DEFAULT = {0.1, 0.1, 0.1, 0.9},
    BORDER_DEFAULT = {0.3, 0.3, 0.3, 1},
    TEXT_ACCENT = {1, 1, 0, 1},
    TEXT_PRIMARY = {1, 1, 1, 1},
    BAR_BACKGROUND = {0.2, 0.2, 0.2, 1},
    BAR_HP = {0.8, 0.2, 0.2, 1},
    BAR_XP = {0.2, 0.8, 0.2, 1},
    HUD_CARD_BG = {0.15, 0.15, 0.15, 0.8},
    HUD_CARD_BORDER = {0.4, 0.4, 0.4, 1},
    OVERLAY_COOLDOWN = {0, 0, 0, 0.7},
    OVERLAY_EMPTY = {0, 0, 0, 0.5}
}

local HUD = {}
HUD.__index = HUD

-- === CONSTRUCTOR ===
function HUD.new()
    local self = setmetatable({}, HUD)
    
    -- Cache for optimization
    self.lastLevel = 0
    self.lastHP = 0
    self.lastMaxHP = 0
    self.lastXP = 0
    self.lastXPToNext = 0
    
    -- Canvas for static elements
    self.playerCardCanvas = nil
    self.levelUp = true

    -- ==== КЕШ ШРИФТОВ ====
    self.fontSmall  = love.graphics.newFont(HUD_CONSTANTS.FONT_SMALL)
    self.fontMedium = love.graphics.newFont(HUD_CONSTANTS.FONT_MEDIUM)
    self.fontLarge  = love.graphics.newFont(HUD_CONSTANTS.FONT_LARGE)
    
    return self
end

-- === DRAW ===
function HUD:draw(player, gameTime)
    if not player then return end
    
    local stats = player:getStats()
    
    -- Check for changes and update canvas if needed
    if self.lastLevel ~= stats.level then
        self.levelUp = true
        self.lastLevel = stats.level
    end
    
    if self.lastHP ~= stats.hp or self.lastMaxHP ~= stats.maxHp then
        self.levelUp = true
        self.lastHP = stats.hp
        self.lastMaxHP = stats.maxHp
    end
    
    if self.lastXP ~= stats.xp or self.lastXPToNext ~= stats.xpToNext then
        self.levelUp = true
        self.lastXP = stats.xp
        self.lastXPToNext = stats.xpToNext
    end
    
    -- Draw player card from canvas or redraw if needed
    if self.levelUp then
        self:updatePlayerCardCanvas(player)
        self.levelUp = false
    end
    
    -- Draw canvas to screen (подняли выше)
    if self.playerCardCanvas then
        local screenH = love.graphics.getHeight()
        local cardY = screenH - HUD_CONSTANTS.HUD_HEIGHT - 140  -- подняли на 140px выше
        love.graphics.draw(self.playerCardCanvas, self.cardX, cardY)
        self.cardY = cardY  -- сохраняем для отображения статов под карточкой
    end
    
    -- Draw stats under card (always redraw)
    self:drawStats(player)
    
    -- Draw skills (always redraw for cooldowns)
    self:drawSkills(player)
    
    -- Draw timer (always redraw)
    self:drawTimer(gameTime)
end

function HUD:updatePlayerCardCanvas(player)
    local stats = player:getStats()
    local screenH = love.graphics.getHeight()
    
    -- Card dimensions
    local cardWidth = HUD_CONSTANTS.CARD_WIDTH / 2
    local cardHeight = HUD_CONSTANTS.HUD_HEIGHT
    local cardX = 0
    
    -- Store positions for optimization
    self.cardX = cardX
    self.cardWidth = cardWidth
    
    -- Create or clear canvas
    if not self.playerCardCanvas then
        self.playerCardCanvas = love.graphics.newCanvas(cardWidth, cardHeight)
    end
    
    -- Draw to canvas
    love.graphics.setCanvas(self.playerCardCanvas)
    love.graphics.clear()
    
    -- Card background
    love.graphics.setColor(Colors.CARD_DEFAULT)
    love.graphics.rectangle("fill", 0, 0, cardWidth, cardHeight, HUD_CONSTANTS.CARD_BORDER_RADIUS, HUD_CONSTANTS.CARD_BORDER_RADIUS)
    
    -- Card border
    love.graphics.setColor(Colors.BORDER_DEFAULT)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 0, 0, cardWidth, cardHeight, HUD_CONSTANTS.CARD_BORDER_RADIUS, HUD_CONSTANTS.CARD_BORDER_RADIUS)
    love.graphics.setLineWidth(1)
    
    -- Level
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(Colors.TEXT_ACCENT)
    local levelX = HUD_CONSTANTS.CARD_PADDING
    local levelY = HUD_CONSTANTS.CARD_PADDING
    love.graphics.print("Level: " .. stats.level, levelX, levelY)
    
    -- HP bar
    local hpY = levelY + HUD_CONSTANTS.FONT_MEDIUM + HUD_CONSTANTS.HUD_ELEMENTS_OFFSET_Y
    self.hpY = hpY
    self:drawHPBar(stats, levelX, hpY, cardWidth)
    
    -- XP bar
    local xpY = hpY + HUD_CONSTANTS.FONT_MEDIUM
    self.xpY = xpY
    self:drawXPBar(stats, levelX, xpY, cardWidth)
    
    
    -- Reset canvas
    love.graphics.setCanvas()
end

function HUD:drawHPBar(stats, x, y, cardWidth)
    local barX = x
    local barY = y
    local barWidth = cardWidth - HUD_CONSTANTS.CARD_PADDING * 2
    local barHeight = HUD_CONSTANTS.HUD_ELEMENTS_OFFSET_Y
    
    love.graphics.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    local hpPercent = stats.hp / stats.maxHp
    love.graphics.setColor(Colors.BAR_HP)
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    local hpText = math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp)
    love.graphics.printf(hpText, barX, barY + barHeight/2 - HUD_CONSTANTS.FONT_SMALL/2, barWidth, "center")
end

function HUD:drawXPBar(stats, x, y, cardWidth)
    local barX = x
    local barY = y
    local barWidth = cardWidth - HUD_CONSTANTS.CARD_PADDING * 2
    local barHeight = HUD_CONSTANTS.HUD_ELEMENTS_OFFSET_Y
    
    love.graphics.setColor(Colors.BAR_BACKGROUND)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    local xpPercent = stats.xp / stats.xpToNext
    love.graphics.setColor(Colors.BAR_XP)
    love.graphics.rectangle("fill", barX, barY, barWidth * xpPercent, barHeight)
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    local xpText = math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext)
    love.graphics.printf(xpText, barX, barY + barHeight/2 - HUD_CONSTANTS.FONT_SMALL/2, barWidth, "center")
end

function HUD:drawSkills(player)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    local skillSize = HUD_CONSTANTS.SKILL_ICON_SIZE
    local skillSpacing = HUD_CONSTANTS.SKILL_SPACING
    local totalWidth = (skillSize + skillSpacing) * HUD_CONSTANTS.MAX_ACTIVE_SKILLS - skillSpacing
    local startX = screenW / 2 - totalWidth / 2
    local startY = screenH - HUD_CONSTANTS.HUD_HEIGHT / 2 - skillSize / 2
    
    for i = 1, HUD_CONSTANTS.MAX_ACTIVE_SKILLS do
        local x = startX + (i - 1) * (skillSize + skillSpacing)
        local y = startY
        
        local skill = player.skills[i]
        
        -- слот
        love.graphics.setColor(Colors.HUD_CARD_BG)
        love.graphics.rectangle("fill", x, y, skillSize, skillSize)
        love.graphics.setColor(Colors.HUD_CARD_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, skillSize, skillSize)
        love.graphics.setLineWidth(1)
        
        if skill then
            -- иконка
            local icon = nil
            if skill.id then
                local spriteSheet = SpriteManager.loadSkillSprite(skill.id)
                if spriteSheet then
                    local tileWidth, tileHeight = 64, 64
                    local quad = SpriteManager.getQuad(spriteSheet, 1, 1, tileWidth, tileHeight)
                    icon = {sprite = spriteSheet, quad = quad}
                end
            end
            
            if icon then
                love.graphics.setColor(1, 1, 1, 1)
                local _, _, quadW, quadH = icon.quad:getViewport()
                local scale = skillSize / math.max(quadW, quadH)
                local centerX = skillSize / 2
                local centerY = skillSize / 2
                love.graphics.draw(icon.sprite, icon.quad, x + centerX, y + centerY, 0, scale, scale, quadW/2, quadH/2)
            end
            
            -- КУЛДАУН (используем геттеры)
            local totalCd = (skill.getCooldownDuration and skill:getCooldownDuration()) or 0
            local remaining = (skill.getCooldownRemaining and skill:getCooldownRemaining()) or 0
            if remaining > 0 and totalCd > 0 then
                local cooldownPercent = remaining / totalCd
                love.graphics.setColor(Colors.OVERLAY_COOLDOWN)
                love.graphics.rectangle("fill", x, y, skillSize, skillSize)
                
                love.graphics.setFont(self.fontSmall)
                love.graphics.setColor(1, 1, 1, 1)
                local timeText = string.format("%.1f", remaining)
                love.graphics.printf(timeText, x, y + skillSize/2 - 8, skillSize, "center")
            end
            
            -- уровень скилла
            if skill.level and skill.level > 1 then
                love.graphics.setFont(self.fontSmall)
                love.graphics.setColor(Colors.TEXT_ACCENT)
                love.graphics.print(skill.level, x + skillSize - 8, y + 2)
            end
            
            -- прогресс баффа
            if skill.type == "buff" then
                self:drawBuffProgressBar(skill, player, x, y, skillSize)
            end
        else
            -- пустой слот
            love.graphics.setColor(Colors.OVERLAY_EMPTY)
            love.graphics.rectangle("fill", x + 4, y + 4, skillSize - 8, skillSize - 8)
        end
    end
end

function HUD:drawBuffProgressBar(skill, player, x, y, skillSize)
    if not player.activeBuffs then return end
    
    for _, buff in ipairs(player.activeBuffs) do
        if buff.skill and buff.skill.id == skill.id then
            local currentTime = love.timer.getTime()
            local remainingTime = (buff.startTime + buff.duration) - currentTime
            if remainingTime > 0 then
                local progress = remainingTime / buff.duration
                local barWidth = skillSize - 4
                local barHeight = 3
                local barX = x + 2
                local barY = y - 8
                love.graphics.setColor(Colors.BAR_BACKGROUND)
                love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
            end
            break
        end
    end
end

function HUD:drawStats(player)
    if not player then return end
    
    local stats = player:getStats()
    if not stats.baseHp or not self.cardY then return end
    
    local screenH = love.graphics.getHeight()
    local statsY = self.cardY + HUD_CONSTANTS.HUD_HEIGHT + 10  -- под карточкой
    local statsX = HUD_CONSTANTS.CARD_PADDING
    local statsOffset = HUD_CONSTANTS.HUD_ELEMENTS_OFFSET_Y + 4
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    
    -- HP: baseHp + hpGrowth
    local hpText = "HP: " .. MathUtils.round(stats.baseHp, 1) .. " + " .. MathUtils.round(stats.hpGrowth, 1)
    love.graphics.print(hpText, statsX, statsY)
    
    -- Armor: baseArmor + armorGrowth
    local armorY = statsY + statsOffset
    local armorText = "Armor: " .. MathUtils.round(stats.baseArmor, 1) .. " + " .. MathUtils.round(stats.armorGrowth, 1)
    love.graphics.print(armorText, statsX, armorY)
    
    -- MoveSpeed: baseMoveSpeed + speedGrowth
    local speedY = armorY + statsOffset
    local speedText = "MoveSpeed: " .. MathUtils.round(stats.baseMoveSpeed, 1) .. " + " .. MathUtils.round(stats.speedGrowth, 1)
    love.graphics.print(speedText, statsX, speedY)
    
    -- PickupRange
    local pickupY = speedY + statsOffset
    local pickupText = "PickupRange: " .. MathUtils.round(stats.pickupRange or 100, 1)
    love.graphics.print(pickupText, statsX, pickupY)
end

function HUD:drawTimer(gameTime)
    love.graphics.setFont(self.fontLarge)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    local timeStr = MathUtils.formatTime(gameTime)
    love.graphics.printf(timeStr, 0, HUD_CONSTANTS.START_Y, love.graphics.getWidth(), "center")
end

return HUD
