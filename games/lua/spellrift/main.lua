local StateManager = require("src.states.state_manager")
local MainMenu = require("src.states.main_menu")

function love.load()
    stateManager = StateManager.new()

    stateManager:register("main_menu", MainMenu)

    stateManager:switch("main_menu")
end

function love.update(dt)
    stateManager:update(dt)
end

function love.draw()
    stateManager:draw()
end

function love.resize(w, h)
    -- Передаем изменение размера в текущее состояние
    if StateManager.currentState and StateManager.currentState.resize then
        StateManager.currentState:resize(w, h)
    end
end
