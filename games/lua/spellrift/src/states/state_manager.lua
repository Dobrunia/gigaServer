local StateManager = {}
StateManager.__index = StateManager

function StateManager.new()
    local self = setmetatable({}, StateManager)
    self.states = {}
    self.currentState = nil
    return self
end

function StateManager:register(name, state)
    -- Передаём ссылку на StateManager внутрь состояния
    if type(state) == "table" then
        state.manager = self
    end
    self.states[name] = state
end

function StateManager:switch(name, ...)
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end

    local state = self.states[name]
    if not state then
        error("State not found: " .. tostring(name))
    end

    self.currentState = state

    if state.enter then
        state:enter(...)
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

return StateManager
