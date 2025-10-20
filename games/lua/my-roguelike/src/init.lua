local Character = require("src.entity.character")

local Game = {}

-- Размер тайла
local TILE_SIZE = 32

function Game:load()
    -- Создаем персонажа
    self.player = Character:new({
        key = "Mage",
        x = 10,
        y = 10
    })
    
    -- Размеры окна
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
end

function Game:update(dt)
    -- Пока ничего не обновляем
end

function Game:draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    -- Рисуем персонажа
    if self.player then
        local px = self.player.x * TILE_SIZE
        local py = self.player.y * TILE_SIZE
        
        -- Рисуем квадрат для персонажа
        love.graphics.setColor(0.3, 0.5, 1)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        
        -- HP бар над персонажем
        self.player:drawHpBar(px, py, TILE_SIZE)

        -- Рисуем символ персонажа
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.player.symbol or "@", px + 8, py + 8, 0, 2, 2)
    end
end

function Game:keypressed(key, scancode, isrepeat)
    if not self.player then return end
    
    -- WASD движение
    if key == "w" or key == "up" then
        self.player:move(0, -1)
    elseif key == "s" or key == "down" then
        self.player:move(0, 1)
    elseif key == "a" or key == "left" then
        self.player:move(-1, 0)
    elseif key == "d" or key == "right" then
        self.player:move(1, 0)
    end
end

return Game
