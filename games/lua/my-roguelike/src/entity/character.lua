local Mob = require("src.entity.Mob")

local Character = {}
Character.__index = Character
setmetatable(Character, {__index = Mob})

local DEFAULT = {
    speed = 50,
    armor = 0,
    maxHp = 100,
}

-- Конструктор персонажа
-- пример character_data = {
--     x = 0,
--     y = 0,
--     maxHp = 100,
--     key = Mage,
-- }
function Character:new(character_data)
    local chars = require("src.data.chars")

    local key = character_data.key
    if not key then
        error("character_data.key is required")
    end

    local charData = chars[key]
    if not charData then
        error("Character '" .. key .. "' not found in chars.lua")
    end

    local x = character_data.x
    local y = character_data.y

    local obj = Mob:new(x, y, charData.maxHp or DEFAULT.maxHp)
    setmetatable(obj, self)

    -- Базовые параметры
    obj.level = 1
    obj.expToNext = 100
    obj.exp = 0

    -- Параметры из chars.lua
    obj.speed = charData.speed or DEFAULT.speed
    obj.armor = charData.armor or DEFAULT.armor
    obj.name = charData.name
    obj.symbol = charData.symbol or "@"
    obj.spriteRow = charData.spriteRow or 0
    obj.spriteCol = charData.spriteCol or 0

    return obj
end

-- Установить скорость (speed)
function Character:setSpeed(value)
    self.speed = tonumber(value)
end

-- Установить броню (armor)
function Character:setArmor(value)
    self.armor = tonumber(value)
end

-- Добавить опыт (exp) с простым повышением уровня
function Character:addExp(amount)
    self.exp = self.exp + tonumber(amount)

    -- Проверяем повышение уровня (может быть несколько уровней сразу)
    while self.exp >= self.expToNext do
        self.exp = self.exp - self.expToNext
        self.level = self.level + 1
        self.expToNext = math.floor(self.expToNext * 1.25)
    end
end

return Character
