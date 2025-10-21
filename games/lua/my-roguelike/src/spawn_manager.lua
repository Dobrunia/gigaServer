-- spawn_manager.lua
-- Manages spawning of mobs, bosses, and XP drops
-- Public API: SpawnManager.new(map, spatialHash), manager:update(dt, player, mobs, xpDrops), manager:spawnMob(mobData, level)
-- Dependencies: constants.lua, utils.lua, entity/mob.lua, config/mobs.lua, config/bosses.lua

local Constants = require("src.constants")
local Utils = require("src.utils")
local Mob = require("src.entity.mob")

local SpawnManager = {}
SpawnManager.__index = SpawnManager

-- === CONSTRUCTOR ===

function SpawnManager.new(map, spatialHash)
    local self = setmetatable({}, SpawnManager)
    
    self.map = map
    self.spatialHash = spatialHash
    
    -- Timers
    self.mobSpawnTimer = 0
    self.bossSpawnTimer = 0
    self.gameTime = 0
    
    -- Mob level (increases over time)
    self.currentMobLevel = 1
    self.mobLevelTimer = 0
    
    return self
end

-- === UPDATE ===

function SpawnManager:update(dt, player, mobs, xpDrops, mobConfigs, bossConfigs)
    self.gameTime = self.gameTime + dt
    
    -- Update mob level based on game time
    self.mobLevelTimer = self.mobLevelTimer + dt
    if self.mobLevelTimer >= Constants.MOB_LEVEL_UP_INTERVAL then
        self.currentMobLevel = self.currentMobLevel + 1
        self.mobLevelTimer = 0
        Utils.log("Mob level increased to " .. self.currentMobLevel)
    end
    
    -- Spawn mobs
    self.mobSpawnTimer = self.mobSpawnTimer + dt
    if self.mobSpawnTimer >= Constants.MOB_SPAWN_INTERVAL then
        self:trySpawnMob(player, mobs, mobConfigs)
        self.mobSpawnTimer = 0
    end
    
    -- Spawn boss
    self.bossSpawnTimer = self.bossSpawnTimer + dt
    if self.bossSpawnTimer >= Constants.BOSS_SPAWN_INTERVAL then
        self:spawnBoss(player, mobs, bossConfigs)
        self.bossSpawnTimer = 0
    end
end

-- === MOB SPAWNING ===

function SpawnManager:trySpawnMob(player, mobs, mobConfigs)
    if not player or not player.alive then return end
    if not mobConfigs or #mobConfigs == 0 then return end
    
    -- Pick random mob type
    local mobData = Utils.randomChoice(mobConfigs)
    
    -- Find spawn position (ring around player)
    local spawnX, spawnY = Utils.randomPointInRing(
        player.x,
        player.y,
        Constants.MOB_SPAWN_MIN_DISTANCE,
        Constants.MOB_SPAWN_MAX_DISTANCE
    )
    
    -- Clamp to map bounds
    spawnX, spawnY = self.map:clampToBounds(spawnX, spawnY, Constants.MOB_HITBOX_RADIUS)
    
    -- Create mob
    local mob = Mob.new(spawnX, spawnY, mobData, self.currentMobLevel)
    table.insert(mobs, mob)
    
    -- Add to spatial hash
    if self.spatialHash then
        self.spatialHash:insert(mob)
    end
    
    return mob
end

-- === BOSS SPAWNING ===

function SpawnManager:spawnBoss(player, mobs, bossConfigs)
    if not player or not player.alive then return end
    if not bossConfigs or #bossConfigs == 0 then return end
    
    Utils.log("Boss spawning!")
    
    -- Pick random boss
    local bossData = Utils.randomChoice(bossConfigs)
    
    -- Spawn near player
    local spawnX, spawnY = Utils.randomPointInRing(
        player.x,
        player.y,
        Constants.MOB_SPAWN_MIN_DISTANCE,
        Constants.MOB_SPAWN_MIN_DISTANCE + 100
    )
    
    spawnX, spawnY = self.map:clampToBounds(spawnX, spawnY, Constants.MOB_HITBOX_RADIUS * 2)
    
    -- Create boss (using Mob class with boss data)
    local boss = Mob.new(spawnX, spawnY, bossData, self.currentMobLevel + 5)
    boss.isBoss = true
    table.insert(mobs, boss)
    
    if self.spatialHash then
        self.spatialHash:insert(boss)
    end
    
    return boss
end

-- === XP DROP ===

function SpawnManager:spawnXPDrop(x, y, amount, xpDrops)
    local drop = {
        x = x,
        y = y,
        amount = amount,
        lifetime = Constants.XP_DROP_LIFETIME,
        timer = 0,
        active = true,
        radius = Constants.XP_DROP_SPRITE_SIZE / 2
    }
    
    table.insert(xpDrops, drop)
    
    if self.spatialHash then
        self.spatialHash:insert(drop)
    end
    
    return drop
end

-- === CLEANUP ===

function SpawnManager:reset()
    self.mobSpawnTimer = 0
    self.bossSpawnTimer = 0
    self.gameTime = 0
    self.currentMobLevel = 1
    self.mobLevelTimer = 0
end

return SpawnManager

