-- game.lua
-- Main game state with fixed timestep loop
-- Handles game modes: menu, character select, playing
-- Public API: Game.new(), game:load(), game:update(dt), game:draw()
-- Dependencies: All game systems

local Constants = require("src.constants")
local Utils = require("src.utils")
local Assets = require("src.assets")
local Input = require("src.input")
local Camera = require("src.camera")
local SpatialHash = require("src.spatial_hash")
local Pool = require("src.pool")
local Map = require("src.map")
local Skills = require("src.skills")
local SpawnManager = require("src.spawn_manager")
local Player = require("src.entity.player")
local Projectile = require("src.entity.projectile")

local Game = {}
Game.__index = Game

-- === CONSTRUCTOR ===

function Game.new()
    local self = setmetatable({}, Game)
    
    -- Game state
    self.mode = "menu"  -- menu, char_select, playing
    self.paused = false
    
    -- Fixed timestep
    self.accumulator = 0
    self.fixedDT = Constants.FIXED_DT
    
    -- Systems
    self.camera = nil
    self.map = nil
    self.spatialHash = nil
    self.projectilePool = nil
    self.skills = nil
    self.spawnManager = nil
    
    -- Entities
    self.player = nil
    self.mobs = {}
    self.projectiles = {}  -- Active projectiles from pool
    self.xpDrops = {}
    
    -- Configs (loaded from config files)
    self.heroConfigs = {}
    self.mobConfigs = {}
    self.skillConfigs = {}
    self.bossConfigs = {}
    
    -- UI state
    self.selectedHeroIndex = 1
    self.pendingSkillChoice = nil  -- Table of skills to choose from
    
    -- Timer
    self.gameTime = 0
    
    return self
end

-- === LOAD ===

function Game:load()
    Utils.log("Game loading...")
    
    -- Load assets
    Assets.load()
    
    -- Initialize input
    Input.init()
    
    -- Load configs
    self:loadConfigs()
    
    -- Initialize systems
    self.map = Map.new()
    self.map:build(Assets)
    
    self.camera = Camera.new(Constants.MAP_WIDTH / 2, Constants.MAP_HEIGHT / 2)
    self.spatialHash = SpatialHash.new(Constants.SPATIAL_CELL_SIZE)
    self.skills = Skills.new()
    self.spawnManager = SpawnManager.new(self.map, self.spatialHash)
    
    -- Initialize projectile pool
    self.projectilePool = Pool.new(
        function() return Projectile.new() end,
        function(proj) proj:reset() end,
        Constants.PROJECTILE_POOL_SIZE
    )
    
    Utils.log("Game loaded")
end

function Game:loadConfigs()
    -- Load data-driven configs
    self.heroConfigs = require("src.config.heroes")
    self.mobConfigs = require("src.config.mobs")
    self.skillConfigs = require("src.config.skills")
    self.bossConfigs = require("src.config.bosses")
end

-- === UPDATE ===

function Game:update(dt)
    Input.update(dt)
    
    if self.mode == "menu" then
        self:updateMenu(dt)
    elseif self.mode == "char_select" then
        self:updateCharSelect(dt)
    elseif self.mode == "playing" then
        self:updatePlaying(dt)
    end
end

function Game:updateMenu(dt)
    -- Simple menu: press space or click to go to character select
    if Input.isKeyPressed("space") or Input.mouse.leftPressed then
        self.mode = "char_select"
    end
end

function Game:updateCharSelect(dt)
    -- Navigate with arrow keys, select with space
    if Input.isKeyPressed("left") then
        self.selectedHeroIndex = math.max(1, self.selectedHeroIndex - 1)
    elseif Input.isKeyPressed("right") then
        self.selectedHeroIndex = math.min(#self.heroConfigs, self.selectedHeroIndex + 1)
    elseif Input.isKeyPressed("space") or Input.isKeyPressed("return") then
        self:startGame()
    end
end

function Game:updatePlaying(dt)
    if self.paused then return end
    
    -- Fixed timestep for logic
    self.accumulator = self.accumulator + dt
    
    local steps = 0
    while self.accumulator >= self.fixedDT and steps < Constants.MAX_FRAME_SKIP do
        self:fixedUpdate(self.fixedDT)
        self.accumulator = self.accumulator - self.fixedDT
        steps = steps + 1
    end
    
    -- Camera follows player (smooth, outside fixed step)
    if self.player then
        self.camera:update(dt, self.player.x, self.player.y)
    end
end

-- === FIXED UPDATE ===

function Game:fixedUpdate(dt)
    self.gameTime = self.gameTime + dt
    
    if not self.player or not self.player.alive then
        -- Game over
        return
    end
    
    -- Input
    self:handleInput(dt)
    
    -- Update player
    self.player:update(dt)
    
    -- Keep player in bounds
    local px, py = self.map:clampToBounds(self.player.x, self.player.y, self.player.radius)
    self.player:setPosition(px, py)
    
    -- Update spatial hash for player
    self.spatialHash:update(self.player)
    
    -- Update mobs
    for i = #self.mobs, 1, -1 do
        local mob = self.mobs[i]
        mob:update(dt, self.player, self.spatialHash)
        
        -- Clamp to bounds
        local mx, my = self.map:clampToBounds(mob.x, mob.y, mob.radius)
        mob:setPosition(mx, my)
        
        -- Update spatial hash
        self.spatialHash:update(mob)
        
        -- Check if mob wants to spawn projectile
        if mob.spawnProjectile then
            self:spawnMobProjectile(mob.spawnProjectile)
            mob.spawnProjectile = nil
        end
        
        -- Remove dead mobs
        if not mob.alive then
            self.spatialHash:remove(mob)
            self.spawnManager:spawnXPDrop(mob.x, mob.y, mob:getXPDrop(), self.xpDrops)
            table.remove(self.mobs, i)
        end
    end
    
    -- Update projectiles
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj:update(dt)
        
        if not proj.active then
            -- Return to pool
            self.projectilePool:release(proj)
            table.remove(self.projectiles, i)
        else
            -- Check collision
            if proj.owner == "player" then
                -- Check hit on mobs
                for _, mob in ipairs(self.mobs) do
                    if proj:checkHit(mob) then
                        proj:hit(mob)
                        break
                    end
                end
            elseif proj.owner == "mob" then
                -- Check hit on player
                if proj:checkHit(self.player) then
                    proj:hit(self.player)
                end
            end
        end
    end
    
    -- Update XP drops
    for i = #self.xpDrops, 1, -1 do
        local drop = self.xpDrops[i]
        drop.timer = drop.timer + dt
        
        -- Check pickup
        if self.player:canPickup(drop) then
            self.player:gainXP(drop.amount)
            self.spatialHash:remove(drop)
            table.remove(self.xpDrops, i)
        elseif drop.timer >= drop.lifetime then
            -- Expire
            self.spatialHash:remove(drop)
            table.remove(self.xpDrops, i)
        end
    end
    
    -- Update skills (auto-cast)
    self.skills:update(dt, self.player, self.mobs, self.projectilePool, self.spatialHash)
    
    -- Update spawns
    self.spawnManager:update(dt, self.player, self.mobs, self.xpDrops, self.mobConfigs, self.bossConfigs)
    
    -- Check for level up (show skill choice)
    -- This would trigger UI for skill selection
    -- For now, auto-select first available skill
    if self.player.xp >= self.player.xpToNextLevel then
        -- Will be handled in draw/UI layer
    end
end

-- === INPUT HANDLING ===

function Game:handleInput(dt)
    if not self.player then return end
    
    -- Movement (WASD or gamepad left stick)
    local moveX, moveY = Input.getMoveVector()
    self.player:setMovementInput(moveX, moveY, dt)
    
    -- Aim mode (LMB or gamepad right stick)
    if Input.isAimHeld() then
        local aimX, aimY = Input.getAimDirection(self.player.x, self.player.y)
        -- Convert screen to world if needed (camera)
        if Input.mouse.left then
            local worldX, worldY = self.camera:screenToWorld(Input.mouse.x, Input.mouse.y)
            aimX, aimY = Utils.directionTo(self.player.x, self.player.y, worldX, worldY)
        end
        self.player:setAimDirection(aimX, aimY)
        self.player:setManualAimMode(true)
    else
        self.player:setManualAimMode(false)
    end
end

-- === GAME FLOW ===

function Game:startGame()
    -- Select hero
    local heroData = self.heroConfigs[self.selectedHeroIndex]
    if not heroData then
        Utils.logError("No hero selected")
        return
    end
    
    -- Create player at map center
    self.player = Player.new(Constants.MAP_WIDTH / 2, Constants.MAP_HEIGHT / 2, heroData)
    self.player.sprite = Assets.getImage("player")
    self.player.isPlayer = true
    
    -- Add to spatial hash
    self.spatialHash:insert(self.player)
    
    -- Reset game state
    self.mobs = {}
    self.projectiles = {}
    self.xpDrops = {}
    self.gameTime = 0
    self.spawnManager:reset()
    
    self.mode = "playing"
    Utils.log("Game started with hero: " .. heroData.name)
end

function Game:spawnMobProjectile(projData)
    local proj = self.projectilePool:acquire()
    local dx, dy = Utils.directionTo(projData.x, projData.y, projData.targetX, projData.targetY)
    proj:init(projData.x, projData.y, dx, dy, projData.speed, projData.damage, 500, "mob")
    proj.sprite = Assets.getImage("projectileMob")
    table.insert(self.projectiles, proj)
end

-- === DRAW ===

function Game:draw()
    if self.mode == "menu" then
        self:drawMenu()
    elseif self.mode == "char_select" then
        self:drawCharSelect()
    elseif self.mode == "playing" then
        self:drawPlaying()
    end
    
    -- Debug info
    if Constants.DEBUG_ENABLED then
        self:drawDebug()
    end
end

function Game:drawMenu()
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    local bg = Assets.getImage("menuBg")
    if bg then
        love.graphics.draw(bg, 0, 0)
    end
    
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, 200, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(Assets.getFont("default"))
    love.graphics.printf("Press SPACE to Start", 0, 400, love.graphics.getWidth(), "center")
end

function Game:drawCharSelect()
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Your Hero", 0, 50, love.graphics.getWidth(), "center")
    
    -- Draw hero cards
    local cardY = 200
    local hero = self.heroConfigs[self.selectedHeroIndex]
    
    if hero then
        love.graphics.setFont(Assets.getFont("default"))
        love.graphics.printf(hero.name, 0, cardY, love.graphics.getWidth(), "center")
        love.graphics.printf("HP: " .. hero.baseHp .. " (+" .. hero.hpGrowth .. "/lvl)", 0, cardY + 40, love.graphics.getWidth(), "center")
        love.graphics.printf("Armor: " .. hero.baseArmor .. " (+" .. hero.armorGrowth .. "/lvl)", 0, cardY + 60, love.graphics.getWidth(), "center")
        love.graphics.printf("Speed: " .. hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. "/lvl)", 0, cardY + 80, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(Assets.getFont("small"))
        love.graphics.printf("< LEFT/RIGHT > to navigate, SPACE to select", 0, cardY + 150, love.graphics.getWidth(), "center")
    end
end

function Game:drawPlaying()
    love.graphics.clear(0, 0, 0, 1)
    
    -- Apply camera
    self.camera:apply()
    
    -- Draw map
    self.map:draw()
    
    -- Draw XP drops
    for _, drop in ipairs(self.xpDrops) do
        local sprite = Assets.getImage("xpDrop")
        if sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprite, drop.x, drop.y, 0, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)
        end
    end
    
    -- Draw mobs
    for _, mob in ipairs(self.mobs) do
        if self.camera:isPointVisible(mob.x, mob.y) then
            mob.sprite = mob.mobType == "melee" and Assets.getImage("mobMelee") or Assets.getImage("mobRanged")
            if mob.isBoss then
                mob.sprite = Assets.getImage("boss")
            end
            mob:draw()
        end
    end
    
    -- Draw projectiles
    for _, proj in ipairs(self.projectiles) do
        proj.sprite = proj.owner == "player" and Assets.getImage("projectilePlayer") or Assets.getImage("projectileMob")
        proj:draw()
    end
    
    -- Draw player
    if self.player then
        self.player:draw()
    end
    
    -- Clear camera
    self.camera:clear()
    
    -- Draw HUD (UI overlay, no camera)
    self:drawHUD()
end

function Game:drawHUD()
    if not self.player then return end
    
    local hudBg = Assets.getImage("hudBg")
    if hudBg then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - Constants.HUD_HEIGHT, love.graphics.getWidth(), Constants.HUD_HEIGHT)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Assets.getFont("small"))
    
    local stats = self.player:getStats()
    local x = Constants.HUD_PADDING
    local y = love.graphics.getHeight() - Constants.HUD_HEIGHT + Constants.HUD_PADDING
    
    love.graphics.print("Level: " .. stats.level, x, y)
    love.graphics.print("HP: " .. math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp), x, y + 20)
    love.graphics.print("XP: " .. math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext), x, y + 40)
    love.graphics.print("Armor: " .. math.floor(stats.armor), x, y + 60)
    
    -- Timer
    love.graphics.printf(Utils.formatTime(self.gameTime), 0, 20, love.graphics.getWidth(), "center")
    
    -- Skills
    local skillX = x + 250
    love.graphics.print("Skills:", skillX, y)
    for i, skill in ipairs(self.player.skills) do
        local skillY = y + 20 + (i - 1) * 20
        local cdText = skill.cooldownTimer > 0 and string.format("%.1f", skill.cooldownTimer) or "Ready"
        love.graphics.print(skill.name .. " - " .. cdText, skillX, skillY)
    end
end

function Game:drawDebug()
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setFont(Assets.getFont("debug"))
    
    local fps = love.timer.getFPS()
    local mobCount = #self.mobs
    local projCount = self.projectilePool:getActiveCount()
    local xpCount = #self.xpDrops
    local cells = self.spatialHash:getCellCount()
    
    love.graphics.print("FPS: " .. fps, 10, 10)
    love.graphics.print("Mobs: " .. mobCount, 10, 25)
    love.graphics.print("Projectiles: " .. projCount, 10, 40)
    love.graphics.print("XP: " .. xpCount, 10, 55)
    love.graphics.print("Cells: " .. cells, 10, 70)
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- === EVENTS ===

function Game:keypressed(key, scancode, isrepeat)
    Input.keypressed(key)
    
    if key == "escape" then
        if self.mode == "playing" then
            self.paused = not self.paused
        else
            love.event.quit()
        end
    end
end

function Game:keyreleased(key)
    Input.keyreleased(key)
end

function Game:mousepressed(x, y, button)
    Input.mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
    Input.mousereleased(x, y, button)
end

function Game:resize(w, h)
    if self.camera then
        self.camera:resize(w, h)
    end
end

return Game

