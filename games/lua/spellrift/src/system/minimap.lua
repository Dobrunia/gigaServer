local UIConstants = require("src.ui.ui_constants")

local Minimap = {}
Minimap.__index = Minimap

local MINIMAP_SIZE = 200                    -- Square minimap size
local MINIMAP_PADDING = 10                 -- Distance from screen edge
local MINIMAP_BORDER_WIDTH = 2             -- Border thickness
local MINIMAP_PLAYER_SIZE = 4              -- Player dot size
local MINIMAP_MOB_SIZE = 2                 -- Mob dot size
local MINIMAP_PROJECTILE_SIZE = 1          -- Projectile dot size
local MINIMAP_BACKGROUND_ALPHA = 0.7       -- Background transparency

local MINIMAP_BG = {0.1, 0.1, 0.1, 1}
local MINIMAP_BORDER = {0.2, 0.2, 0.2, 1}
local MINIMAP_MAP_BORDER = {0.3, 0.3, 0.3, 1}
local MINIMAP_PROJECTILE = {0.4, 0.4, 0.4, 1}
local MINIMAP_MOB = {0.5, 0.5, 0.5, 1}
local MINIMAP_PLAYER = {0.6, 0.6, 0.6, 1}

function Minimap.new()
    local self = setmetatable({}, Minimap)
    
    -- Position (top-right corner)
    self.x = 0  -- Will be calculated in draw()
    self.y = MINIMAP_PADDING
    
    -- Size
    self.size = MINIMAP_SIZE
    
    return self
end

-- === DRAW ===

function Minimap:draw(player, mobs, projectiles, camera, assets)
    if not player then return end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Position in top-right corner
    self.x = screenW - self.size - MINIMAP_PADDING
    
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
    Colors.setColor(MINIMAP_BG)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
    
    -- Border
    Colors.setColor(MINIMAP_BORDER)
    love.graphics.setLineWidth(MINIMAP_BORDER_WIDTH)
    love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
    love.graphics.setLineWidth(1)
end

function Minimap:drawMapBoundaries()
    -- Calculate map bounds in minimap coordinates
    local mapX, mapY = self:worldToMinimap(0, 0)
    local mapW, mapH = self:worldToMinimap(Constants.MAP_WIDTH, Constants.MAP_HEIGHT)
    
    -- Draw map boundary
    Colors.setColor(MINIMAP_MAP_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", mapX, mapY, mapW - mapX, mapH - mapY)
end

function Minimap:drawProjectiles(projectiles)
    if not projectiles then return end
    
    Colors.setColor(MINIMAP_PROJECTILE)
    
    for _, proj in ipairs(projectiles) do
        if proj.active and proj.owner == "mob" then  -- Only enemy projectiles
            local px, py = self:worldToMinimap(proj.x, proj.y)
            
            -- Only draw if within minimap bounds
            if self:isPointInMinimap(px, py) then
                love.graphics.circle("fill", px, py, MINIMAP_PROJECTILE_SIZE)
            end
        end
    end
end

function Minimap:drawMobs(mobs, player, camera)
    if not mobs then return end
    
    Colors.setColor(MINIMAP_MOB)
    
    for _, mob in ipairs(mobs) do
        if mob.alive then
            local mx, my = self:worldToMinimap(mob.x, mob.y)
            
            -- Only draw if within minimap bounds
            if self:isPointInMinimap(mx, my) then
                love.graphics.circle("fill", mx, my, MINIMAP_MOB_SIZE)
            end
        end
    end
end

function Minimap:drawPlayer(player, camera)
    if not player or not player.alive then return end
    
    local px, py = self:worldToMinimap(player.x, player.y)
    
    -- Player dot
    Colors.setColor(MINIMAP_PLAYER)
    love.graphics.circle("fill", px, py, MINIMAP_PLAYER_SIZE)
    
    -- Player direction indicator (small line)
    local angle = math.atan2(player.aimY or 0, player.aimX or 0)
    local dirX = px + math.cos(angle) * (MINIMAP_PLAYER_SIZE + 2)
    local dirY = py + math.sin(angle) * (MINIMAP_PLAYER_SIZE + 2)
    
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
