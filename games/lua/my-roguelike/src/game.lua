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
    self.mode = "menu"  -- menu, char_select, playing, game_over
    self.paused = false
    
    -- Game over stats
    self.finalStats = {
        time = 0,
        kills = 0
    }
    
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
    self.mobsKilled = 0
    
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
    -- Load all configs
    local allHeroes = require("src.config.heroes")
    local allMobs = require("src.config.mobs")
    local allBosses = require("src.config.bosses")
    
    -- TEMPORARY: Limit to 1 hero and 1 mob for testing
    self.heroConfigs = {allHeroes[1]}  -- Only Mage (ranged)
    self.mobConfigs = {allMobs[1]}     -- Only Zombie (melee)
    self.bossConfigs = {}              -- No bosses for now
    
    self.skillConfigs = require("src.config.skills")
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
    elseif self.mode == "game_over" then
        self:updateGameOver(dt)
    end
    
    -- Clear pressed states at the END of frame (after all updates)
    Input.clearPressed()
end

function Game:updateMenu(dt)
    -- Button bounds for "Start Game" button
    local buttonWidth = 300
    local buttonHeight = 60
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = 400
    
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    local isHovering = mx >= buttonX and mx <= buttonX + buttonWidth and
                       my >= buttonY and my <= buttonY + buttonHeight
    
    -- Debug log - check Input state
    if Input.mouse.leftPressed then
        -- print(string.format("[MENU] Mouse leftPressed=true at (%.0f, %.0f), hovering=%s", mx, my, tostring(isHovering)))
    end
    
    if Input.isKeyPressed("space") then
        -- print("[MENU] SPACE isKeyPressed=true")
    end
    
    -- Check for click on button or SPACE key
    if Input.isKeyPressed("space") then
        -- print("[MENU] Starting game via SPACE!")
        self.mode = "char_select"
    elseif Input.mouse.leftPressed and isHovering then
        --  print("[MENU] Starting game via button click!")
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

function Game:updateGameOver(dt)
    -- Restart on SPACE or click
    if Input.isKeyPressed("space") or Input.isKeyPressed("return") or Input.mouse.leftPressed then
        self:startGame()  -- Restart game
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
        -- Trigger game over
        if self.mode == "playing" then
            self.mode = "game_over"
            self.finalStats.time = self.gameTime
            self.finalStats.kills = self.mobsKilled
        end
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
            self.mobsKilled = self.mobsKilled + 1
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
    self.skills:update(dt, self.player, self.mobs, self.projectilePool, self.spatialHash, self.projectiles)
    
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
    
    -- Movement via RMB (right mouse button)
    if Input.mouse.right then
        local worldX, worldY = self.camera:screenToWorld(Input.mouse.x, Input.mouse.y)
        local moveX, moveY = Utils.directionTo(self.player.x, self.player.y, worldX, worldY)
        self.player:setMovementInput(moveX, moveY, dt)
    else
        -- Movement (WASD or gamepad left stick)
        local moveX, moveY = Input.getMoveVector()
        self.player:setMovementInput(moveX, moveY, dt)
    end
    
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
    
    -- Add starting skill with proper initialization
    if self.player.startingSkillData then
        self.player:addSkill(self.player.startingSkillData)
    end
    
    -- Set player sprite from spritesheet
    local spriteIndex = heroData.spriteIndex or Assets.images.player
    self.player.spritesheet = Assets.getSpritesheet("rogues")
    self.player.quad = Assets.getQuad("rogues", spriteIndex)
    self.player.spriteIndex = spriteIndex
    self.player.isPlayer = true
    
    -- DEBUG (can remove later)
    -- print("[GAME] Player sprite setup:")
    -- print("  spriteIndex:", spriteIndex)
    -- print("  spritesheet:", self.player.spritesheet ~= nil)
    -- print("  quad:", self.player.quad ~= nil)
    
    -- Add to spatial hash
    self.spatialHash:insert(self.player)
    
    -- Reset game state
    self.mobs = {}
    self.projectiles = {}
    self.xpDrops = {}
    self.gameTime = 0
    self.mobsKilled = 0
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
    elseif self.mode == "game_over" then
        self:drawGameOver()
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
    
    -- Draw clickable "Start Game" button
    local buttonWidth = 300
    local buttonHeight = 60
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = 400
    
    -- Check if mouse is hovering over button
    local mx, my = love.mouse.getPosition()
    local isHovering = mx >= buttonX and mx <= buttonX + buttonWidth and
                       my >= buttonY and my <= buttonY + buttonHeight
    
    -- Draw button background
    if isHovering then
        love.graphics.setColor(0.3, 0.6, 0.3, 0.8)  -- Green hover
    else
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)  -- Dark background
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 10, 10)
    
    -- Draw button border
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Draw button text
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("START GAME", buttonX, buttonY + 15, buttonWidth, "center")
    
    -- Draw instruction text below
    love.graphics.setFont(Assets.getFont("small"))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Click button or press SPACE", 0, buttonY + 80, love.graphics.getWidth(), "center")
end

function Game:drawCharSelect()
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choose Your Hero", 0, 50, love.graphics.getWidth(), "center")
    
    -- Draw hero cards
    local hero = self.heroConfigs[self.selectedHeroIndex]
    
    if hero then
        local centerX = love.graphics.getWidth() / 2
        local spriteY = 140
        
        -- Draw hero sprite (large)
        local spriteIndex = hero.spriteIndex or Assets.images.player
        local spritesheet = Assets.getSpritesheet("rogues")
        local quad = Assets.getQuad("rogues", spriteIndex)
        
        if spritesheet and quad then
            love.graphics.setColor(1, 1, 1, 1)
            -- Draw sprite at 4x scale (32x32 -> 128x128)
            love.graphics.draw(spritesheet, quad, centerX, spriteY, 0, 4, 4, 16, 16)
        end
        
        -- Draw hero name
        local cardY = 280
        love.graphics.setFont(Assets.getFont("large"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(hero.name, 0, cardY, love.graphics.getWidth(), "center")
        
        -- Draw stats
        love.graphics.setFont(Assets.getFont("default"))
        love.graphics.printf("HP: " .. hero.baseHp .. " (+" .. hero.hpGrowth .. "/lvl)", 0, cardY + 50, love.graphics.getWidth(), "center")
        love.graphics.printf("Armor: " .. hero.baseArmor .. " (+" .. hero.armorGrowth .. "/lvl)", 0, cardY + 70, love.graphics.getWidth(), "center")
        love.graphics.printf("Speed: " .. hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. "/lvl)", 0, cardY + 90, love.graphics.getWidth(), "center")
        love.graphics.printf("Cast Speed: " .. hero.baseCastSpeed .. "x (+" .. hero.castSpeedGrowth .. "/lvl)", 0, cardY + 110, love.graphics.getWidth(), "center")
        
        -- Draw innate ability
        if hero.innateSkill then
            love.graphics.setFont(Assets.getFont("small"))
            love.graphics.setColor(0.8, 0.8, 1, 1)
            love.graphics.printf("Innate: " .. hero.innateSkill.name, 0, cardY + 140, love.graphics.getWidth(), "center")
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.printf(hero.innateSkill.description or "", 0, cardY + 160, love.graphics.getWidth(), "center")
        end
        
        -- Navigation instructions
        love.graphics.setFont(Assets.getFont("default"))
        love.graphics.setColor(0.5, 1, 0.5, 1)
        love.graphics.printf("< LEFT/RIGHT arrows to navigate >", 0, cardY + 200, love.graphics.getWidth(), "center")
        love.graphics.printf("Press SPACE or ENTER to select", 0, cardY + 220, love.graphics.getWidth(), "center")
        
        -- Show hero counter
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf(self.selectedHeroIndex .. " / " .. #self.heroConfigs, 0, cardY + 250, love.graphics.getWidth(), "center")
    end
end

function Game:drawGameOver()
    love.graphics.clear(0.1, 0.05, 0.05, 1)  -- Dark red background
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Title
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.printf("GAME OVER", 0, 150, screenW, "center")
    
    -- Stats
    love.graphics.setFont(Assets.getFont("default"))
    love.graphics.setColor(1, 1, 1, 1)
    
    local statsY = 250
    love.graphics.printf("Time Survived: " .. Utils.formatTime(self.finalStats.time), 0, statsY, screenW, "center")
    love.graphics.printf("Enemies Killed: " .. self.finalStats.kills, 0, statsY + 40, screenW, "center")
    
    -- Restart button
    local buttonW = 300
    local buttonH = 60
    local buttonX = (screenW - buttonW) / 2
    local buttonY = 400
    
    -- Check hover
    local mx, my = love.mouse.getPosition()
    local isHovering = mx >= buttonX and mx <= buttonX + buttonW and
                       my >= buttonY and my <= buttonY + buttonH
    
    -- Button background
    if isHovering then
        love.graphics.setColor(0.4, 0.7, 0.4, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 10, 10)
    
    -- Button border
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Button text
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("RESTART", buttonX, buttonY + 15, buttonW, "center")
    
    -- Instruction
    love.graphics.setFont(Assets.getFont("small"))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Press SPACE or click button to restart", 0, buttonY + 80, screenW, "center")
end

function Game:drawPlaying()
    love.graphics.clear(0, 0, 0, 1)
    
    -- Apply camera
    self.camera:apply()
    
    -- Draw map
    self.map:draw()
    
    -- Draw XP drops
    for _, drop in ipairs(self.xpDrops) do
        local xpIndex = Assets.images.xpDrop
        local spritesheet = Assets.getSpritesheet("items")
        local quad = Assets.getQuad("items", xpIndex)
        
        if spritesheet and quad then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(spritesheet, quad, drop.x, drop.y, 0, 1, 1, 16, 16)
        end
    end
    
    -- Draw mobs
    for _, mob in ipairs(self.mobs) do
        if self.camera:isPointVisible(mob.x, mob.y) then
            mob:draw()
        end
    end
    
    -- Draw projectiles
    for _, proj in ipairs(self.projectiles) do
        local projIndex = proj.owner == "player" and Assets.images.projectilePlayer or Assets.images.projectileMob
        local spritesheet = Assets.getSpritesheet("items")
        local quad = Assets.getQuad("items", projIndex)
        
        if spritesheet and quad then
            love.graphics.setColor(1, 1, 1, 1)
            -- Calculate rotation angle towards movement direction
            local angle = math.atan2(proj.dy, proj.dx)
            -- Draw projectile with rotation
            love.graphics.draw(spritesheet, quad, proj.x, proj.y, angle, 1.5, 1.5, 16, 16)
        else
            -- Fallback: draw as orange circle if sprite not found
            love.graphics.setColor(1, 0.5, 0, 1)
            love.graphics.circle("fill", proj.x, proj.y, 6)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    -- Draw player
    if self.player then
        self.player:draw()
    end
    
    -- Draw hitboxes for debugging
    if Constants.DEBUG_DRAW_HITBOXES then
        love.graphics.setLineWidth(2)
        
        -- Player hitbox (green)
        if self.player then
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.circle("line", self.player.x, self.player.y, self.player.radius)
        end
        
        -- Mob hitboxes (red)
        love.graphics.setColor(1, 0, 0, 0.5)
        for _, mob in ipairs(self.mobs) do
            if self.camera:isPointVisible(mob.x, mob.y) then
                love.graphics.circle("line", mob.x, mob.y, mob.radius)
            end
        end
        
        -- Projectile hitboxes (yellow)
        love.graphics.setColor(1, 1, 0, 0.5)
        for _, proj in ipairs(self.projectiles) do
            love.graphics.circle("line", proj.x, proj.y, proj.radius)
        end
        
        -- XP drop hitboxes (cyan)
        love.graphics.setColor(0, 1, 1, 0.5)
        for _, drop in ipairs(self.xpDrops) do
            love.graphics.circle("line", drop.x, drop.y, drop.radius)
        end
        
        -- Player skill ranges (blue)
        if self.player and self.player.skills then
            love.graphics.setColor(0, 0, 1, 0.3)
            for _, skill in ipairs(self.player.skills) do
                if skill.range then
                    love.graphics.circle("line", self.player.x, self.player.y, skill.range)
                end
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
    end
    
    -- Clear camera
    self.camera:clear()
    
    -- Draw HUD (UI overlay, no camera)
    self:drawHUD()
    
    -- Draw pause screen overlay
    if self.paused then
        self:drawPauseScreen()
    end
end

function Game:drawHUD()
    if not self.player then return end
    
    local stats = self.player:getStats()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Timer at top center
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(Utils.formatTime(self.gameTime), 0, 10, screenW, "center")
    
    -- Stats Card (bottom left)
    local statsCardW = 220
    local statsCardH = 140
    local statsCardX = 20
    local statsCardY = screenH - statsCardH - 20
    
    -- Card background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", statsCardX, statsCardY, statsCardW, statsCardH, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", statsCardX, statsCardY, statsCardW, statsCardH, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Stats content
    love.graphics.setFont(Assets.getFont("default"))
    love.graphics.setColor(1, 1, 1, 1)
    local textX = statsCardX + 10
    local textY = statsCardY + 10
    
    -- Level
    love.graphics.print("Level: " .. stats.level, textX, textY)
    
    -- HP Bar
    textY = textY + 25
    love.graphics.setFont(Assets.getFont("small"))
    love.graphics.print("HP:", textX, textY)
    local hpBarX = textX + 30
    local hpBarW = statsCardW - 50
    local hpBarH = 16
    local hpPercent = math.max(0, math.min(1, stats.hp / stats.maxHp))
    
    -- HP bar background
    love.graphics.setColor(0.2, 0, 0, 0.8)
    love.graphics.rectangle("fill", hpBarX, textY, hpBarW, hpBarH, 3, 3)
    -- HP bar fill
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", hpBarX, textY, hpBarW * hpPercent, hpBarH, 3, 3)
    -- HP text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(math.floor(stats.hp) .. "/" .. math.floor(stats.maxHp), hpBarX, textY + 2, hpBarW, "center")
    
    -- XP Bar
    textY = textY + 25
    love.graphics.print("XP:", textX, textY)
    local xpPercent = math.max(0, math.min(1, stats.xp / stats.xpToNext))
    
    -- XP bar background
    love.graphics.setColor(0, 0, 0.2, 0.8)
    love.graphics.rectangle("fill", hpBarX, textY, hpBarW, hpBarH, 3, 3)
    -- XP bar fill
    love.graphics.setColor(0.3, 0.5, 1, 1)
    love.graphics.rectangle("fill", hpBarX, textY, hpBarW * xpPercent, hpBarH, 3, 3)
    -- XP text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(math.floor(stats.xp) .. "/" .. math.floor(stats.xpToNext), hpBarX, textY + 2, hpBarW, "center")
    
    -- Armor
    textY = textY + 25
    love.graphics.setFont(Assets.getFont("default"))
    love.graphics.print("Armor: " .. math.floor(stats.armor), textX, textY)
    
    -- Speed
    textY = textY + 20
    love.graphics.setFont(Assets.getFont("small"))
    love.graphics.print("Speed: " .. math.floor(stats.speed), textX, textY)
    
    -- Skills Card (bottom right)
    local skillsCardW = 250
    local skillsCardH = 140
    local skillsCardX = screenW - skillsCardW - 20
    local skillsCardY = screenH - skillsCardH - 20
    
    -- Card background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", skillsCardX, skillsCardY, skillsCardW, skillsCardH, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", skillsCardX, skillsCardY, skillsCardW, skillsCardH, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Skills content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Assets.getFont("default"))
    local skillTextX = skillsCardX + 10
    local skillTextY = skillsCardY + 10
    love.graphics.print("Skills:", skillTextX, skillTextY)
    
    skillTextY = skillTextY + 25
    love.graphics.setFont(Assets.getFont("small"))
    
    if #self.player.skills == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("No skills yet", skillTextX, skillTextY)
    else
        for i, skill in ipairs(self.player.skills) do
            local cooldown = skill.cooldownTimer or 0
            local cdPercent = 0
            if skill.cooldown and skill.cooldown > 0 then
                cdPercent = math.max(0, math.min(1, cooldown / skill.cooldown))
            end
            
            -- Skill name
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(skill.name or "Unknown", skillTextX, skillTextY)
            
            -- Cooldown bar (small)
            local cdBarX = skillTextX + 100
            local cdBarW = skillsCardW - 120
            local cdBarH = 12
            
            if cooldown > 0 then
                -- CD bar background
                love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", cdBarX, skillTextY, cdBarW, cdBarH, 2, 2)
                -- CD bar fill
                love.graphics.setColor(1, 0.5, 0, 1)
                love.graphics.rectangle("fill", cdBarX, skillTextY, cdBarW * cdPercent, cdBarH, 2, 2)
                -- CD text
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(string.format("%.1f", cooldown), cdBarX, skillTextY, cdBarW, "center")
            else
                -- Ready indicator
                love.graphics.setColor(0.2, 1, 0.2, 0.8)
                love.graphics.rectangle("fill", cdBarX, skillTextY, cdBarW, cdBarH, 2, 2)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf("READY", cdBarX, skillTextY, cdBarW, "center")
            end
            
            skillTextY = skillTextY + 20
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
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

function Game:drawPauseScreen()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Pause text
    love.graphics.setFont(Assets.getFont("large"))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PAUSED", 0, screenH/2 - 60, screenW, "center")
    
    -- Continue button
    love.graphics.setFont(Assets.getFont("medium"))
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("Press ESC to Continue", 0, screenH/2 + 20, screenW, "center")
end

return Game

