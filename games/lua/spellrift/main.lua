local StateManager = require("src.states.state-manager")
local Game = require("src.states.game")

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Инициализируем менеджер состояний
    StateManager:init()

    -- Переходим в игровое состояние
    StateManager:switch(Game)
end

function love.update(dt)
end

function love.draw()
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
end

function love.resize(w, h)
end

function love.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
end

