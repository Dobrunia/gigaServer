local Constants = require("src.constants")

local DebugDisplay = {}
DebugDisplay.__index = DebugDisplay

function DebugDisplay.new()
    local self = setmetatable({}, DebugDisplay)
    
    -- Позиция отладки (левый верхний угол)
    self.x = 10
    self.y = 10
    
    -- Шрифт для отладки
    self.font = love.graphics.newFont(12)
    
    -- Данные для отображения
    self.fps = 0
    self.frameTime = 0
    self.memoryUsage = 0
    self.entityCounts = {
        heroes = 0,
        enemies = 0,
        projectiles = 0,
        drops = 0
    }
    
    -- Дополнительные параметры
    self.heroPosition = {x = 0, y = 0}
    self.cameraPosition = {x = 0, y = 0}
    self.gameTime = 0
    
    -- Счетчик кадров для FPS
    self.frameCount = 0
    self.fpsTimer = 0
    
    return self
end

function DebugDisplay:update(dt, world, hero, camera)
    -- Обновляем FPS
    self.frameCount = self.frameCount + 1
    self.fpsTimer = self.fpsTimer + dt
    
    if self.fpsTimer >= 1.0 then
        self.fps = self.frameCount
        self.frameCount = 0
        self.fpsTimer = 0
    end
    
    -- Обновляем время кадра
    self.frameTime = dt * 1000  -- в миллисекундах
    
    -- Обновляем использование памяти
    self.memoryUsage = collectgarbage("count")
    
    -- Обновляем игровое время
    self.gameTime = self.gameTime + dt
    
    -- Обновляем позиции
    if hero then
        self.heroPosition.x = math.floor(hero.x)
        self.heroPosition.y = math.floor(hero.y)
    end
    
    if camera then
        self.cameraPosition.x = math.floor(camera.x)
        self.cameraPosition.y = math.floor(camera.y)
    end
    
    -- Обновляем количество объектов
    if world then
        self.entityCounts.heroes = world.heroes and #world.heroes or 0
        self.entityCounts.enemies = world.enemies and #world.enemies or 0
        self.entityCounts.projectiles = world.projectiles and #world.projectiles or 0
        self.entityCounts.drops = world.drops and #world.drops or 0
    end
end

function DebugDisplay:draw()
    -- Сохраняем текущее состояние графики
    love.graphics.push()
    
    -- Устанавливаем шрифт
    love.graphics.setFont(self.font)
    
    -- Фон для отладки
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x - 5, self.y - 5, 195, 190)
    
    -- Рамка
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x - 5, self.y - 5, 195, 190)
    
    -- Текст отладки
    love.graphics.setColor(1, 1, 1, 1)
    local lineHeight = 15
    local currentY = self.y
    
    -- FPS
    love.graphics.printf("FPS: " .. self.fps, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Время кадра
    love.graphics.printf("Frame: " .. string.format("%.1f", self.frameTime) .. "ms", self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Память
    love.graphics.printf("Memory: " .. string.format("%.1f", self.memoryUsage) .. "KB", self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Разделитель
    love.graphics.printf("---", self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Количество объектов
    love.graphics.printf("Heroes: " .. self.entityCounts.heroes, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    love.graphics.printf("Enemies: " .. self.entityCounts.enemies, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    love.graphics.printf("Projectiles: " .. self.entityCounts.projectiles, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    love.graphics.printf("Drops: " .. self.entityCounts.drops, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Разделитель
    love.graphics.printf("---", self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Позиции
    love.graphics.printf("Hero: " .. self.heroPosition.x .. ", " .. self.heroPosition.y, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    love.graphics.printf("Camera: " .. self.cameraPosition.x .. ", " .. self.cameraPosition.y, self.x, currentY, 190, "left")
    currentY = currentY + lineHeight
    
    -- Игровое время
    love.graphics.printf("Time: " .. string.format("%.1f", self.gameTime) .. "s", self.x, currentY, 190, "left")
    
    -- Восстанавливаем состояние графики
    love.graphics.pop()
end

return DebugDisplay
