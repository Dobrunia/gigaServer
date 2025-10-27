local UIConstants = require("src.ui.ui_constants")
local heroes = require("src.config.heroes")
local SpriteManager = require("src.utils.sprite_manager")

local UIHeroSelect = {}
UIHeroSelect.__index = UIHeroSelect

-- Layout
local CARD_WIDTH = 500
local CARD_HEIGHT = 390
local CARD_SPACING = 40
local CARDS_PER_ROW = 3
local CARDS_START_Y = 100
local CARD_BORDER_RADIUS = 8
local CARD_PADDING = 20
local CARD_MAIN_SPRITE_SIZE = 128
local CARD_ELEMENTS_OFFSET_Y = 100
local CARD_INNATE_SPRITE_SIZE = 40
local CARD_DESCRIPTION_HEIGHT = CARD_INNATE_SPRITE_SIZE + CARD_PADDING * 2

-- Colors (RGB tuples)
local BG_COLOR = {0.08, 0.08, 0.08, 1}
local CARD_BG = {0.12, 0.12, 0.12, 1}
local CARD_BORDER = {0.7, 0.7, 0.7, 0.18}
local CARD_SELECTED = {0.20, 0.45, 0.20, 0.95}
local TEXT_COLOR = {1, 1, 1, 1}
local SUBTEXT_COLOR = {0.85, 0.85, 0.85, 1}
local PANEL_BG = {0.15, 0.15, 0.15, 0.9}

-- Reused constants
local ICON_STAT_SIZE = UIConstants.FONT_MEDIUM

-- ctor
function UIHeroSelect.new()
    local self = setmetatable({}, UIHeroSelect)

    -- fonts (создаём один раз)
    self.fontLarge = love.graphics.newFont(UIConstants.FONT_LARGE)
    self.fontMedium = love.graphics.newFont(UIConstants.FONT_MEDIUM)
    self.fontSmall = love.graphics.newFont(UIConstants.FONT_SMALL)

    -- load heroes
    self.heroes = {}
    for heroId, cfg in pairs(heroes) do
        local spriteSheet = nil
        if SpriteManager and SpriteManager.loadHeroSprite then
            spriteSheet = SpriteManager.loadHeroSprite(heroId)
        end
        table.insert(self.heroes, { id = heroId, config = cfg, sprite = spriteSheet })
    end

    self.selectedIndex = 1
    return self
end

-- helper: compute card rect by index
local function cardRectForIndex(index, screenW)
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2
    local row = math.floor((index - 1) / CARDS_PER_ROW)
    local col = (index - 1) % CARDS_PER_ROW
    local x = startX + col * (CARD_WIDTH + CARD_SPACING)
    local y = CARD_START_Y or CARD_START_Y -- fallback (keeps same var name)
    y = CARD_START_Y + row * (CARD_HEIGHT + CARD_SPACING)
    return x, y, CARD_WIDTH, CARD_HEIGHT
end

-- draw single stat line (iconless): label + value
local function drawStatLine(x, y, label, value, font)
    love.graphics.setFont(font)
    love.graphics.setColor(SUBTEXT_COLOR)
    love.graphics.print(label .. ": ", x, y)
    local labelW = font:getWidth(label .. ": ")
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print(value, x + labelW, y)
end

-- DRAW
function UIHeroSelect:draw()
    -- background
    love.graphics.setColor(BG_COLOR)
    love.graphics.clear()

    -- title
    love.graphics.setFont(self.fontLarge)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf("Choose Your Hero", 0, 50, love.graphics.getWidth(), "center")

    local screenW = love.graphics.getWidth()
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2

    for i, entry in ipairs(self.heroes) do
        local cfg = entry.config
        local spriteSheet = entry.sprite

        local row = math.floor((i - 1) / CARDS_PER_ROW)
        local col = (i - 1) % CARDS_PER_ROW
        local x = startX + col * (CARD_WIDTH + CARD_SPACING)
        local y = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)

        local isSelected = (self.selectedIndex == i)

        -- card background
        love.graphics.setColor(isSelected and CARD_SELECTED or CARD_BG)
        love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)

        -- card border
        love.graphics.setColor(CARD_BORDER)
        love.graphics.setLineWidth(isSelected and 3 or 1)
        love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
        love.graphics.setLineWidth(1)

        -- hero name
        love.graphics.setFont(self.fontMedium)
        love.graphics.setColor(TEXT_COLOR)
        love.graphics.print(cfg.name, x + CARD_PADDING, y + CARD_PADDING)

        -- hero sprite (centered horizontally inside card)
        local spriteX = x + CARD_WIDTH / 2
        local spriteY = y + CARD_ELEMENTS_OFFSET_Y
        if spriteSheet then
            -- предполагаем, что SpriteManager.getQuad(sheet, col, row, tileW, tileH)
            local ok, quad = pcall(function() return SpriteManager.getQuad(spriteSheet, 1, 1, 64, 64) end)
            if ok and quad then
                local scale = CARD_MAIN_SPRITE_SIZE / 64
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(spriteSheet, quad, spriteX, spriteY, 0, scale, scale, 32, 32)
            end
        else
            -- fallback: просто маленький кружок вместо спрайта
            love.graphics.setColor(0.2, 0.6, 0.2, 1)
            love.graphics.circle("fill", spriteX, spriteY, CARD_MAIN_SPRITE_SIZE/4)
        end

        -- stats block (bottom-left of card)
        local statsX = x + CARD_PADDING
        local statsY = y + CARD_HEIGHT - 120
        drawStatLine(statsX, statsY + 0, "HP", tostring(cfg.baseHp) .. " (+" .. tostring(cfg.hpGrowth) .. ")", self.fontSmall)
        drawStatLine(statsX, statsY + 20, "Armor", tostring(cfg.baseArmor) .. " (+" .. tostring(cfg.armorGrowth) .. ")", self.fontSmall)
        drawStatLine(statsX, statsY + 40, "Speed", tostring(cfg.baseMoveSpeed) .. " (+" .. tostring(cfg.speedGrowth) .. ")", self.fontSmall)
        drawStatLine(statsX, statsY + 60, "Cast", tostring(cfg.baseCastSpeed) .. "x (+" .. tostring(cfg.castSpeedGrowth) .. ")", self.fontSmall)

        -- innate panel (bottom area)
        local innateX = x + CARD_PADDING
        local innateY = y + CARD_HEIGHT - CARD_DESCRIPTION_HEIGHT - CARD_PADDING
        love.graphics.setColor(PANEL_BG)
        love.graphics.rectangle("fill", innateX, innateY, CARD_WIDTH - CARD_PADDING * 2, CARD_DESCRIPTION_HEIGHT, 6, 6)

        -- innate icon if spriteSheet exists: use quad (col=2,row=1) as in your example
        local iconX = innateX + CARD_PADDING + CARD_INNATE_SPRITE_SIZE/2
        local iconY = innateY + CARD_PADDING + CARD_INNATE_SPRITE_SIZE/2
        if spriteSheet then
            local ok2, quad2 = pcall(function() return SpriteManager.getQuad(spriteSheet, 2, 1, 64, 64) end)
            if ok2 and quad2 then
                local scale = CARD_INNATE_SPRITE_SIZE / 64
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(spriteSheet, quad2, iconX, iconY, 0, scale, scale, 32, 32)
            end
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.rectangle("fill", iconX - 10, iconY - 10, 20, 20)
        end

        -- innate description text (to the right of icon)
        love.graphics.setFont(self.fontSmall)
        love.graphics.setColor(TEXT_COLOR)
        local descX = iconX + CARD_PADDING + CARD_INNATE_SPRITE_SIZE/2
        local descW = CARD_WIDTH - CARD_PADDING*3 - CARD_INNATE_SPRITE_SIZE
        local descY = iconY - 10
        local descText = (cfg.innateSkill and cfg.innateSkill.description) or ""
        love.graphics.printf(descText, descX, descY, descW, "left")
    end
end

-- input handling: returns selected index or nil
function UIHeroSelect:handleClick(x, y)
    local screenW = love.graphics.getWidth()
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2

    for i = 1, #self.heroes do
        local row = math.floor((i - 1) / CARDS_PER_ROW)
        local col = (i - 1) % CARDS_PER_ROW
        local cardX = startX + col * (CARD_WIDTH + CARD_SPACING)
        local cardY = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)
        if x >= cardX and x <= cardX + CARD_WIDTH and y >= cardY and y <= cardY + CARD_HEIGHT then
            self.selectedIndex = i
            return i
        end
    end
    return nil
end

function UIHeroSelect:selectByIndex(index)
    if index and index >= 1 and index <= #self.heroes then
        self.selectedIndex = index
    end
end

function UIHeroSelect:getSelectedHero()
    return self.selectedIndex and self.heroes[self.selectedIndex] or nil
end

return UIHeroSelect
