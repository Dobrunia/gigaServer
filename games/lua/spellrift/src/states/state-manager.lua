local StateManager = {}
StateManager.__index = StateManager

function StateManager.new()
    local self = setmetatable({}, StateManager)
    self.current = nil
    return self
end

function StateManager:switch(newState, ...)
    if self.current and self.current.exit then
        self.current:exit()
    end
    self.current = newState
    if self.current.enter then
        self.current:enter(...)
    end
end

function StateManager:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function StateManager:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

return StateManager
