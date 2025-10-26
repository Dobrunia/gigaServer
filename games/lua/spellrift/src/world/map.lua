local Map = {}
Map.__index = Map

function Map.new(width, height)
    local self = setmetatable({}, Map)
    
    self.width = width or 1000
    self.height = height or 1000
    
    -- Создаем Canvas для карты
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    
    -- Рендерим карту один раз
    self:renderMap()
    
    return self
end

function Map:renderMap()
    -- Рисуем карту на Canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    
    -- Просто зеленый фон
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

function Map:draw()
    -- Рисуем карту (статично)
    love.graphics.draw(self.canvas, 0, 0)
end

return Map