-- map.lua
-- Map rendering and boundary checking
-- Renders map once to a Canvas for performance
-- Public API: Map.new(), map:build(), map:draw(), map:isInBounds(x, y, radius)
-- Dependencies: constants.lua, assets.lua

local Constants = require("src.constants")

local Map = {}
Map.__index = Map

-- === CONSTRUCTOR ===

function Map.new()
    local self = setmetatable({}, Map)
    
    self.width = Constants.MAP_WIDTH
    self.height = Constants.MAP_HEIGHT
    self.boundaryWidth = Constants.MAP_BOUNDARY_WIDTH
    
    self.canvas = nil
    self.built = false
    
    return self
end

-- === BUILD ===

-- Build map canvas once (call after assets are loaded)
function Map:build(assets)
    -- Create canvas
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    
    -- Render to canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    
    -- Draw map texture (background)
    if assets then
        local mapTexture = assets.getImage("mapTexture")
        if mapTexture then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(mapTexture, 0, 0)
        end
    else
        -- Fallback: simple gradient/color
        love.graphics.setColor(0.15, 0.2, 0.15, 1)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end
    
    -- Draw white boundaries
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(self.boundaryWidth)
    love.graphics.rectangle(
        "line",
        self.boundaryWidth / 2,
        self.boundaryWidth / 2,
        self.width - self.boundaryWidth,
        self.height - self.boundaryWidth
    )
    love.graphics.setLineWidth(1)
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    self.built = true
end

-- === DRAW ===

function Map:draw()
    if not self.built or not self.canvas then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)
end

-- === BOUNDS CHECKING ===

-- Check if position with radius is within map bounds
function Map:isInBounds(x, y, radius)
    radius = radius or 0
    local margin = self.boundaryWidth + radius
    
    return x >= margin and
           x <= self.width - margin and
           y >= margin and
           y <= self.height - margin
end

-- Clamp position to bounds
function Map:clampToBounds(x, y, radius)
    radius = radius or 0
    local margin = self.boundaryWidth + radius
    
    x = math.max(margin, math.min(self.width - margin, x))
    y = math.max(margin, math.min(self.height - margin, y))
    
    return x, y
end

-- Check if entity would collide with boundary after movement
function Map:checkBoundaryCollision(x, y, newX, newY, radius)
    return not self:isInBounds(newX, newY, radius)
end

return Map

