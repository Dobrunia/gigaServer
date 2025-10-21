-- game.lua
-- Main game state with fixed timestep loop
-- Handles game modes: menu, character select, playing
-- Public API: Game.new(), game:load(), game:update(dt), game:draw()
-- Dependencies: All game systems

local Constants = require("src.constants")
local Utils = require("src.utils")
local Assets = require("src.assets")
local Input = require("src.input")
local Colors = require("src.ui.colors")
local Camera = require("src.camera")
local SpatialHash = require("src.spatial_hash")
local Pool = require("src.pool")
local Map = require("src.map")
local Skills = require("src.skills")
local SpawnManager = require("src.spawn_manager")
local Player = require("src.entity.player")
local Projectile = require("src.entity.projectile")
local MainMenu = require("src.ui.main_menu")
local CharacterSelect = require("src.ui.character_select")
local SkillSelect = require("src.ui.skill_select")
local HUD = require("src.ui.hud")
local Minimap = require("src.ui.minimap")

local Game = {}
Game.__index = Game

-- === CONSTRUCTOR ===

function Game.new()
    local self = setmetatable({}, Game)
    
    -- Game state
    self.mode = "menu"  -- menu, char_select, skill_select, playing, game_over
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
    
    -- UI modules
    self.mainMenu = nil
    self.characterSelect = nil
    self.skillSelect = nil
    self.hud = nil
    self.minimap = nil
    
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
    self.startingSkillConfigs = {}
    
    -- UI state
    self.selectedHeroIndex = 1
    self.selectedSkillIndex = 1
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
    
    -- Initialize UI modules
    self.mainMenu = MainMenu.new()
    self.characterSelect = CharacterSelect.new()
    self.skillSelect = SkillSelect.new()
    self.hud = HUD.new()
    self.minimap = Minimap.new()
    
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
    self.startingSkillConfigs = require("src.config.starting_skills")
end

-- === UPDATE ===

function Game:update(dt)
    Input.update(dt)
    
    if self.mode == "menu" then
        self:updateMenu(dt)
    elseif self.mode == "char_select" then
        self:updateCharSelect(dt)
    elseif self.mode == "skill_select" then
        self:updateSkillSelect(dt)
    elseif self.mode == "playing" then
        self:updatePlaying(dt)
    elseif self.mode == "game_over" then
        self:updateGameOver(dt)
    end
    
    -- Clear pressed states at the END of frame (after all updates)
    Input.clearPressed()
end

function Game:updateMenu(dt)
    -- Check for click on button
    if Input.mouse.leftPressed and self.mainMenu:isButtonHovered() then
        self.mode = "char_select"
    end
end

function Game:updateCharSelect(dt)
    -- Handle mouse clicks on hero cards
    if Input.mouse.leftPressed then
        local mx, my = Input.mouse.x, Input.mouse.y
        local clickedHeroIndex = self.characterSelect:handleClick(mx, my, self.heroConfigs)
        if clickedHeroIndex then
            self.selectedHeroIndex = clickedHeroIndex
            -- Proceed to skill selection immediately after clicking hero
            self.mode = "skill_select"
            self.selectedSkillIndex = 1
        end
    end
    
    -- Navigate with arrow keys
    if Input.isKeyPressed("left") then
        self.selectedHeroIndex = math.max(1, self.selectedHeroIndex - 1)
    elseif Input.isKeyPressed("right") then
        self.selectedHeroIndex = math.min(#self.heroConfigs, self.selectedHeroIndex + 1)
    end
end

function Game:updateSkillSelect(dt)
    -- Handle mouse clicks on skill cards
    if Input.mouse.leftPressed then
        local mx, my = Input.mouse.x, Input.mouse.y
        local clickedSkillIndex = self.skillSelect:handleClick(mx, my, self.startingSkillConfigs)
        if clickedSkillIndex then
            self.selectedSkillIndex = clickedSkillIndex
            -- Start game immediately after clicking skill
            self:startGame()
        end
    end
    
    -- Navigate with arrow keys
    if Input.isKeyPressed("left") then
        self.selectedSkillIndex = math.max(1, self.selectedSkillIndex - 1)
    elseif Input.isKeyPressed("right") then
        self.selectedSkillIndex = math.min(#self.startingSkillConfigs, self.selectedSkillIndex + 1)
    end
end

function Game:updateGameOver(dt)
    -- Restart on LMB click
    if Input.mouse.leftPressed then
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
            -- Get mob data for XP drop sprite
            local mobData = nil
            for _, config in ipairs(self.mobConfigs) do
                if config.id == mob.mobId then
                    mobData = config
                    break
                end
            end
            self.spawnManager:spawnXPDrop(mob.x, mob.y, mob:getXPDrop(), self.xpDrops, mobData)
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
    
    -- Select starting skill
    local startingSkill = self.startingSkillConfigs[self.selectedSkillIndex]
    if not startingSkill then
        Utils.logError("No starting skill selected")
        return
    end
    
    -- Create player at map center
    self.player = Player.new(Constants.MAP_WIDTH / 2, Constants.MAP_HEIGHT / 2, heroData)
    
    -- Add starting skill with proper initialization
    self.player:addSkill(startingSkill)
    
    -- Load hero sprites from folder if needed
    if heroData.assetFolder and not heroData.loadedSprites then
        heroData.loadedSprites = Assets.loadHeroSprites("assets/heroes/" .. heroData.assetFolder)
    end
    
    -- Set player sprite data
    self.player.heroSprites = heroData.loadedSprites
    self.player.assetFolder = heroData.assetFolder
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
    -- Load sprites from folder if assetFolder specified
    local flightSprites = {}
    local hitSprite = nil
    
    if projData.assetFolder then
        if not projData.loadedSprites then
            projData.loadedSprites = Assets.loadFolderSprites("assets/" .. projData.assetFolder)
        end
        flightSprites = projData.loadedSprites.flight or {}
        hitSprite = projData.loadedSprites.hit
    end
    
    local proj = self.projectilePool:acquire()
    local dx, dy = Utils.directionTo(projData.x, projData.y, projData.targetX, projData.targetY)
    proj:init(
        projData.x, 
        projData.y, 
        dx, 
        dy, 
        projData.speed, 
        projData.damage, 
        500, 
        "mob",
        flightSprites,
        hitSprite,
        projData.animationSpeed or 0.1,
        projData.hitboxRadius or nil  -- Custom hitbox radius
    )
    table.insert(self.projectiles, proj)
end

-- === DRAW ===

function Game:draw()
    if self.mode == "menu" then
        self:drawMenu()
    elseif self.mode == "char_select" then
        self:drawCharSelect()
    elseif self.mode == "skill_select" then
        self:drawSkillSelect()
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
    self.mainMenu:draw(Assets)
end

function Game:drawCharSelect()
    self.characterSelect:draw(Assets, self.heroConfigs, self.selectedHeroIndex)
end

function Game:drawSkillSelect()
    self.skillSelect:draw(Assets, self.startingSkillConfigs, self.selectedSkillIndex)
end

function Game:drawGameOver()
    Colors.setColor(Colors.GAME_OVER_BG)
    love.graphics.clear()
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Title
    love.graphics.setFont(Assets.getFont("large"))
    Colors.setColor(Colors.GAME_OVER_TITLE)
    love.graphics.printf("GAME OVER", 0, 150, screenW, "center")
    
    -- Stats
    love.graphics.setFont(Assets.getFont("default"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    
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
        Colors.setColor(Colors.BUTTON_HOVER)
    else
        Colors.setColor(Colors.BUTTON_DEFAULT)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 10, 10)
    
    -- Button border
    Colors.setColor(Colors.BUTTON_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Button text
    love.graphics.setFont(Assets.getFont("large"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("RESTART", buttonX, buttonY + 15, buttonW, "center")
    
    -- Instruction
    love.graphics.setFont(Assets.getFont("small"))
    Colors.setColor(Colors.TEXT_DIM)
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
        local spritesheet = Assets.getSpritesheet(drop.spritesheet or "items")
        local quad = Assets.getQuad(drop.spritesheet or "items", drop.spriteIndex or Assets.images.xpDrop)
        
        if spritesheet and quad then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(spritesheet, quad, drop.x, drop.y, 0, 1, 1, 16, 16)
        else
            -- Fallback: draw as blue circle if sprite not found
            Colors.setColor(Colors.BAR_XP)  -- Blue color for XP
            love.graphics.circle("fill", drop.x, drop.y, drop.radius)
            love.graphics.setColor(1, 1, 1, 1)  -- Reset to white
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
        local sprite = nil
        
        -- Determine which sprite to show based on projectile state
        if proj.isHitting and proj.hitSprite then
            -- Show hit effect
            sprite = proj.hitSprite
        elseif proj.flightSprites and #proj.flightSprites > 0 then
            -- Show current flight animation frame
            sprite = proj.flightSprites[proj.currentFrameIndex]
        end
        
        if sprite then
            Colors.setColor(Colors.TEXT_PRIMARY)
            
            -- Get sprite dimensions
            local spriteW, spriteH = sprite:getDimensions()
            
            -- Calculate target display size based on hitbox radius
            -- Make sprite slightly larger than hitbox for visibility (3x diameter)
            local targetSize = proj.radius * 3
            
            -- Calculate scale to fit target size (maintain aspect ratio)
            local scale = targetSize / math.max(spriteW, spriteH)
            
            -- Calculate center point (half of actual sprite size for proper origin)
            local centerX = spriteW / 2
            local centerY = spriteH / 2
            
            -- Calculate rotation angle towards movement direction
            -- Sprites are oriented FACING RIGHT (angle = 0)
            -- math.atan2(dy, dx) returns correct angle for this orientation
            -- Both flight and hit sprites rotate to match projectile direction
            local angle = math.atan2(proj.dy, proj.dx)
            
            -- Draw projectile with rotation, centered and scaled
            love.graphics.draw(sprite, proj.x, proj.y, angle, scale, scale, centerX, centerY)
        else
            -- Fallback: draw as orange circle using hitbox radius if sprite not found
            Colors.setColor(Colors.ACCENT)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius)
            Colors.setColor(Colors.TEXT_PRIMARY)
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
            love.graphics.setColor(Colors.PRIMARY)
            love.graphics.circle("line", self.player.x, self.player.y, self.player.radius)
        end
        
        -- Mob hitboxes (red)
        love.graphics.setColor(Colors.ACCENT)
        for _, mob in ipairs(self.mobs) do
            if self.camera:isPointVisible(mob.x, mob.y) then
                love.graphics.circle("line", mob.x, mob.y, mob.radius)
            end
        end
        
        -- Projectile hitboxes (yellow)
        love.graphics.setColor(Colors.ACCENT)
        for _, proj in ipairs(self.projectiles) do
            love.graphics.circle("line", proj.x, proj.y, proj.radius)
        end
        
        -- XP drop hitboxes (cyan)
        love.graphics.setColor(Colors.PRIMARY)
        for _, drop in ipairs(self.xpDrops) do
            love.graphics.circle("line", drop.x, drop.y, drop.radius)
        end
        
        -- Player skill ranges (blue)
        if self.player and self.player.skills then
            love.graphics.setColor(Colors.SECONDARY)
            for _, skill in ipairs(self.player.skills) do
                if skill.range then
                    love.graphics.circle("line", self.player.x, self.player.y, skill.range)
                end
            end
        end
        
        love.graphics.setColor(Colors.ACCENT)
        love.graphics.setLineWidth(1)
    end
    
    -- Clear camera
    self.camera:clear()
    
    -- Draw HUD (UI overlay, no camera) using HUD module
    if self.hud then
        self.hud:draw(self.player, self.gameTime, Assets)
    end
    
    -- Draw minimap (UI overlay, no camera)
    if self.minimap then
        self.minimap:draw(self.player, self.mobs, self.camera, Assets)
    end
    
    -- Draw pause screen overlay
    if self.paused then
        self:drawPauseScreen()
    end
end

-- Old drawHUD function removed - now using HUD module (src/ui/hud.lua)

function Game:drawDebug()
    Colors.setColor(Colors.ACCENT)
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
    
    Colors.setColor(Colors.TEXT_PRIMARY)
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
    Colors.setColor(Colors.OVERLAY_PAUSE)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Pause text
    love.graphics.setFont(Assets.getFont("large"))
    Colors.setColor(Colors.TEXT_PRIMARY)
    love.graphics.printf("PAUSED", 0, screenH/2 - 60, screenW, "center")
    
    -- Continue button
    love.graphics.setFont(Assets.getFont("medium"))
    Colors.setColor(Colors.TEXT_SECONDARY)
    love.graphics.printf("Press ESC to Continue", 0, screenH/2 + 20, screenW, "center")
end

return Game

