-- src/init.lua
local M = {}

-- Конфигурация сетки
local TILE_SIZE = 16
local MAP_W, MAP_H = 40, 25

-- Игрок
local player = { x = 1, y = 1 }

-- Карта: 1 = wall, 0 = floor
local map = {}

local function new_map()
    map = {}
    for y = 1, MAP_H do
        map[y] = {}
        for x = 1, MAP_W do
            map[y][x] = 1
        end
    end
end

local dirs = {
    {1,0},{-1,0},{0,1},{0,-1}
}

-- Простейший "drunkard walk" генератор
local function generate_map(percent_floor)
    percent_floor = percent_floor or 0.35
    new_map()
    local x = math.floor(MAP_W/2)
    local y = math.floor(MAP_H/2)
    map[y][x] = 0
    local floor_count = 1
    local target = math.floor(MAP_W * MAP_H * percent_floor)

    while floor_count < target do
        local d = dirs[math.random(1, #dirs)]
        x = math.max(2, math.min(MAP_W-1, x + d[1]))
        y = math.max(2, math.min(MAP_H-1, y + d[2]))
        if map[y][x] == 1 then
            map[y][x] = 0
            floor_count = floor_count + 1
        end
    end

    -- поместим игрока на первый найденный пол
    for yy = 1, MAP_H do
        for xx = 1, MAP_W do
            if map[yy][xx] == 0 then
                player.x = xx
                player.y = yy
                return
            end
        end
    end
end

-- Рисование простой карты: квадратики
local function draw_map()
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local tile = map[y][x]
            if tile == 1 then
                love.graphics.setColor(0.2, 0.2, 0.2) -- стена (темнее)
            else
                love.graphics.setColor(0.85, 0.85, 0.85) -- пол (светлее)
            end
            love.graphics.rectangle("fill",
                (x-1)*TILE_SIZE, (y-1)*TILE_SIZE,
                TILE_SIZE-1, TILE_SIZE-1)
        end
    end
end

-- Рисуем игрока
local function draw_player()
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill",
        (player.x-1)*TILE_SIZE, (player.y-1)*TILE_SIZE,
        TILE_SIZE-1, TILE_SIZE-1)
end

-- Проверка на проходимость
local function is_walkable(x,y)
    if x < 1 or x > MAP_W or y < 1 or y > MAP_H then
        return false
    end
    return map[y][x] == 0
end

-- Пошаговое движение (по кнопкам стрелок / wasd)
function M:keypressed(key)
    local dx, dy = 0, 0
    if key == "left" or key == "a" then dx = -1 end
    if key == "right" or key == "d" then dx = 1 end
    if key == "up" or key == "w" then dy = -1 end
    if key == "down" or key == "s" then dy = 1 end

    if dx ~= 0 or dy ~= 0 then
        local nx, ny = player.x + dx, player.y + dy
        if is_walkable(nx, ny) then
            player.x, player.y = nx, ny
        end
    elseif key == "r" then
        -- перестроить карту (полезно при тестировании)
        generate_map(0.37)
    end
end

-- Инициализация
function M:load()
    generate_map(0.37)
    love.window.setMode(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE, {resizable=false})
end

function M:update(dt)
    -- Для пошаговой логики тут ничего не нужно (всё по keypressed)
end

function M:draw()
    love.graphics.clear(0.1, 0.1, 0.12)
    draw_map()
    draw_player()

    -- подсказки
    love.graphics.setColor(1,1,1)
    love.graphics.print("Arrows / WASD - move, R - regen map", 6, MAP_H * TILE_SIZE + 4)
end

return M
