-- main.lua
-- Entry point for LÖVE framework
-- Proxies all LÖVE callbacks to Game module

local Game = require("src.game")

-- Global game instance
local game = nil

function love.load(args)
    -- Seed RNG
    math.randomseed(os.time())
    
    -- Set pixel art filter (no smoothing)
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Create and load game
    game = Game.new()
    game:load()
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if game then
        game:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key)
    if game then
        game:keyreleased(key)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if game then
        game:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if game then
        game:mousereleased(x, y, button)
    end
end

function love.resize(w, h)
    if game then
        game:resize(w, h)
    end
end

function love.gamepadpressed(joystick, button)
    if game and game.input then
        game.input:gamepadpressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    if game and game.input then
        game.input:gamepadreleased(joystick, button)
    end
end

