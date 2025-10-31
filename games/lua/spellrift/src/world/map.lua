local SpriteManager = require("src.utils.sprite_manager")

local Map = {}
Map.__index = Map

function Map.new(width, height)
    local self = setmetatable({}, Map)
    
    self.width = width or 5000  -- Увеличиваем размер карты
    self.height = height or 5000
    
    -- Загружаем спрайт-лист карты
    self.mapSpriteSheet = SpriteManager.loadMapSprite()
    
    -- Размер тайла биома
    self.tileSize = 64
    
    -- Количество биомов в спрайт-листе (5 штук)
    self.numBiomes = 5
    
    -- Создаем quads для всех биомов (они идут в ряд: 1x5)
    self.biomeQuads = {}
    for i = 1, self.numBiomes do
        self.biomeQuads[i] = SpriteManager.getQuad(self.mapSpriteSheet, i, 1, self.tileSize, self.tileSize)
    end
    
    -- Создаем quad для стены (6-я колонка)
    self.wallQuad = SpriteManager.getQuad(self.mapSpriteSheet, 6, 1, self.tileSize, self.tileSize)
    
    -- Генерируем случайные позиции биомов
    self:generateBiomes()
    
    -- Создаем Canvas для карты
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    
    -- Рендерим карту один раз
    self:renderMap()
    
    return self
end

-- Генерирует центры биомов (зоны влияния)
function Map:generateBiomeCenters()
    -- Количество центров биомов на карте
    local numCenters = 15  -- примерно 15 зон биомов
    
    self.biomeCenters = {}
    for i = 1, numCenters do
        local centerX = math.random(0, self.width)
        local centerY = math.random(0, self.height)
        local biomeType = math.random(1, self.numBiomes)
        local radius = math.random(400, 800)  -- радиус влияния биома
        
        table.insert(self.biomeCenters, {
            x = centerX,
            y = centerY,
            type = biomeType,
            radius = radius
        })
    end
end

-- Определяет тип биома для ячейки сетки на основе ближайших центров
function Map:getBiomeTypeForCell(gridX, gridY)
    local cellX = gridX * self.tileSize
    local cellY = gridY * self.tileSize
    
    local bestType = math.random(1, self.numBiomes)  -- дефолтный случайный
    local maxInfluence = 0
    
    -- Проверяем влияние каждого центра биома
    for _, center in ipairs(self.biomeCenters) do
        local dx = cellX - center.x
        local dy = cellY - center.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist <= center.radius then
            -- Влияние уменьшается с расстоянием
            local influence = 1.0 - (dist / center.radius)
            if influence > maxInfluence then
                maxInfluence = influence
                bestType = center.type
            end
        end
    end
    
    -- Если мы в зоне влияния, с небольшой вероятностью можем выбрать соседний тип
    if maxInfluence > 0.1 and math.random() < 0.15 then
        bestType = math.random(1, self.numBiomes)
    end
    
    return bestType
end

-- Генерирует полную сетку блоков без промежутков
function Map:generateBiomes()
    -- Генерируем центры биомов
    self:generateBiomeCenters()
    
    -- Вычисляем размеры сетки
    local cols = math.ceil(self.width / self.tileSize)
    local rows = math.ceil(self.height / self.tileSize)
    
    -- Создаем 2D массив для хранения типов биомов (для проверки соседей)
    local biomeGrid = {}
    for y = 1, rows do
        biomeGrid[y] = {}
    end
    
    self.biomes = {}  -- Массив всех тайлов для отрисовки
    
    -- Заполняем всю карту блоками в сетке
    for y = 0, rows - 1 do
        for x = 0, cols - 1 do
            local gridX = x
            local gridY = y
            
            -- Определяем тип биома для этой ячейки на основе центров
            local biomeType = self:getBiomeTypeForCell(gridX, gridY)
            
            -- Учитываем соседние блоки: если сосед того же типа, увеличиваем шанс
            -- Проверяем левого соседа (x-1)
            if gridX > 0 and biomeGrid[gridY + 1] and biomeGrid[gridY + 1][gridX] then
                local neighborType = biomeGrid[gridY + 1][gridX]
                -- 70% шанс использовать тип соседа, если он есть
                if neighborType and math.random() < 0.7 then
                    biomeType = neighborType
                end
            end
            
            -- Проверяем верхнего соседа (y-1)
            if gridY > 0 and biomeGrid[gridY] and biomeGrid[gridY][gridX + 1] then
                local neighborType = biomeGrid[gridY][gridX + 1]
                if neighborType and math.random() < 0.6 then
                    biomeType = neighborType
                end
            end
            
            -- Сохраняем тип в сетку
            if not biomeGrid[gridY + 1] then
                biomeGrid[gridY + 1] = {}
            end
            biomeGrid[gridY + 1][gridX + 1] = biomeType
            
            -- Позиция блока в сетке (без смещений)
            local blockX = gridX * self.tileSize
            local blockY = gridY * self.tileSize
            
            -- Проверяем, что блок не выходит за границы карты
            if blockX < self.width and blockY < self.height then
                table.insert(self.biomes, {
                    x = blockX,
                    y = blockY,
                    quad = self.biomeQuads[biomeType]
                })
            end
        end
    end
end

function Map:renderMap()
    -- Рисуем карту на Canvas (один раз при создании, не перерисовываем постоянно)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    
    -- Фон убираем - биомы сами формируют фон
    -- Рисуем биомы затемненными, чтобы существа и предметы выделялись
    love.graphics.setColor(0.35, 0.35, 0.35, 1)  -- затемняем блоки до 65% яркости
    for _, biome in ipairs(self.biomes) do
        if biome.quad then
            love.graphics.draw(self.mapSpriteSheet, biome.quad, biome.x, biome.y)
        end
    end
    
    -- Рисуем стены по краям карты (непроходимые)
    love.graphics.setColor(0.65, 0.65, 0.65, 1)  -- такой же уровень затемнения
    local cols = math.ceil(self.width / self.tileSize)
    local rows = math.ceil(self.height / self.tileSize)
    
    -- Верхняя стена
    for x = 0, cols - 1 do
        local wallX = x * self.tileSize
        if wallX < self.width then
            love.graphics.draw(self.mapSpriteSheet, self.wallQuad, wallX, 0)
        end
    end
    
    -- Нижняя стена
    local bottomY = rows * self.tileSize - self.tileSize
    if bottomY + self.tileSize > self.height then
        bottomY = self.height - self.tileSize
    end
    for x = 0, cols - 1 do
        local wallX = x * self.tileSize
        if wallX < self.width then
            love.graphics.draw(self.mapSpriteSheet, self.wallQuad, wallX, bottomY)
        end
    end
    
    -- Левая стена
    for y = 1, rows - 2 do
        local wallY = y * self.tileSize
        if wallY + self.tileSize <= self.height then
            love.graphics.draw(self.mapSpriteSheet, self.wallQuad, 0, wallY)
        end
    end
    
    -- Правая стена
    local rightX = cols * self.tileSize - self.tileSize
    if rightX + self.tileSize > self.width then
        rightX = self.width - self.tileSize
    end
    for y = 1, rows - 2 do
        local wallY = y * self.tileSize
        if wallY + self.tileSize <= self.height then
            love.graphics.draw(self.mapSpriteSheet, self.wallQuad, rightX, wallY)
        end
    end
    
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

function Map:draw()
    -- Рисуем карту (статично)
    love.graphics.draw(self.canvas, 0, 0)
end

return Map