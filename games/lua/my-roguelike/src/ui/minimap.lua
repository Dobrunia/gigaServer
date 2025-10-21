-- minimap.lua
-- Minimap system showing player, enemies, and map boundaries
-- Public API: Minimap.new(), minimap:draw(player, mobs, projectiles, camera, assets)
-- Dependencies: constants.lua, utils.lua, colors.lua

local Constants = require("src.constants")
local Utils = require("src.utils")
local Colors = require("src.ui.colors")

local Minimap = {}
Minimap.__index = Minimap

-- === CONSTRUCTOR ===

function Minimap.new()
    local self = setmetatable({}, Minimap)
    
    -- Position (top-right corner)
    self.x = 0  -- Will be calculated in draw()
    self.y = Constants.MINIMAP_PADDING
    
    -- Size
    self.size = Constants.MINIMAP_SIZE
    
    return self
end

-- === DRAW ===

function Minimap:draw(player, mobs, projectiles, camera, assets)
    if not player then return end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Position in top-right corner
    self.x = screenW - self.size - Constants.MINIMAP_PADDING
    
    -- Save current graphics state
    love.graphics.push()
    
    -- Draw background with border
    self:drawBackground()
    
    -- Draw map boundaries
    self:drawMapBoundaries()
    
    -- Draw projectiles (enemy projectiles only)
    self:drawProjectiles(projectiles)
    
    -- Draw mobs
    self:drawMobs(mobs, player, camera)
    
    -- Draw player (always on top)
    self:drawPlayer(player, camera)
    
    -- Restore graphics state
    love.graphics.pop()
end

function Minimap:drawBackground()
    -- Background
    Colors.setColor(Colors.MINIMAP_BG)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
    
    -- Border
    Colors.setColor(Colors.MINIMAP_BORDER)
    love.graphics.setLineWidth(Constants.MINIMAP_BORDER_WIDTH)
    love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
    love.graphics.setLineWidth(1)
end

function Minimap:drawMapBoundaries()
    -- Calculate map bounds in minimap coordinates
    local mapX, mapY = self:worldToMinimap(0, 0)
    local mapW, mapH = self:worldToMinimap(Constants.MAP_WIDTH, Constants.MAP_HEIGHT)
    
    -- Draw map boundary
    Colors.setColor(Colors.MINIMAP_MAP_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", mapX, mapY, mapW - mapX, mapH - mapY)
end

function Minimap:drawProjectiles(projectiles)
    if not projectiles then return end
    
    Colors.setColor(Colors.MINIMAP_PROJECTILE)
    
    for _, proj in ipairs(projectiles) do
        if proj.active and proj.owner == "mob" then  -- Only enemy projectiles
            local px, py = self:worldToMinimap(proj.x, proj.y)
            
            -- Only draw if within minimap bounds
            if self:isPointInMinimap(px, py) then
                love.graphics.circle("fill", px, py, Constants.MINIMAP_PROJECTILE_SIZE)
            end
        end
    end
end

function Minimap:drawMobs(mobs, player, camera)
    if not mobs then return end
    
    Colors.setColor(Colors.MINIMAP_MOB)
    
    for _, mob in ipairs(mobs) do
        if mob.alive then
            local mx, my = self:worldToMinimap(mob.x, mob.y)
            
            -- Only draw if within minimap bounds
            if self:isPointInMinimap(mx, my) then
                love.graphics.circle("fill", mx, my, Constants.MINIMAP_MOB_SIZE)
            end
        end
    end
end

function Minimap:drawPlayer(player, camera)
    if not player or not player.alive then return end
    
    local px, py = self:worldToMinimap(player.x, player.y)
    
    -- Player dot
    Colors.setColor(Colors.MINIMAP_PLAYER)
    love.graphics.circle("fill", px, py, Constants.MINIMAP_PLAYER_SIZE)
    
    -- Player direction indicator (small line)
    local angle = math.atan2(player.aimY or 0, player.aimX or 0)
    local dirX = px + math.cos(angle) * (Constants.MINIMAP_PLAYER_SIZE + 2)
    local dirY = py + math.sin(angle) * (Constants.MINIMAP_PLAYER_SIZE + 2)
    
    love.graphics.setLineWidth(2)
    love.graphics.line(px, py, dirX, dirY)
    love.graphics.setLineWidth(1)
end

-- === COORDINATE CONVERSION ===

-- Convert world coordinates to minimap coordinates
function Minimap:worldToMinimap(worldX, worldY)
    -- Scale world coordinates to minimap size
    local scaleX = self.size / Constants.MAP_WIDTH
    local scaleY = self.size / Constants.MAP_HEIGHT
    
    local minimapX = self.x + worldX * scaleX
    local minimapY = self.y + worldY * scaleY
    
    return minimapX, minimapY
end

-- Check if point is within minimap bounds
function Minimap:isPointInMinimap(x, y)
    return x >= self.x and x <= self.x + self.size and
           y >= self.y and y <= self.y + self.size
end

-- === UTILITY ===

-- Get minimap bounds in world coordinates
function Minimap:getWorldBounds()
    local worldScaleX = Constants.MAP_WIDTH / self.size
    local worldScaleY = Constants.MAP_HEIGHT / self.size
    
    return {
        left = 0,
        top = 0,
        right = Constants.MAP_WIDTH,
        bottom = Constants.MAP_HEIGHT,
        scaleX = worldScaleX,
        scaleY = worldScaleY
    }
end

return Minimap
