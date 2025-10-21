-- camera.lua
-- Simple 2D camera with smooth follow, zoom and culling support
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
    
    -- Scale (zoom level). 1 = normal, >1 = zoom in, <1 = zoom out
    self.scale = 1.5  -- example: +0.5 zoom
    
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
    -- IMPORTANT: use viewport size in WORLD coordinates (i.e. divided by scale)
    local halfW_world = (self.viewportWidth / self.scale) / 2
    local halfH_world = (self.viewportHeight / self.scale) / 2
    
    self.x = Utils.clamp(self.x, halfW_world, Constants.MAP_WIDTH - halfW_world)
    self.y = Utils.clamp(self.y, halfH_world, Constants.MAP_HEIGHT - halfH_world)
end

-- === TRANSFORM ===

function Camera:apply()
    -- We want the camera world point (self.x, self.y) to appear at the center of the viewport
    -- and to apply scaling around the center. Sequence:
    -- 1) translate to screen center
    -- 2) scale
    -- 3) translate by -camera position (world -> camera-space)
    love.graphics.push()
    -- move origin to center of screen
    love.graphics.translate(self.viewportWidth * 0.5, self.viewportHeight * 0.5)
    -- apply scale (zoom)
    love.graphics.scale(self.scale, self.scale)
    -- move world so that camera position is at origin
    love.graphics.translate(-self.x, -self.y)
end

function Camera:clear()
    love.graphics.pop()
end

-- === COORDINATE CONVERSION ===

-- Convert screen coordinates to world coordinates (considering scale & center origin)
function Camera:screenToWorld(screenX, screenY)
    -- inverse of apply():
    -- step1: move origin to center -> (screenX - vw/2, screenY - vh/2)
    -- step2: un-scale -> / scale
    -- step3: add camera position -> + self.x, + self.y
    local worldX = (screenX - self.viewportWidth * 0.5) / self.scale + self.x
    local worldY = (screenY - self.viewportHeight * 0.5) / self.scale + self.y
    return worldX, worldY
end

-- Convert world coordinates to screen coordinates (considering scale & center origin)
function Camera:worldToScreen(worldX, worldY)
    local screenX = (worldX - self.x) * self.scale + self.viewportWidth * 0.5
    local screenY = (worldY - self.y) * self.scale + self.viewportHeight * 0.5
    return screenX, screenY
end

-- === CULLING ===

-- Check if point is visible (with margin for culling optimization)
function Camera:isPointVisible(x, y, margin)
    margin = margin or Constants.CULLING_MARGIN
    -- viewport half-sizes in world coords
    local halfW = (self.viewportWidth / self.scale) / 2 + margin
    local halfH = (self.viewportHeight / self.scale) / 2 + margin
    
    return x > self.x - halfW and x < self.x + halfW and
           y > self.y - halfH and y < self.y + halfH
end

-- Check if AABB is visible
function Camera:isAABBVisible(x, y, w, h, margin)
    margin = margin or Constants.CULLING_MARGIN
    local halfW = (self.viewportWidth / self.scale) / 2 + margin
    local halfH = (self.viewportHeight / self.scale) / 2 + margin
    
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

-- Returns viewport in WORLD coordinates: x, y, w, h
function Camera:getViewport()
    local worldW = self.viewportWidth / self.scale
    local worldH = self.viewportHeight / self.scale
    local halfW = worldW / 2
    local halfH = worldH / 2
    return self.x - halfW, self.y - halfH, worldW, worldH
end

return Camera