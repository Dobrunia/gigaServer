-- input.lua
-- Input abstraction for keyboard and gamepad
-- Handles press, hold, release for both mouse/keyboard and gamepad
-- Public API: Input.update(dt), Input.getMoveVector(), Input.isAimHeld(), Input.isMoveHeld()
-- Dependencies: constants.lua

local Constants = require("src.constants")

local Input = {
    -- Keyboard/mouse state
    keys = {},
    keysPressed = {},
    mouse = {
        x = 0,
        y = 0,
        left = false,
        right = false,
        leftPressed = false,
        rightPressed = false,
        leftHoldTime = 0,
        rightHoldTime = 0
    },
    
    -- Gamepad state
    gamepad = nil,
    gamepadButtons = {},
    gamepadButtonsPressed = {}
}

-- === INITIALIZATION ===

function Input.init()
    -- Detect gamepad
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        Input.gamepad = joysticks[1]
    end
end

-- === UPDATE ===

function Input.update(dt)
    -- Update mouse position
    Input.mouse.x, Input.mouse.y = love.mouse.getPosition()
    
    -- Update hold timers
    if Input.mouse.left then
        Input.mouse.leftHoldTime = Input.mouse.leftHoldTime + dt
    else
        Input.mouse.leftHoldTime = 0
    end
    
    if Input.mouse.right then
        Input.mouse.rightHoldTime = Input.mouse.rightHoldTime + dt
    else
        Input.mouse.rightHoldTime = 0
    end
end

-- Call this at the END of the frame to clear pressed states
function Input.clearPressed()
    Input.keysPressed = {}
    Input.mouse.leftPressed = false
    Input.mouse.rightPressed = false
    Input.gamepadButtonsPressed = {}
end

-- === KEYBOARD ===

function Input.keypressed(key)
    Input.keys[key] = true
    Input.keysPressed[key] = true
    -- Debug: log key presses
    -- print("[INPUT] Key pressed: " .. tostring(key))
end

function Input.keyreleased(key)
    Input.keys[key] = false
end

function Input.isKeyDown(key)
    return Input.keys[key] == true
end

function Input.isKeyPressed(key)
    return Input.keysPressed[key] == true
end

-- === MOUSE ===

function Input.mousepressed(x, y, button)
    -- Debug: log mouse clicks
    -- print(string.format("[INPUT] Mouse pressed: button=%d at (%.0f, %.0f)", button, x, y))
    
    if button == 1 then
        Input.mouse.left = true
        Input.mouse.leftPressed = true
        Input.mouse.leftHoldTime = 0
    elseif button == 2 then
        Input.mouse.right = true
        Input.mouse.rightPressed = true
        Input.mouse.rightHoldTime = 0
    end
end

function Input.mousereleased(x, y, button)
    if button == 1 then
        Input.mouse.left = false
    elseif button == 2 then
        Input.mouse.right = false
    end
end

function Input.getMousePosition()
    return Input.mouse.x, Input.mouse.y
end

function Input.isMouseDown(button)
    if button == 1 then
        return Input.mouse.left
    elseif button == 2 then
        return Input.mouse.right
    end
    return false
end

-- === GAMEPAD ===

function Input.gamepadpressed(joystick, button)
    if joystick == Input.gamepad then
        Input.gamepadButtons[button] = true
        Input.gamepadButtonsPressed[button] = true
    end
end

function Input.gamepadreleased(joystick, button)
    if joystick == Input.gamepad then
        Input.gamepadButtons[button] = false
    end
end

function Input.isGamepadButtonDown(button)
    return Input.gamepadButtons[button] == true
end

function Input.getGamepadAxis(axis)
    if not Input.gamepad then return 0 end
    local value = Input.gamepad:getAxis(axis)
    if math.abs(value) < Constants.GAMEPAD_DEADZONE then
        return 0
    end
    return value
end

-- === HIGH-LEVEL API ===

-- Get movement vector from keyboard (WASD/Arrows) or right stick
function Input.getMoveVector()
    local x, y = 0, 0
    
    -- Keyboard
    if Input.isKeyDown("w") or Input.isKeyDown("up") then y = y - 1 end
    if Input.isKeyDown("s") or Input.isKeyDown("down") then y = y + 1 end
    if Input.isKeyDown("a") or Input.isKeyDown("left") then x = x - 1 end
    if Input.isKeyDown("d") or Input.isKeyDown("right") then x = x + 1 end
    
    -- Gamepad right stick (or left stick if preferred)
    if Input.gamepad then
        local gx = Input.getGamepadAxis(1)  -- Left stick X
        local gy = Input.getGamepadAxis(2)  -- Left stick Y
        if math.abs(gx) > 0 or math.abs(gy) > 0 then
            x, y = gx, gy
        end
    end
    
    -- Normalize if diagonal
    local len = math.sqrt(x * x + y * y)
    if len > 1 then
        x, y = x / len, y / len
    end
    
    return x, y
end

-- Check if player is holding aim (LMB or right stick)
function Input.isAimHeld()
    -- Mouse left button held
    if Input.mouse.left and Input.mouse.leftHoldTime > Constants.HOLD_THRESHOLD then
        return true
    end
    
    -- Gamepad right stick (axis 3, 4)
    if Input.gamepad then
        local rx = Input.getGamepadAxis(3)
        local ry = Input.getGamepadAxis(4)
        if math.abs(rx) > 0 or math.abs(ry) > 0 then
            return true
        end
    end
    
    return false
end

-- Get aim direction (from mouse or right stick)
function Input.getAimDirection(playerX, playerY)
    -- Gamepad right stick has priority
    if Input.gamepad then
        local rx = Input.getGamepadAxis(3)
        local ry = Input.getGamepadAxis(4)
        if math.abs(rx) > 0 or math.abs(ry) > 0 then
            return rx, ry
        end
    end
    
    -- Mouse direction from player
    local mx, my = Input.getMousePosition()
    -- TODO: Convert screen coords to world coords (need camera)
    -- For now, return normalized direction
    local dx, dy = mx - playerX, my - playerY
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        return dx / len, dy / len
    end
    
    return 0, 0
end

-- Check if player is holding move command (RMB or left stick)
-- Note: in ТЗ, movement is on right stick or RMB, but we'll check both
function Input.isMoveHeld()
    -- Mouse right button held
    if Input.mouse.right and Input.mouse.rightHoldTime > Constants.HOLD_THRESHOLD then
        return true
    end
    
    -- Movement vector present
    local x, y = Input.getMoveVector()
    return x ~= 0 or y ~= 0
end

return Input

