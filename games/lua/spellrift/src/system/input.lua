local Input = {}
Input.__index = Input

function Input.new()
    local self = setmetatable({}, Input)
    
    -- Состояние мыши
    self.mouse = {
        x = 0,
        y = 0,
        leftDown = false,
        rightDown = false,
        leftPressed = false,
        rightPressed = false
    }
    
    -- Состояние клавиатуры
    self.keys = {
        escape = false,
        escapePressed = false
    }
    
    return self
end

function Input:snapshotNow()
    -- Считываем текущее физическое состояние и делаем его "предыдущим",
    -- чтобы на первом update НЕ родились ложные *_Pressed
    local l = love.mouse.isDown(1)
    local r = love.mouse.isDown(2)
    self.mouse.leftDown     = l
    self.mouse.rightDown    = r
    self.mouse.leftPressed  = false
    self.mouse.rightPressed = false

    local esc = love.keyboard.isDown("escape")
    self.keys.escape        = esc
    self.keys.escapePressed = false
end


function Input:update(dt)
    -- Получаем позицию мыши
    self.mouse.x, self.mouse.y = love.mouse.getPosition()
    
    -- Обновляем состояние мыши
    local leftDown = love.mouse.isDown(1)
    local rightDown = love.mouse.isDown(2)
    
    self.mouse.leftPressed = leftDown and not self.mouse.leftDown
    self.mouse.rightPressed = rightDown and not self.mouse.rightDown
    
    self.mouse.leftDown = leftDown
    self.mouse.rightDown = rightDown
    
    -- Обновляем состояние клавиатуры
    local escapeDown = love.keyboard.isDown("escape")
    self.keys.escapePressed = escapeDown and not self.keys.escape
    self.keys.escape = escapeDown
end

-- 1. ПКМ - движение героя к курсору (зажатое)
function Input:isRightMouseDown()
    return self.mouse.rightDown
end

function Input:getMousePosition()
    return self.mouse.x, self.mouse.y
end

-- 2. ЛКМ - заглушка (пока не используется)
function Input:isLeftMousePressed()
    return self.mouse.leftPressed
end

function Input:isLeftMouseDown()
    return self.mouse.leftDown
end

-- 3. ESC - заглушка (пока не используется)
function Input:isEscapePressed()
    return self.keys.escapePressed
end

-- Вспомогательные методы
function Input:getMouseWorldPosition(camera)
    -- Конвертируем экранные координаты в мировые
    local screenX, screenY = self:getMousePosition()
    return camera:screenToWorld(screenX, screenY)
end

function Input:getDirectionToMouse(fromX, fromY)
    -- Получаем направление от точки к курсору
    local mouseX, mouseY = self:getMousePosition()
    local dx = mouseX - fromX
    local dy = mouseY - fromY
    local distance = math.sqrt(dx*dx + dy*dy)
    
    if distance > 0 then
        return dx / distance, dy / distance
    end
    return 0, 0
end

return Input