local Input = {}
Input.__index = Input

function Input.new()
    local self = setmetatable({}, Input)
    
    -- Состояние мыши
    self.mouse = {
        x = 0, y = 0,
        leftDown = false,  rightDown = false,
        leftPressed = false, rightPressed = false,
        leftReleased = false, rightReleased = false
    }
    
    -- Состояние клавиатуры
    self.keys = {
        escape = false,
        escapePressed = false
    }
    
    return self
end

function Input:snapshotNow()
    local l = love.mouse.isDown(1)
    local r = love.mouse.isDown(2)
    self.mouse.leftDown = l
    self.mouse.rightDown = r
    self.mouse.leftPressed = false
    self.mouse.rightPressed = false
    self.mouse.leftReleased = false
    self.mouse.rightReleased = false

    local esc = love.keyboard.isDown("escape")
    self.keys.escape = esc
    self.keys.escapePressed = false
end

function Input:update(dt)
    self.mouse.x, self.mouse.y = love.mouse.getPosition()
    
    local prevLeftDown  = self.mouse.leftDown
    local prevRightDown = self.mouse.rightDown

    local leftDown  = love.mouse.isDown(1)
    local rightDown = love.mouse.isDown(2)
    
    self.mouse.leftPressed  = (leftDown  and not prevLeftDown)
    self.mouse.rightPressed = (rightDown and not prevRightDown)
    self.mouse.leftReleased  = (not leftDown)  and prevLeftDown
    self.mouse.rightReleased = (not rightDown) and prevRightDown
    
    self.mouse.leftDown  = leftDown
    self.mouse.rightDown = rightDown
    
    local prevEsc = self.keys.escape
    local escapeDown = love.keyboard.isDown("escape")
    self.keys.escapePressed = (escapeDown and not prevEsc)
    self.keys.escape = escapeDown
end

-- === МЫШЬ ===
function Input:isRightMouseDown()  return self.mouse.rightDown end
function Input:isLeftMouseDown()   return self.mouse.leftDown  end
function Input:isLeftMousePressed() return self.mouse.leftPressed end
function Input:isLeftMouseReleased() return self.mouse.leftReleased end

function Input:getMousePosition()
    return self.mouse.x, self.mouse.y
end

-- экраны -> мир
function Input:getMouseWorldPosition(camera)
    local sx, sy = self:getMousePosition()
    return camera:screenToWorld(sx, sy)
end

-- нормализованное направление из (fromX,fromY) к курсору (экран!)
function Input:getDirectionToMouse(fromX, fromY)
    local mx, my = self:getMousePosition()
    local dx, dy = (mx - fromX), (my - fromY)
    local d = math.sqrt(dx*dx + dy*dy)
    if d > 0 then return dx/d, dy/d end
    return 0, 0
end

-- === КЛАВИАТУРА ===
function Input:isEscapePressed() return self.keys.escapePressed end

return Input