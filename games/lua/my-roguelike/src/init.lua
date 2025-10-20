local Character = require("src.entity.character")

local Game = {}

-- Константы
local TILE_SIZE = 32
local MOVE_SPEED = 320 -- пикселей в секунду (увеличена для плавности)
local MOVE_COOLDOWN = 0.15 -- секунды между движениями (уменьшен для отзывчивости)

function Game:load()
    -- Загружаем спрайтшит
    self.spritesheet = love.graphics.newImage("assets/rogues.png")
    self.spritesheet:setFilter("nearest", "nearest") -- пиксельная графика
    
    -- Параметры спрайтшита
    self.spriteSize = 32
    self.spriteCols = 8
    
    -- Параметры карты
    self.mapWidth = 50
    self.mapHeight = 50
    
    -- Глобальная ссылка для мобов
    _G.Game = self
    
    -- Создаем персонажа
    self.player = Character:new({
        key = "Mage",
        x = self.mapWidth / 2,
        y = self.mapHeight / 2
    })
    
    -- Размеры окна
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    -- Камера (смещение мира)
    self.cameraX = 0
    self.cameraY = 0
    
    -- Для плавного движения
    self.player.screenX = self.player.x * TILE_SIZE
    self.player.screenY = self.player.y * TILE_SIZE
    self.player.targetX = self.player.screenX
    self.player.targetY = self.player.screenY
    self.player.moveSpeed = MOVE_SPEED
    
    -- Контроль движения
    self.lastMoveTime = 0
    self.moveCooldown = MOVE_COOLDOWN
    
    -- Геймпад
    self.gamepad = love.joystick.getJoysticks()[1]

    -- Отладочная отрисовка хитбокса
    self.debugHitbox = true

    -- Параметры навигации
    self.allowDiagonal = true
end

function Game:update(dt)
    if not self.player then return end
    
    -- Плавное движение к цели
    local dx = self.player.targetX - self.player.screenX
    local dy = self.player.targetY - self.player.screenY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance > 1 then
        local moveDistance = self.player.moveSpeed * dt
        local ratio = math.min(1, moveDistance / distance)
        
        self.player.screenX = self.player.screenX + dx * ratio
        self.player.screenY = self.player.screenY + dy * ratio
    else
        -- Достигли цели
        self.player.screenX = self.player.targetX
        self.player.screenY = self.player.targetY
        
        -- Проверяем зажатые клавиши для движения
        self:handleMovement()
    end
    
    -- Обновляем размеры окна (на случай ресайза)
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    -- Обновляем камеру: центрируем на персонаже
    -- Учитываем размер спрайта, чтобы центр был точно по центру спрайта
    local playerCenterX = self.player.screenX + TILE_SIZE / 2
    local playerCenterY = self.player.screenY + TILE_SIZE / 2
    self.cameraX = playerCenterX - self.screenWidth / 2
    self.cameraY = playerCenterY - self.screenHeight / 2
end

function Game:getInputDirection()
    local dx, dy = 0, 0
    
    -- Клавиатура
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    
    -- Геймпад
    if self.gamepad then
        local deadzone = 0.3
        local axisX = self.gamepad:getGamepadAxis("leftx")
        local axisY = self.gamepad:getGamepadAxis("lefty")
        
        if math.abs(axisX) > deadzone then
            dx = dx + (axisX > 0 and 1 or -1)
        end
        if math.abs(axisY) > deadzone then
            dy = dy + (axisY > 0 and 1 or -1)
        end
        
        -- D-pad
        if self.gamepad:isGamepadDown("dpup") then dy = dy - 1 end
        if self.gamepad:isGamepadDown("dpdown") then dy = dy + 1 end
        if self.gamepad:isGamepadDown("dpleft") then dx = dx - 1 end
        if self.gamepad:isGamepadDown("dpright") then dx = dx + 1 end
    end
    
    -- Нормализуем для диагонали (чтобы скорость была одинаковой)
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end
    
    return dx, dy
end

function Game:handleMovement()
    if not self.player then return end
    
    -- Проверяем кулдаун движения
    local currentTime = love.timer.getTime()
    if currentTime - self.lastMoveTime < self.moveCooldown then
        return
    end
    
    -- Если есть путь (A*) — двигаемся по нему
    if self.path and self.pathIndex and self.path[self.pathIndex] then
        local node = self.path[self.pathIndex]
        local dx = node.x - self.player.x
        local dy = node.y - self.player.y
        
        -- На всякий случай ограничим до одного тайла
        if dx > 1 then dx = 1 elseif dx < -1 then dx = -1 end
        if dy > 1 then dy = 1 elseif dy < -1 then dy = -1 end
        
        if dx ~= 0 or dy ~= 0 then
            -- Запоминаем старую позицию
            local oldX = self.player.x
            local oldY = self.player.y
            
            -- Пытаемся двигаться (move сам проверит границы)
            self.player:move(dx, dy)
            
            -- Проверяем, удалось ли сдвинуться
            if self.player.x ~= oldX or self.player.y ~= oldY then
                self.player.targetX = self.player.x * TILE_SIZE
                self.player.targetY = self.player.y * TILE_SIZE
                self.lastMoveTime = currentTime
                
                -- Если достигли узла — переходим к следующему
                if self.player.x == node.x and self.player.y == node.y then
                    self.pathIndex = self.pathIndex + 1
                    if not self.path[self.pathIndex] then
                        -- Путь пройден
                        self.path = nil
                        self.pathIndex = nil
                        self.player.targetGameX = nil
                        self.player.targetGameY = nil
                    end
                end
            else
                -- Не можем идти дальше - отменяем путь
                self.path = nil
                self.pathIndex = nil
                self.player.targetGameX = nil
                self.player.targetGameY = nil
            end
            return
        else
            -- Уже на узле, продвигаем индекс
            self.pathIndex = self.pathIndex + 1
            if not self.path[self.pathIndex] then
                self.path = nil
                self.pathIndex = nil
                self.player.targetGameX = nil
                self.player.targetGameY = nil
            end
            return
        end
    end
    
    -- Получаем направление из клавиатуры/геймпада
    local dx, dy = self:getInputDirection()
    
    -- Если есть ввод, двигаем персонажа
    if dx ~= 0 or dy ~= 0 then
        -- Округляем до целых для grid-движения
        local gridDx = math.floor(dx + 0.5)
        local gridDy = math.floor(dy + 0.5)
        
        if gridDx ~= 0 or gridDy ~= 0 then
            -- Запоминаем старую позицию
            local oldX = self.player.x
            local oldY = self.player.y
            
            -- Пытаемся двигаться (move сам проверит границы)
            self.player:move(gridDx, gridDy)
            
            -- Если удалось сдвинуться - обновляем состояние
            if self.player.x ~= oldX or self.player.y ~= oldY then
                self.player.targetX = self.player.x * TILE_SIZE
                self.player.targetY = self.player.y * TILE_SIZE
                self.lastMoveTime = currentTime
            end
            
            -- Отменяем движение к цели мыши при использовании клавиатуры
            self.player.targetGameX = nil
            self.player.targetGameY = nil
        end
    end
end

function Game:drawSprite(row, col, x, y, width, height)
    if not self.spritesheet or not row or not col then return end
    
    width = width or 32
    height = height or 32
    
    local sx = col * self.spriteSize
    local sy = row * self.spriteSize
    local scaleX = width / self.spriteSize
    local scaleY = height / self.spriteSize
    
    local quad = love.graphics.newQuad(
        sx, sy,
        self.spriteSize, self.spriteSize,
        self.spritesheet:getDimensions()
    )
    
    love.graphics.draw(self.spritesheet, quad, x, y, 0, scaleX, scaleY)
end

function Game:draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    -- Применяем камеру
    love.graphics.push()
    love.graphics.translate(-self.cameraX, -self.cameraY)
    
    -- Рисуем границы карты
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 0, self.mapWidth * TILE_SIZE, self.mapHeight * TILE_SIZE)
    
    -- Рисуем персонажа
    if self.player then
        local px = self.player.screenX
        local py = self.player.screenY
        -- Центрируем спрайт в клетке: центр спрайта = центр клетки
        local drawX = px - (self.player.width - TILE_SIZE) / 2
        local drawY = py - (self.player.height - TILE_SIZE) / 2
        
        -- HP бар над персонажем
        self.player:drawHpBar(drawX, drawY, self.player.width)
        
        -- Рисуем спрайт персонажа
        love.graphics.setColor(1, 1, 1)
        self:drawSprite(
            self.player.spriteRow, 
            self.player.spriteCol, 
            drawX, drawY, 
            self.player.width, 
            self.player.height
        )

        -- Временная отрисовка хитбокса
        if self.debugHitbox then
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.rectangle("line", drawX, drawY, self.player.width, self.player.height)
            love.graphics.setColor(1, 1, 1)
        end
    end
    
    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

function Game:keypressed(key, scancode, isrepeat)
    -- Обработка других клавиш (не движения)
    if key == "escape" then
        love.event.quit()
    elseif key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
        -- F11 или Alt+Enter для полноэкранного режима
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    end
end

function Game:mousepressed(x, y, button)
    if not self.player then return end
    
    if button == 1 then -- Левая кнопка мыши
        self:setTargetPosition(x, y)
    elseif button == 2 then -- Правая кнопка мыши (клик по месту)
        self:setTargetPosition(x, y)
    end
end

function Game:mousemoved(x, y, dx, dy)
    if not self.player then return end
    
    -- Если зажата правая кнопка мыши - обновляем цель
    if love.mouse.isDown(2) then -- Правая кнопка мыши
        self:setTargetPosition(x, y)
    end
end

function Game:setTargetPosition(targetX, targetY)
    if not self.player then return end
    
    -- Конвертируем экранные координаты с учетом камеры в игровые координаты
    local worldX = targetX + self.cameraX
    local worldY = targetY + self.cameraY
    local scaledTileSize = TILE_SIZE
    -- Округляем до ближайшей клетки
    local gameX = math.floor(worldX / scaledTileSize)
    local gameY = math.floor(worldY / scaledTileSize)
    
    -- Проверяем что цель в пределах карты
    if gameX < 0 or gameX >= self.mapWidth or gameY < 0 or gameY >= self.mapHeight then
        return
    end
    
    -- Устанавливаем целевую позицию и считаем путь (A*)
    self.player.targetGameX = gameX
    self.player.targetGameY = gameY
    self.path = self:findPath(self.player.x, self.player.y, gameX, gameY, self.allowDiagonal)
    self.pathIndex = self.path and 1 or nil
end

-- Проверка проходимости клетки (с учетом размера хитбокса моба)
function Game:isWalkable(x, y, mob)
    if not mob or not mob.width or not mob.height then
        -- Обычная проверка для 1 тайла
        if x < 0 or x >= self.mapWidth or y < 0 or y >= self.mapHeight then
            return false
        end
        return true
    end
    
    -- Для больших мобов: считаем сколько тайлов занимает хитбокс
    local tilesW = math.ceil(mob.width / TILE_SIZE)
    local tilesH = math.ceil(mob.height / TILE_SIZE)
    
    -- Хитбокс центрирован на тайле (x, y) и занимает tilesW x tilesH тайлов
    -- Для 96x96 (3 тайла): центр на (x,y), значит занимает от (x-1) до (x+1)
    local offsetX = math.floor((tilesW - 1) / 2)
    local offsetY = math.floor((tilesH - 1) / 2)
    
    local startX = x - offsetX
    local startY = y - offsetY
    local endX = startX + tilesW - 1
    local endY = startY + tilesH - 1
    
    -- Проверяем что весь хитбокс в пределах карты
    if startX < 0 or endX >= self.mapWidth or startY < 0 or endY >= self.mapHeight then
        return false
    end
    
    -- Здесь можно подключить карту, коллайдеры и т.п.
    return true
end

-- Соседи клетки (4- или 8-направлений)
function Game:getNeighbors(x, y, allowDiagonal)
    local neighbors = {}
    -- 4 направления
    local dirs4 = {
        {x =  1, y =  0}, {x = -1, y =  0},
        {x =  0, y =  1}, {x =  0, y = -1},
    }
    for i = 1, #dirs4 do
        local nx = x + dirs4[i].x
        local ny = y + dirs4[i].y
        if self:isWalkable(nx, ny) then
            neighbors[#neighbors + 1] = {x = nx, y = ny}
        end
    end
    if allowDiagonal then
        local dirs4diag = {
            {x =  1, y =  1}, {x =  1, y = -1},
            {x = -1, y =  1}, {x = -1, y = -1},
        }
        for i = 1, #dirs4diag do
            local nx = x + dirs4diag[i].x
            local ny = y + dirs4diag[i].y
            if self:isWalkable(nx, ny) then
                neighbors[#neighbors + 1] = {x = nx, y = ny}
            end
        end
    end
    return neighbors
end

-- Ключ для словаря
local function key(x, y)
    return tostring(x) .. "," .. tostring(y)
end

-- Эвристика для 8-направленного движения: расстояние Чебышёва (admissible при стоимости шага = 1)
local function chebyshevDistance(ax, ay, bx, by)
    local dx = math.abs(ax - bx)
    local dy = math.abs(ay - by)
    return math.max(dx, dy)
end

-- Восстановление пути из cameFrom
function Game:reconstructPath(cameFrom, currentKey)
    local path = {}
    while currentKey do
        local cx, cy = currentKey:match("^(%-?%d+),(%-?%d+)$")
        cx = tonumber(cx)
        cy = tonumber(cy)
        table.insert(path, 1, {x = cx, y = cy})
        currentKey = cameFrom[currentKey]
    end
    return path
end

-- Поиск пути A*
function Game:findPath(sx, sy, tx, ty, allowDiagonal)
    if sx == tx and sy == ty then return nil end
    
    -- Проверяем что цель проходима
    if not self:isWalkable(tx, ty) then
        return nil
    end
    
    local startKey = key(sx, sy)
    local goalKey = key(tx, ty)
    
    local openSet = {[startKey] = true}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {[startKey] = 0}
    local fScore = {[startKey] = chebyshevDistance(sx, sy, tx, ty)}
    
    local iterations = 0
    local maxIterations = 10000 -- Защита от зацикливания
    
    while next(openSet) do
        iterations = iterations + 1
        if iterations > maxIterations then
            return nil -- Защита от бесконечного цикла
        end
        
        -- Выбираем узел с минимальным fScore из openSet
        local currentKey, currentF = nil, math.huge
        for k, _ in pairs(openSet) do
            local f = fScore[k] or math.huge
            if f < currentF then
                currentF = f
                currentKey = k
            end
        end
        
        if not currentKey then
            return nil
        end
        
        if currentKey == goalKey then
            -- Восстанавливаем путь и убираем стартовую клетку
            local fullPath = self:reconstructPath(cameFrom, currentKey)
            if #fullPath > 0 and fullPath[1].x == sx and fullPath[1].y == sy then
                table.remove(fullPath, 1)
            end
            return #fullPath > 0 and fullPath or nil
        end
        
        openSet[currentKey] = nil
        closedSet[currentKey] = true
        
        local cx, cy = currentKey:match("^(%-?%d+),(%-?%d+)$")
        cx = tonumber(cx)
        cy = tonumber(cy)
        
        local neighbors = self:getNeighbors(cx, cy, allowDiagonal)
        for i = 1, #neighbors do
            local nx = neighbors[i].x
            local ny = neighbors[i].y
            local nKey = key(nx, ny)
            
            if not closedSet[nKey] then
                local tentativeG = (gScore[currentKey] or 0) + 1
                
                if not gScore[nKey] or tentativeG < gScore[nKey] then
                    cameFrom[nKey] = currentKey
                    gScore[nKey] = tentativeG
                    fScore[nKey] = tentativeG + chebyshevDistance(nx, ny, tx, ty)
                    
                    if not openSet[nKey] then
                        openSet[nKey] = true
                    end
                end
            end
        end
    end
    
    return nil -- Путь не найден
end


return Game
