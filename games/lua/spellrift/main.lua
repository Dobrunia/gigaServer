local StateManager = require("src.states.state-manager")

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Инициализируем менеджер состояний
    StateManager:init()

    -- Переходим в игровое состояние
    StateManager:switch("main_menu")
end

function love.update(dt)
    StateManager:update(dt)
end

function love.draw()
    StateManager:draw()
end

function love.resize(w, h)
    -- Передаем изменение размера в текущее состояние
    if StateManager.currentState and StateManager.currentState.resize then
        StateManager.currentState:resize(w, h)
    end
end
