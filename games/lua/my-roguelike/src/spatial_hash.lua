-- spatial_hash.lua
-- Uniform grid spatial partitioning for fast neighbor queries
-- Public API: SpatialHash.new(cellSize), hash:insert(entity), hash:remove(entity), hash:update(entity), hash:queryNearby(x, y, radius)
-- Dependencies: constants.lua

local Constants = require("src.constants")

local SpatialHash = {}
SpatialHash.__index = SpatialHash

-- === CONSTRUCTOR ===

function SpatialHash.new(cellSize)
    local self = setmetatable({}, SpatialHash)
    
    self.cellSize = cellSize or Constants.SPATIAL_CELL_SIZE
    self.grid = {}  -- grid[cellKey] = { entity1, entity2, ... }
    self.entityCells = {}  -- entityCells[entity] = { cellKey1, cellKey2, ... }
    
    return self
end

-- === GRID HELPERS ===

-- Convert world coordinates to cell coordinates
function SpatialHash:worldToCell(x, y)
    return math.floor(x / self.cellSize), math.floor(y / self.cellSize)
end

-- Convert cell coordinates to cell key (string)
function SpatialHash:cellToKey(cx, cy)
    return cx .. "," .. cy
end

-- Get cell key from world position
function SpatialHash:getCellKey(x, y)
    local cx, cy = self:worldToCell(x, y)
    return self:cellToKey(cx, cy)
end

-- Get all cells that an AABB touches
function SpatialHash:getCellsForAABB(x, y, w, h)
    local cells = {}
    local cx1, cy1 = self:worldToCell(x, y)
    local cx2, cy2 = self:worldToCell(x + w, y + h)
    
    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            table.insert(cells, self:cellToKey(cx, cy))
        end
    end
    
    return cells
end

-- Get all cells within radius of a point
function SpatialHash:getCellsInRadius(x, y, radius)
    local cells = {}
    local cx, cy = self:worldToCell(x, y)
    local cellRadius = math.ceil(radius / self.cellSize)
    
    for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
            table.insert(cells, self:cellToKey(cx + dx, cy + dy))
        end
    end
    
    return cells
end

-- === INSERT / REMOVE ===

function SpatialHash:insert(entity)
    if not entity.x or not entity.y then return end
    
    -- Calculate which cells entity occupies
    local cells
    if entity.width and entity.height then
        cells = self:getCellsForAABB(entity.x, entity.y, entity.width, entity.height)
    else
        -- Point entity
        cells = { self:getCellKey(entity.x, entity.y) }
    end
    
    -- Add entity to each cell
    for _, cellKey in ipairs(cells) do
        if not self.grid[cellKey] then
            self.grid[cellKey] = {}
        end
        table.insert(self.grid[cellKey], entity)
    end
    
    -- Remember which cells this entity is in
    self.entityCells[entity] = cells
end

function SpatialHash:remove(entity)
    local cells = self.entityCells[entity]
    if not cells then return end
    
    -- Remove entity from each cell
    for _, cellKey in ipairs(cells) do
        local cell = self.grid[cellKey]
        if cell then
            for i = #cell, 1, -1 do
                if cell[i] == entity then
                    table.remove(cell, i)
                    break
                end
            end
            
            -- Remove empty cells to save memory
            if #cell == 0 then
                self.grid[cellKey] = nil
            end
        end
    end
    
    self.entityCells[entity] = nil
end

function SpatialHash:update(entity)
    -- Simple approach: remove and re-insert
    -- Could be optimized to only update changed cells
    self:remove(entity)
    self:insert(entity)
end

-- === QUERY ===

-- Find all entities near a point (within radius)
function SpatialHash:queryNearby(x, y, radius)
    local cells = self:getCellsInRadius(x, y, radius)
    local found = {}
    local seen = {}  -- Avoid duplicates
    
    for _, cellKey in ipairs(cells) do
        local cell = self.grid[cellKey]
        if cell then
            for _, entity in ipairs(cell) do
                if not seen[entity] then
                    seen[entity] = true
                    -- Distance check (actual distance, not just cell proximity)
                    local dx = entity.x - x
                    local dy = entity.y - y
                    local distSq = dx * dx + dy * dy
                    if distSq <= radius * radius then
                        table.insert(found, entity)
                    end
                end
            end
        end
    end
    
    return found
end

-- Find closest entity to a point (within radius, optional filter function)
function SpatialHash:queryClosest(x, y, radius, filterFn)
    local entities = self:queryNearby(x, y, radius)
    local closest = nil
    local closestDistSq = radius * radius
    
    for _, entity in ipairs(entities) do
        if not filterFn or filterFn(entity) then
            local dx = entity.x - x
            local dy = entity.y - y
            local distSq = dx * dx + dy * dy
            if distSq < closestDistSq then
                closest = entity
                closestDistSq = distSq
            end
        end
    end
    
    return closest
end

-- === CLEAR ===

function SpatialHash:clear()
    self.grid = {}
    self.entityCells = {}
end

-- === DEBUG ===

function SpatialHash:getCellCount()
    local count = 0
    for _ in pairs(self.grid) do
        count = count + 1
    end
    return count
end

function SpatialHash:getEntityCount()
    local count = 0
    for _ in pairs(self.entityCells) do
        count = count + 1
    end
    return count
end

return SpatialHash

