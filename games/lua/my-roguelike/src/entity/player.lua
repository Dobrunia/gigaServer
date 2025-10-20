local Mob = require("src.entity.Mob")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Mob})

local DEFAULT = {
    level = 1,
    expToNext = 100,
    exp = 0,
    speed = 1,
    armor = 0,
    maxHp = 100,
}

-- Конструктор игрока
function Player:new(player_data)
    local obj = Mob:new(
        player_data.x,
        player_data.y,
        player_data.maxHp or DEFAULT.maxHp)
    setmetatable(obj, self)

    -- Базовые неизменные на старте параметры
    obj.level =
    obj.expToNext =
    obj.exp =

    -- Параметры которые меняется на старте в зависимости от перса
    obj.speed =
    obj.armor =

    return obj
end

return Player
