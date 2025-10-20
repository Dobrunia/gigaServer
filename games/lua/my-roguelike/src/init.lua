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
    
    -- Создаем персонажа
    self.player = Character:new({
        key = "Mage",
        x = 10,
        y = 10
    })
    
    -- Размеры окна
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
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
    
    -- Получаем направление из всех источников ввода
    local dx, dy = self:getInputDirection()
    
    -- Если есть ввод, двигаем персонажа
    if dx ~= 0 or dy ~= 0 then
        -- Округляем до целых для grid-движения
        local gridDx = math.floor(dx + 0.5)
        local gridDy = math.floor(dy + 0.5)
        
        if gridDx ~= 0 or gridDy ~= 0 then
            self.player:move(gridDx, gridDy)
            self.player.targetX = self.player.x * TILE_SIZE
            self.player.targetY = self.player.y * TILE_SIZE
            self.lastMoveTime = currentTime
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
    
    -- Рисуем персонажа
    if self.player then
        local px = self.player.screenX
        local py = self.player.screenY
        
        -- HP бар над персонажем
        self.player:drawHpBar(px, py, self.player.width)
        
        -- Рисуем спрайт персонажа
        love.graphics.setColor(1, 1, 1)
        self:drawSprite(
            self.player.spriteRow, 
            self.player.spriteCol, 
            px, py, 
            self.player.width, 
            self.player.height
        )
    end
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

return Game
