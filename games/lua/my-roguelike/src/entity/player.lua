-- entity/player.lua
-- Player character entity
-- Public API: Player.new(x, y, heroData), player:update(dt), player:gainXP(amount), player:levelUp()
-- Dependencies: base_entity.lua, constants.lua, utils.lua

local BaseEntity = require("src.entity.base_entity")
local Constants = require("src.constants")
local Utils = require("src.utils")

local Player = setmetatable({}, {__index = BaseEntity})
Player.__index = Player

-- === CONSTRUCTOR ===

function Player.new(x, y, heroData)
    local self = setmetatable(BaseEntity.new(x, y), Player)
    
    -- Hero data from config
    self.heroId = heroData.id
    self.heroName = heroData.name
    
    -- Base stats from hero config
    self.maxHp = heroData.baseHp
    self.hp = self.maxHp
    self.armor = heroData.baseArmor
    self.speed = heroData.baseMoveSpeed
    self.castSpeed = heroData.baseCastSpeed  -- Affects skill cooldowns
    
    -- Stat growth per level
    self.hpGrowth = heroData.hpGrowth
    self.armorGrowth = heroData.armorGrowth
    self.speedGrowth = heroData.speedGrowth
    self.castSpeedGrowth = heroData.castSpeedGrowth
    
    -- Level & XP
    self.level = 1
    self.xp = 0
    self.xpToNextLevel = Utils.xpForLevel(2)
    
    -- Skills
    self.skills = {}  -- Active skills
    self.innateSkill = heroData.innateSkill  -- Passive/modifier skill
    self.maxSkillSlots = Constants.MAX_ACTIVE_SKILLS
    
    -- Add starting skill if provided
    if heroData.startingSkill then
        table.insert(self.skills, heroData.startingSkill)
    end
    
    -- Pickup radius
    self.pickupRadius = Constants.PLAYER_DEFAULT_PICKUP_RADIUS
    
    -- Combat
    self.autoAttackTimer = 0
    self.manualAimMode = false
    self.aimDirection = {x = 1, y = 0}
    
    -- Visual
    self.radius = Constants.PLAYER_HITBOX_RADIUS
    self.directionArrow = 0  -- Angle for direction indicator
    
    return self
end

-- === UPDATE ===

function Player:update(dt)
    BaseEntity.update(self, dt)
    
    -- Update skill cooldowns
    for _, skill in ipairs(self.skills) do
        if skill.cooldownTimer > 0 then
            skill.cooldownTimer = skill.cooldownTimer - dt
        end
    end
end

-- === MOVEMENT ===

function Player:setMovementInput(dx, dy, dt)
    if dx ~= 0 or dy ~= 0 then
        self:move(dx, dy, dt)
        -- Update direction arrow
        self.directionArrow = math.atan2(dy, dx)
    else
        self:stopMovement()
    end
end

-- === COMBAT & SKILLS ===

function Player:setAimDirection(dx, dy)
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        self.aimDirection.x = dx / len
        self.aimDirection.y = dy / len
        self.directionArrow = math.atan2(dy, dx)
    end
end

function Player:setManualAimMode(enabled)
    self.manualAimMode = enabled
end

-- Check if skill can be cast
function Player:canCastSkill(skill)
    if not self:canAttack() then return false end
    if not skill.cooldownTimer then skill.cooldownTimer = 0 end
    return skill.cooldownTimer <= 0
end

-- Cast a specific skill (called by skills system)
function Player:castSkill(skill, targetX, targetY)
    if not self:canCastSkill(skill) then return false end
    
    -- Calculate effective cooldown (affected by cast speed)
    local effectiveCooldown = skill.cooldown / self.castSpeed
    skill.cooldownTimer = effectiveCooldown
    
    return true
end

-- === LEVELING ===

function Player:gainXP(amount)
    self.xp = self.xp + amount
    
    -- Check for level up
    while self.xp >= self.xpToNextLevel do
        self.xp = self.xp - self.xpToNextLevel
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    
    -- Apply stat growth
    self.maxHp = self.maxHp + self.hpGrowth
    self.hp = self.maxHp  -- Full heal on level up
    self.armor = self.armor + self.armorGrowth
    self.speed = self.speed + self.speedGrowth
    self.castSpeed = self.castSpeed + self.castSpeedGrowth
    
    -- Update XP requirement for next level
    self.xpToNextLevel = Utils.xpForLevel(self.level + 1)
    
    Utils.log("Player leveled up to " .. self.level)
    
    -- Trigger skill choice (handled by game state)
    return true  -- Signal level up happened
end

function Player:addSkill(skillData)
    -- Check if we have room
    if #self.skills >= self.maxSkillSlots then
        Utils.logError("Cannot add skill: all slots full")
        return false
    end
    
    -- Check if skill already exists (for upgrades)
    for _, skill in ipairs(self.skills) do
        if skill.id == skillData.id then
            -- Upgrade existing skill
            skill.level = (skill.level or 1) + 1
            Utils.log("Upgraded skill: " .. skillData.name)
            return true
        end
    end
    
    -- Add new skill
    local newSkill = Utils.shallowCopy(skillData)
    newSkill.cooldownTimer = 0
    newSkill.level = 1
    table.insert(self.skills, newSkill)
    Utils.log("Added new skill: " .. skillData.name)
    
    return true
end

-- === PICKUP ===

function Player:canPickup(xpDrop)
    local dist = Utils.distance(self.x, self.y, xpDrop.x, xpDrop.y)
    return dist <= self.pickupRadius
end

-- === DRAW ===

function Player:draw()
    BaseEntity.draw(self)
    
    -- Draw direction arrow
    self:drawDirectionArrow()
end

function Player:drawDirectionArrow()
    local arrowLength = self.radius + 8
    local arrowX = self.x + math.cos(self.directionArrow) * arrowLength
    local arrowY = self.y + math.sin(self.directionArrow) * arrowLength
    
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.x, self.y, arrowX, arrowY)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

-- === STATS ===

function Player:getStats()
    return {
        level = self.level,
        xp = self.xp,
        xpToNext = self.xpToNextLevel,
        hp = self.hp,
        maxHp = self.maxHp,
        armor = self.armor,
        speed = self.speed,
        castSpeed = self.castSpeed,
    }
end

return Player

