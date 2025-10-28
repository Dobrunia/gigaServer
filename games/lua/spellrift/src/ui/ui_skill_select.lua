local UIConstants   = require("src.ui.ui_constants")
local SkillsConfig  = require("src.config.skills")
local SpriteManager = require("src.utils.sprite_manager")

local UISkillSelect = {}
UISkillSelect.__index = UISkillSelect

-- Layout
local CARD_WIDTH  = 420
local CARD_HEIGHT = 280
local CARD_SPACING = 30
local CARDS_PER_ROW = 3
local CARDS_START_Y = 110
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

-- Порядок отображения «типичных» статов; остальные выведем после них
local STAT_ORDER = {
  "damage", "cooldown", "range", "speed", "radius",
  "debuffType", "debuffDuration", "debuffDamage", "debuffTickRate"
}

-- ctor
function UISkillSelect.new()
  local self = setmetatable({}, UISkillSelect)

  -- Шрифты (создаём один раз)
  self.fontLarge  = love.graphics.newFont(UIConstants.FONT_LARGE or 28)
  self.fontMedium = love.graphics.newFont(UIConstants.FONT_MEDIUM or 18)
  self.fontSmall  = love.graphics.newFont(UIConstants.FONT_SMALL or 14)

  -- Собираем список стартовых навыков
  self.skills = {}
  for id, cfg in pairs(SkillsConfig) do
    if cfg.isStartingSkill then
      local sprite = SpriteManager.loadSkillSprite(id) -- кешируется внутри менеджера
      table.insert(self.skills, { id = id, config = cfg, sprite = sprite })
    end
  end

  -- Стабильный порядок (по имени)
  table.sort(self.skills, function(a, b)
    return (a.config.name or a.id) < (b.config.name or b.id)
  end)

  self.selectedIndex = (#self.skills > 0) and 1 or nil
  return self
end

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
  

local function drawKV(x, y, key, value, font)
  love.graphics.setFont(font)
  love.graphics.setColor(SUBTEXT_COLOR)
  love.graphics.print(prettyStatName(key) .. ": ", x, y)
  local labelW = font:getWidth(prettyStatName(key) .. ": ")
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(tostring(value), x + labelW, y)
end

-- считает кол-во уровней (апгрейдов)
local function countUpgrades(cfg)
  if not cfg.upgrades then return 0 end
  return #cfg.upgrades
end

-- DRAW
function UISkillSelect:draw()
  love.graphics.setColor(BG_COLOR)
  love.graphics.clear()

  -- Заголовок
  love.graphics.setFont(self.fontLarge)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.printf("Choose Starting Skill", 0, 50, love.graphics.getWidth(), "center")

  local screenW = love.graphics.getWidth()
  local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
  local startX = (screenW - totalWidth) / 2

  for i, entry in ipairs(self.skills) do
    local cfg = entry.config
    local spriteSheet = entry.sprite

    local row = math.floor((i - 1) / CARDS_PER_ROW)
    local col = (i - 1) % CARDS_PER_ROW
    local x = startX + col * (CARD_WIDTH + CARD_SPACING)
    local y = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)

    local isSelected = (self.selectedIndex == i)

    -- Карточка
    love.graphics.setColor(isSelected and CARD_SELECTED or CARD_BG)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)

    love.graphics.setColor(CARD_BORDER)
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
    love.graphics.setLineWidth(1)

    -- Имя
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print(cfg.name or entry.id, x + CARD_PADDING, y + CARD_PADDING)

    -- Спрайт (1,1) из спрайт-листа навыка
    local spriteX = x + CARD_PADDING + SPRITE_SIZE/2
    local spriteY = y + CARD_PADDING + SPRITE_SIZE + 12
    if spriteSheet then
      -- быстрый путь без pcall (если спрайт-лист неверный — упадёт)
      local quad = SpriteManager.getQuad(spriteSheet, 1, 1, 64, 64)
      local scale = SPRITE_SIZE / 64
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(spriteSheet, quad, spriteX, spriteY, 0, scale, scale, 32, 32)
    else
      -- заглушка
      love.graphics.setColor(0.35, 0.35, 0.35, 1)
      love.graphics.rectangle("fill", spriteX - SPRITE_SIZE/2, spriteY - SPRITE_SIZE/2, SPRITE_SIZE, SPRITE_SIZE, 6, 6)
    end

    -- Описание (справа от иконки)
    local descX = x + CARD_PADDING*2 + SPRITE_SIZE
    local descY = y + CARD_PADDING + 4
    local descW = CARD_WIDTH - (descX - x) - CARD_PADDING
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf(cfg.description or "", descX, descY, descW, "left")

    -- Базовые статы (под описанием)
    local lineY = descY + 60
    local shown = {}

    -- Сначала «типичные» ключи в заданном порядке
    for _, key in ipairs(STAT_ORDER) do
      local value = cfg.stats and cfg.stats[key]
      if value ~= nil then
        drawKV(descX, lineY, key, value, self.fontSmall)
        lineY = lineY + 18
        shown[key] = true
      end
    end
    -- Затем все остальные статы, которые есть в конфиге
    if cfg.stats then
      for key, value in pairs(cfg.stats) do
        if shown[key] ~= true then
          drawKV(descX, lineY, key, value, self.fontSmall)
          lineY = lineY + 18
        end
      end
    end

    -- Панель с апгрейдами (внизу)
    local panelH = 36
    local panelY = y + CARD_HEIGHT - panelH - CARD_PADDING
    local panelX = x + CARD_PADDING
    local panelW = CARD_WIDTH - CARD_PADDING*2
    love.graphics.setColor(PANEL_BG)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(TEXT_COLOR)
    local levels = countUpgrades(cfg) + 1 -- 1 базовый + апгрейды
    local text = ("Levels: %d"):format(levels)
    if cfg.upgrades and #cfg.upgrades > 0 then
      -- маленькая подсказка о первом апгрейде
      local up1 = cfg.upgrades[1]
      local firstKey, firstVal = next(up1)
      if firstKey ~= nil then
        text = text .. ("  |  +%s @ L2"):format(prettyStatName(firstKey))
      end
    end
    love.graphics.print(text, panelX + 10, panelY + (panelH - self.fontSmall:getHeight())/2)
  end
end

-- Клик мыши → выбрать карточку
function UISkillSelect:handleClick(x, y)
    local screenW = love.graphics.getWidth()
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2

    for i = 1, #self.skills do
        local row = math.floor((i - 1) / CARDS_PER_ROW)
        local col = (i - 1) % CARDS_PER_ROW
        local cardX = startX + col * (CARD_WIDTH + CARD_SPACING)
        local cardY = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)

        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT
        then
            return self.skills[i].id  -- Return skill ID directly
        end
    end
    return nil
end

return UISkillSelect
