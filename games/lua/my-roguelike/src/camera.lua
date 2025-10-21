-- camera.lua
-- Simple 2D camera with smooth follow and culling support
-- Public API: Camera.new(x, y), camera:update(dt, targetX, targetY), camera:apply(), camera:clear()
-- Dependencies: constants.lua, utils.lua

local Constants = require("src.constants")
local Utils = require("src.utils")

local Camera = {}
Camera.__index = Camera

-- === CONSTRUCTOR ===

function Camera.new(x, y)
    local self = setmetatable({}, Camera)
    
    self.x = x or 0
    self.y = y or 0
    self.prevX = self.x
    self.prevY = self.y
    
    -- Viewport (set on window resize)
    self.viewportWidth = love.graphics.getWidth()
    self.viewportHeight = love.graphics.getHeight()
    
    return self
end

-- === UPDATE ===

function Camera:update(dt, targetX, targetY)
    -- Store previous position for interpolation
    self.prevX = self.x
    self.prevY = self.y
    
    -- Smooth follow using lerp
    self.x = Utils.lerp(self.x, targetX, Constants.CAMERA_LERP_SPEED * dt)
    self.y = Utils.lerp(self.y, targetY, Constants.CAMERA_LERP_SPEED * dt)
    
    -- Clamp camera to map bounds (keep viewport within map)
    local halfW = self.viewportWidth / 2
    local halfH = self.viewportHeight / 2
    
    self.x = Utils.clamp(self.x, halfW, Constants.MAP_WIDTH - halfW)
    self.y = Utils.clamp(self.y, halfH, Constants.MAP_HEIGHT - halfH)
end

-- === TRANSFORM ===

function Camera:apply()
    love.graphics.push()
    love.graphics.translate(
        -self.x + self.viewportWidth / 2,
        -self.y + self.viewportHeight / 2
    )
end

function Camera:clear()
    love.graphics.pop()
end

-- === COORDINATE CONVERSION ===

-- Convert screen coordinates to world coordinates
function Camera:screenToWorld(screenX, screenY)
    local worldX = screenX + self.x - self.viewportWidth / 2
    local worldY = screenY + self.y - self.viewportHeight / 2
    return worldX, worldY
end

-- Convert world coordinates to screen coordinates
function Camera:worldToScreen(worldX, worldY)
    local screenX = worldX - self.x + self.viewportWidth / 2
    local screenY = worldY - self.y + self.viewportHeight / 2
    return screenX, screenY
end

-- === CULLING ===

-- Check if point is visible (with margin for culling optimization)
function Camera:isPointVisible(x, y, margin)
    margin = margin or Constants.CULLING_MARGIN
    local halfW = self.viewportWidth / 2 + margin
    local halfH = self.viewportHeight / 2 + margin
    
    return x > self.x - halfW and x < self.x + halfW and
           y > self.y - halfH and y < self.y + halfH
end

-- Check if AABB is visible
function Camera:isAABBVisible(x, y, w, h, margin)
    margin = margin or Constants.CULLING_MARGIN
    local halfW = self.viewportWidth / 2 + margin
    local halfH = self.viewportHeight / 2 + margin
    
    local camLeft = self.x - halfW
    local camRight = self.x + halfW
    local camTop = self.y - halfH
    local camBottom = self.y + halfH
    
    return x < camRight and x + w > camLeft and
           y < camBottom and y + h > camTop
end

-- === VIEWPORT ===

function Camera:resize(width, height)
    self.viewportWidth = width
    self.viewportHeight = height
end

function Camera:getViewport()
    local halfW = self.viewportWidth / 2
    local halfH = self.viewportHeight / 2
    return self.x - halfW, self.y - halfH, self.viewportWidth, self.viewportHeight
end

return Camera

