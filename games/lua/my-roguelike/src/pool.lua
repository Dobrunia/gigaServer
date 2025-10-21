-- pool.lua
-- Generic object pooling to reduce GC pressure
-- Public API: Pool.new(createFn, resetFn, initialSize), pool:acquire(), pool:release(obj)
-- Dependencies: none

local Pool = {}
Pool.__index = Pool

-- === CONSTRUCTOR ===

-- createFn: function that creates a new object
-- resetFn: function that resets an object to default state
-- initialSize: number of objects to pre-allocate
function Pool.new(createFn, resetFn, initialSize)
    local self = setmetatable({}, Pool)
    
    self.createFn = createFn
    self.resetFn = resetFn
    self.available = {}
    self.active = {}
    
    -- Pre-allocate objects
    initialSize = initialSize or 0
    for i = 1, initialSize do
        local obj = createFn()
        table.insert(self.available, obj)
    end
    
    return self
end

-- === ACQUIRE / RELEASE ===

function Pool:acquire()
    local obj
    
    if #self.available > 0 then
        -- Reuse available object
        obj = table.remove(self.available)
    else
        -- Create new object if pool is empty
        obj = self.createFn()
    end
    
    self.active[obj] = true
    return obj
end

function Pool:release(obj)
    if not self.active[obj] then
        -- Object not from this pool or already released
        return false
    end
    
    -- Reset object state
    if self.resetFn then
        self.resetFn(obj)
    end
    
    -- Move from active to available
    self.active[obj] = nil
    table.insert(self.available, obj)
    
    return true
end

-- Release all active objects
function Pool:releaseAll()
    for obj in pairs(self.active) do
        if self.resetFn then
            self.resetFn(obj)
        end
        table.insert(self.available, obj)
    end
    self.active = {}
end

-- === STATS ===

function Pool:getActiveCount()
    local count = 0
    for _ in pairs(self.active) do
        count = count + 1
    end
    return count
end

function Pool:getAvailableCount()
    return #self.available
end

function Pool:getTotalCount()
    return self:getActiveCount() + self:getAvailableCount()
end

-- === CLEAR ===

function Pool:clear()
    self.available = {}
    self.active = {}
end

return Pool

