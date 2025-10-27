local StateManager = {}
StateManager.__index = StateManager

function StateManager:init()
    self.currentState = nil
    self.states = {}
end

function StateManager:switch(stateName, ...)
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end
    
    if type(stateName) == "string" then
        self.currentState = self.states[stateName]
    else
        self.currentState = stateName
    end
    
    if self.currentState and self.currentState.enter then
        self.currentState:enter(...)
    end
end

function StateManager:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function StateManager:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

-- Регистрируем состояния
StateManager.states = {
    main_menu = require("src.states.main_menu"),
    hero_select = require("src.states.hero_select"),
    game = require("src.states.game")
}

return StateManager