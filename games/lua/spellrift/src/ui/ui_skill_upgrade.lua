local UIConstants   = require("src.ui.ui_constants")
local SkillsConfig  = require("src.config.skills")
local SpriteManager = require("src.utils.sprite_manager")

local UISkillUpgrade = {}
UISkillUpgrade.__index = UISkillUpgrade

-- Layout
local CARD_WIDTH  = 420
local CARD_HEIGHT = 320
local CARD_SPACING = 30
local CARDS_COUNT = 3
local CARDS_START_Y = 150
local CARD_BORDER_RADIUS = 8
local CARD_PADDING = 16
local SPRITE_SIZE = 96

-- Colors
local BG_COLOR       = {0.08, 0.08, 0.08, 1}
local CARD_BG        = {0.12, 0.12, 0.12, 1}
local CARD_BORDER    = {0.7, 0.7, 0.7, 0.18}
local CARD_SELECTED  = {0.20, 0.45, 0.20, 0.95}
local TEXT_COLOR     = {1, 1, 1, 1}
local SUBTEXT_COLOR  = {0.85, 0.85, 0.85, 1}
local PANEL_BG       = {0.15, 0.15, 0.15, 0.9}
local UPGRADE_BADGE  = {0.8, 0.6, 0.2, 1}

-- Порядок отображения статов
local STAT_ORDER = {
  "damage", "cooldown", "range", "speed", "radius",
  "debuffType", "debuffDuration", "debuffDamage", "debuffTickRate"
}

local prettyNames = {
    damage = "Damage",
    cooldown = "Cooldown",
    range = "Range",
    speed = "Speed",
    radius = "Radius",
    debuffType = "Debuff",
    debuffDuration = "Debuff time",
    debuffDamage = "Debuff dmg",
    debuffTickRate = "Debuff tick"
}

local function prettyStatName(key)
    return prettyNames[key] or key
end

function UISkillUpgrade.new(hero, availableOptions)
    local self = setmetatable({}, UISkillUpgrade)

    self.fontLarge  = love.graphics.newFont(UIConstants.FONT_LARGE or 28)
    self.fontMedium = love.graphics.newFont(UIConstants.FONT_MEDIUM or 18)
    self.fontSmall  = love.graphics.newFont(UIConstants.FONT_SMALL or 14)

    self.hero = hero
    self.options = availableOptions or {}
    self.selectedIndex = (#self.options > 0) and 1 or nil
    
    return self
end

local function drawKV(x, y, key, value, font)
    love.graphics.setFont(font)
    love.graphics.setColor(SUBTEXT_COLOR)
    love.graphics.print(prettyStatName(key) .. ": ", x, y)
    local labelW = font:getWidth(prettyStatName(key) .. ": ")
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print(tostring(value), x + labelW, y)
end

-- Получить следующее улучшение для скилла
local function getNextUpgrade(skill)
    if not skill.upgrades or not skill:canLevelUp() then
        return nil
    end
    local nextLevel = skill.level + 1
    if nextLevel <= skill.maxLevel then
        return skill.upgrades[nextLevel - 1]
    end
    return nil
end

-- Рисуем карточку нового скилла
local function drawNewSkillCard(self, x, y, option, isSelected)
    local cfg = option.config
    local spriteSheet = option.sprite

    -- Карточка
    love.graphics.setColor(isSelected and CARD_SELECTED or CARD_BG)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)

    love.graphics.setColor(CARD_BORDER)
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
    love.graphics.setLineWidth(1)

    -- Бейдж "NEW"
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(UPGRADE_BADGE)
    love.graphics.print("NEW SKILL", x + CARD_PADDING, y + CARD_PADDING)

    -- Имя
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print(cfg.name or option.id, x + CARD_PADDING, y + CARD_PADDING + 20)

    -- Спрайт
    local spriteX = x + CARD_PADDING + SPRITE_SIZE/2
    local spriteY = y + CARD_PADDING + SPRITE_SIZE + 40
    if spriteSheet then
        local quad = SpriteManager.getQuad(spriteSheet, 1, 1, 64, 64)
        local scale = SPRITE_SIZE / 64
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(spriteSheet, quad, spriteX, spriteY, 0, scale, scale, 32, 32)
    else
        love.graphics.setColor(0.35, 0.35, 0.35, 1)
        love.graphics.rectangle("fill", spriteX - SPRITE_SIZE/2, spriteY - SPRITE_SIZE/2, SPRITE_SIZE, SPRITE_SIZE, 6, 6)
    end

    -- Описание
    local descX = x + CARD_PADDING*2 + SPRITE_SIZE
    local descY = y + CARD_PADDING + 40
    local descW = CARD_WIDTH - (descX - x) - CARD_PADDING
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf(cfg.description or "", descX, descY, descW, "left")

    -- Статы
    local lineY = descY + 60
    local shown = {}
    for _, key in ipairs(STAT_ORDER) do
        local value = cfg.stats and cfg.stats[key]
        if value ~= nil then
            drawKV(descX, lineY, key, value, self.fontSmall)
            lineY = lineY + 18
            shown[key] = true
        end
    end
    if cfg.stats then
        for key, value in pairs(cfg.stats) do
            if shown[key] ~= true then
                drawKV(descX, lineY, key, value, self.fontSmall)
                lineY = lineY + 18
            end
        end
    end

    -- Панель с уровнями
    local panelH = 36
    local panelY = y + CARD_HEIGHT - panelH - CARD_PADDING
    local panelX = x + CARD_PADDING
    local panelW = CARD_WIDTH - CARD_PADDING*2
    love.graphics.setColor(PANEL_BG)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(TEXT_COLOR)
    local levels = (cfg.upgrades and #cfg.upgrades or 0) + 1
    local text = ("Max Level: %d"):format(levels)
    love.graphics.print(text, panelX + 10, panelY + (panelH - self.fontSmall:getHeight())/2)
end

-- Рисуем карточку улучшения существующего скилла
local function drawUpgradeCard(self, x, y, option, isSelected)
    local skill = option.skill
    local cfg = option.config
    local upgrade = option.upgrade
    local spriteSheet = option.sprite

    -- Карточка
    love.graphics.setColor(isSelected and CARD_SELECTED or CARD_BG)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)

    love.graphics.setColor(CARD_BORDER)
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
    love.graphics.setLineWidth(1)

    -- Бейдж "UPGRADE"
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(UPGRADE_BADGE)
    love.graphics.print("UPGRADE", x + CARD_PADDING, y + CARD_PADDING)

    -- Имя + текущий уровень
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(TEXT_COLOR)
    local nameText = (cfg.name or skill.id) .. (" (Lv %d → %d)"):format(skill.level, skill.level + 1)
    love.graphics.print(nameText, x + CARD_PADDING, y + CARD_PADDING + 20)

    -- Спрайт
    local spriteX = x + CARD_PADDING + SPRITE_SIZE/2
    local spriteY = y + CARD_PADDING + SPRITE_SIZE + 40
    if spriteSheet then
        local quad = SpriteManager.getQuad(spriteSheet, 1, 1, 64, 64)
        local scale = SPRITE_SIZE / 64
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(spriteSheet, quad, spriteX, spriteY, 0, scale, scale, 32, 32)
    end

    -- Описание улучшения
    local descX = x + CARD_PADDING*2 + SPRITE_SIZE
    local descY = y + CARD_PADDING + 40
    local descW = CARD_WIDTH - (descX - x) - CARD_PADDING
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf("Improvements:", descX, descY, descW, "left")

    -- Показываем изменения статов
    local lineY = descY + 25
    for key, value in pairs(upgrade) do
        local currentValue = skill.stats and skill.stats[key]
        if currentValue ~= nil then
            local diff = value - currentValue
            if diff ~= 0 then
                local sign = diff > 0 and "+" or ""
                local text = ("%s: %s%.1f"):format(prettyStatName(key), sign, diff)
                love.graphics.setColor(TEXT_COLOR)
                love.graphics.print(text, descX, lineY)
                lineY = lineY + 18
            end
        else
            -- Новый стат
            local text = ("%s: +%s"):format(prettyStatName(key), tostring(value))
            love.graphics.setColor(TEXT_COLOR)
            love.graphics.print(text, descX, lineY)
            lineY = lineY + 18
        end
    end
end

function UISkillUpgrade:draw()
    love.graphics.setColor(BG_COLOR)
    love.graphics.clear()

    -- Заголовок
    love.graphics.setFont(self.fontLarge)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf("Level Up! Choose an Upgrade", 0, 50, love.graphics.getWidth(), "center")

    -- Информация об уровне
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(SUBTEXT_COLOR)
    local levelText = ("Hero Level: %d"):format(self.hero.level)
    love.graphics.printf(levelText, 0, 100, love.graphics.getWidth(), "center")

    if #self.options == 0 then
        love.graphics.printf("No upgrades available", 0, 200, love.graphics.getWidth(), "center")
        return
    end

    local screenW = love.graphics.getWidth()
    local totalWidth = (CARD_WIDTH * CARDS_COUNT) + (CARD_SPACING * (CARDS_COUNT - 1))
    local startX = (screenW - totalWidth) / 2

    for i, option in ipairs(self.options) do
        local x = startX + (i - 1) * (CARD_WIDTH + CARD_SPACING)
        local y = CARDS_START_Y
        local isSelected = (self.selectedIndex == i)

        if option.type == "new_skill" then
            drawNewSkillCard(self, x, y, option, isSelected)
        elseif option.type == "upgrade" then
            drawUpgradeCard(self, x, y, option, isSelected)
        end
    end

    -- Подсказка
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(SUBTEXT_COLOR)
    love.graphics.printf("Click on a card to select", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

function UISkillUpgrade:handleClick(x, y)
    local screenW = love.graphics.getWidth()
    local totalWidth = (CARD_WIDTH * CARDS_COUNT) + (CARD_SPACING * (CARDS_COUNT - 1))
    local startX = (screenW - totalWidth) / 2

    for i = 1, #self.options do
        local cardX = startX + (i - 1) * (CARD_WIDTH + CARD_SPACING)
        local cardY = CARDS_START_Y

        -- Проверяем попадание в карточку
        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT
        then
            return self.options[i]
        end
    end
    return nil
end

function UISkillUpgrade:update(dt, input)
    if not input then
        return nil
    end
    
    -- Проверяем клик мыши - используем метод для надежности
    if input:isLeftMousePressed() then
        local mx, my = input:getMousePosition()
        local selected = self:handleClick(mx, my)
        if selected then
            return selected
        end
    end
    
    return nil
end

return UISkillUpgrade

