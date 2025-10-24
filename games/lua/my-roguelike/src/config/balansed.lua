-- config/balansed.lua
-- Baseline balance templates for all entity types
-- This is the central place to adjust game balance
-- All other configs should reference these baselines

local Balansed = {}

-- === BASELINE HERO ===
-- Standard hero template - all heroes should be balanced around this
Balansed.BASELINE_HERO = {
    id = "baseline_hero",
    name = "Baseline Hero",
    assetFolder = "baseline_hero",
    
    -- Core stats
    baseHp = 100,           -- Standard HP
    hpGrowth = 15,          -- Moderate HP growth per level
    baseArmor = 2,           -- Some armor
    armorGrowth = 0.8,       -- Decent armor scaling
    baseMoveSpeed = 100,     -- Standard movement speed
    speedGrowth = 1.5,       -- Moderate speed growth
    baseCastSpeed = 1.0,     -- Normal cast speed (1.0 = 100%)
    castSpeedGrowth = 0.03,  -- Cast speed growth per level
    
    -- Visual
    spriteSize = 64,         -- Standard hero size
    
    -- Innate skill (passive modifier)
    innateSkill = {
        id = "baseline_innate",
        name = "Balanced",
        description = "No special modifiers",
        modifiers = {}
    }
}

-- === BASELINE MOBS ===

-- Standard melee mob template
Balansed.BASELINE_MELEE_MOB = {
    id = "baseline_melee_mob",
    name = "Baseline Melee Mob",
    type = "melee",
    assetFolder = "baseline_melee_mob",
    
    -- Core stats
    baseHp = 50,             -- Standard mob HP
    hpGrowth = 8,            -- Moderate HP growth per level
    baseArmor = 0,           -- No armor
    armorGrowth = 0.3,        -- Low armor scaling
    baseMoveSpeed = 70,       -- Slightly slower than player
    speedGrowth = 1,          -- Standard speed growth
    baseDamage = 10,          -- Standard damage
    damageGrowth = 2,         -- Moderate damage scaling
    
    -- Combat
    attackSpeed = 1.0,        -- 1 attack per second
    
    -- Visual
    spriteSize = 32,          -- Standard mob size
    
    -- Rewards
    xpDrop = 10,              -- Standard XP
    xpDropGrowth = 2,         -- Moderate XP scaling
    
    -- Spawn
    spawnWeight = 1,          -- Common mob
    spawnStartTime = 0,       -- Can spawn from start
    spawnEndTime = nil,       -- Spawns forever
    spawnGroupSize = 1        -- Single mob spawns
}

-- Standard ranged mob template
Balansed.BASELINE_RANGED_MOB = {
    id = "baseline_ranged_mob",
    name = "Baseline Ranged Mob",
    type = "ranged",
    assetFolder = "baseline_ranged_mob",
    
    -- Core stats (slightly weaker than melee)
    baseHp = 40,             -- Lower HP than melee
    hpGrowth = 6,            -- Lower HP growth
    baseArmor = 0,           -- No armor
    armorGrowth = 0.2,        -- Lower armor scaling
    baseMoveSpeed = 50,       -- Slower than melee
    speedGrowth = 0.8,        -- Lower speed growth
    baseDamage = 15,          -- Higher damage than melee
    damageGrowth = 3,         -- Higher damage scaling
    
    -- Combat
    attackSpeed = 0.8,        -- Slower attacks than melee
    attackRange = 300,        -- Standard ranged attack range
    projectileSpeed = 150,    -- Standard projectile speed
    projectileAssetFolder = "baseline_projectile",
    
    -- Visual
    spriteSize = 32,          -- Standard mob size
    
    -- Rewards (higher than melee due to difficulty)
    xpDrop = 15,              -- Higher XP than melee
    xpDropGrowth = 3,         -- Higher XP scaling
    
    -- Spawn
    spawnWeight = 2,          -- Less common than melee
    spawnStartTime = 0,       -- Can spawn from start
    spawnEndTime = nil,       -- Spawns forever
    spawnGroupSize = 1        -- Single mob spawns
}

-- === BASELINE BOSS ===
-- Standard boss template - much stronger than mobs
Balansed.BASELINE_BOSS = {
    id = "baseline_boss",
    name = "Baseline Boss",
    type = "melee",
    assetFolder = "baseline_boss",
    
    -- Core stats (4x stronger than average mob)
    baseHp = 200,             -- 4x mob HP
    hpGrowth = 30,            -- High HP growth
    baseArmor = 5,            -- Moderate armor
    armorGrowth = 1.0,        -- Good armor scaling
    baseMoveSpeed = 80,        -- Slightly slower than player
    speedGrowth = 2,           -- Decent speed growth
    baseDamage = 25,           -- 2.5x mob damage
    damageGrowth = 5,          -- Strong damage scaling
    
    -- Combat
    attackSpeed = 0.8,         -- Slower than mobs but hits harder
    
    -- Visual
    spriteSize = 64,          -- Larger than mobs
    
    -- Rewards (10x mob XP)
    xpDrop = 100,             -- 10x mob XP
    xpDropGrowth = 20,        -- High XP scaling
    
    -- Spawn
    spawnWeight = 0.1,        -- Very rare
    spawnStartTime = 600,      -- Spawns after 10 minutes
    spawnEndTime = nil,        -- Spawns forever
    spawnGroupSize = 1         -- Single boss spawns
}

-- === BASELINE SKILLS ===

-- Standard projectile skill template
Balansed.BASELINE_PROJECTILE_SKILL = {
    id = "baseline_projectile",
    name = "Baseline Projectile",
    description = "Shoots a projectile that deals damage",
    type = "projectile",
    assetFolder = "baseline_projectile",
    
    -- Core stats
    cooldown = 2.0,           -- Standard cooldown
    damage = 25,              -- Standard damage
    range = 300,               -- Standard range
    projectileSpeed = 250,   -- Standard projectile speed
    hitboxRadius = 6,          -- Standard hitbox radius
    animationSpeed = 0.1       -- Standard animation speed
}

-- Standard AOE skill template
Balansed.BASELINE_AOE_SKILL = {
    id = "baseline_aoe",
    name = "Baseline AOE",
    description = "Area of effect damage around caster",
    type = "aoe",
    assetFolder = "baseline_aoe",
    
    -- Core stats (1.5x damage, 1.5x cooldown for balance)
    cooldown = 3.0,           -- 1.5x projectile cooldown
    damage = 37.5,             -- 1.5x projectile damage
    radius = 100,              -- Standard AOE radius
    animationSpeed = 0.1       -- Standard animation speed
}

-- Standard buff skill template
Balansed.BASELINE_BUFF_SKILL = {
    id = "baseline_buff",
    name = "Baseline Buff",
    description = "Applies beneficial effect to caster",
    type = "buff",
    assetFolder = "baseline_buff",
    
    -- Core stats (2x cooldown for utility)
    cooldown = 4.0,           -- 2x projectile cooldown
    buffEffect = {
        type = "speed",
        duration = 5,
        speedPercent = 50
    },
    animationSpeed = 0.1       -- Standard animation speed
}

-- Standard summon skill template
Balansed.BASELINE_SUMMON_SKILL = {
    id = "baseline_summon",
    name = "Baseline Summon",
    description = "Spawns allied creature",
    type = "summon",
    assetFolder = "baseline_summon",
    
    -- Core stats (3x cooldown for allies)
    cooldown = 6.0,           -- 3x projectile cooldown
    damage = 25,               -- Summon's attack damage
    summonSpeed = 100,         -- Summon's movement speed
    summonHp = 50,              -- Summon's health
    summonArmor = 0,            -- Summon's armor
    animationSpeed = 0.1        -- Standard animation speed
}

-- Standard aura skill template
Balansed.BASELINE_AURA_SKILL = {
    id = "baseline_aura",
    name = "Baseline Aura",
    description = "Continuous area effect around caster",
    type = "aura",
    assetFolder = "baseline_aura",
    
    -- Core stats (0.5x cooldown, 0.3x damage for continuous)
    cooldown = 1.0,           -- 0.5x projectile cooldown
    damage = 7.5,             -- 0.3x projectile damage
    radius = 100,              -- Standard aura radius
    tickRate = 1.0,            -- Standard tick rate
    duration = 10.0,           -- Standard aura duration
    animationSpeed = 0.1       -- Standard animation speed
}

-- Standard laser skill template
Balansed.BASELINE_LASER_SKILL = {
    id = "baseline_laser",
    name = "Baseline Laser",
    description = "Continuous beam attack to single target",
    type = "laser",
    assetFolder = "baseline_laser",
    
    -- Core stats (1.2x cooldown, 0.6x damage for continuous)
    cooldown = 2.4,           -- 1.2x projectile cooldown
    range = 300,               -- Standard laser range
    damage = 15,               -- 0.6x projectile damage
    tickRate = 1.0,            -- Standard tick rate
    animationSpeed = 0.1        -- Standard animation speed
}

-- === BASELINE INNATE SKILLS ===

-- Balanced innate (no modifiers)
Balansed.BASELINE_INNATE = {
    id = "baseline_innate",
    name = "Balanced",
    description = "No special modifiers",
    modifiers = {}
}

-- Cast speed innate
Balansed.CAST_SPEED_INNATE = {
    id = "cast_speed_innate",
    name = "Spell Mastery",
    description = "All skills have 30% shorter cooldowns",
    modifiers = {
        cooldownReduction = 0.3
    }
}

-- Damage innate
Balansed.DAMAGE_INNATE = {
    id = "damage_innate",
    name = "Power Strike",
    description = "All skills deal 25% more damage",
    modifiers = {
        damageMultiplier = 0.25
    }
}

-- Speed innate
Balansed.SPEED_INNATE = {
    id = "speed_innate",
    name = "Swift Movement",
    description = "20% faster movement speed",
    modifiers = {
        speedMultiplier = 0.2
    }
}

-- Health innate
Balansed.HEALTH_INNATE = {
    id = "health_innate",
    name = "Toughness",
    description = "50% more health and 25% more armor",
    modifiers = {
        hpMultiplier = 0.5,
        armorMultiplier = 0.25
    }
}

-- === BALANCE MULTIPLIERS ===
-- These control the relative power of different skill types

Balansed.SKILL_TYPE_MULTIPLIERS = {
    -- Cooldown multipliers (higher = longer cooldown)
    PROJECTILE_COOLDOWN = 1.0,    -- Baseline
    AOE_COOLDOWN = 1.5,           -- 50% longer for area damage
    BUFF_COOLDOWN = 2.0,          -- 100% longer for utility
    SUMMON_COOLDOWN = 3.0,        -- 200% longer for allies
    AURA_COOLDOWN = 0.5,          -- 50% shorter for continuous
    LASER_COOLDOWN = 1.2,         -- 20% longer for continuous
    
    -- Damage multipliers (higher = more damage)
    PROJECTILE_DAMAGE = 1.0,      -- Baseline
    AOE_DAMAGE = 1.5,             -- 50% more for area damage
    AURA_DAMAGE = 0.3,            -- 70% less for continuous
    LASER_DAMAGE = 0.6,           -- 40% less for continuous
    BUFF_DAMAGE = 0.0,            -- No damage (utility)
    SUMMON_DAMAGE = 1.0           -- Same as projectile (summon's attack)
}

-- === BALANCE CONSTANTS ===
-- Key balance values that affect gameplay

Balansed.CONSTANTS = {
    -- Hero balance
    HERO_HP_PER_LEVEL = 15,       -- How much HP heroes gain per level
    HERO_ARMOR_PER_LEVEL = 0.8,   -- How much armor heroes gain per level
    HERO_SPEED_PER_LEVEL = 1.5,   -- How much speed heroes gain per level
    HERO_CAST_SPEED_PER_LEVEL = 0.03, -- How much cast speed heroes gain per level
    
    -- Mob balance
    MOB_HP_PER_LEVEL = 8,         -- How much HP mobs gain per level
    MOB_ARMOR_PER_LEVEL = 0.3,     -- How much armor mobs gain per level
    MOB_SPEED_PER_LEVEL = 1,       -- How much speed mobs gain per level
    MOB_DAMAGE_PER_LEVEL = 2,      -- How much damage mobs gain per level
    
    -- Skill balance
    SKILL_BASE_COOLDOWN = 2.0,     -- Baseline skill cooldown
    SKILL_BASE_DAMAGE = 25,        -- Baseline skill damage
    SKILL_BASE_RANGE = 300,       -- Baseline skill range
    SKILL_BASE_AOE_RADIUS = 100,  -- Baseline AOE radius
    SKILL_BASE_TICK_RATE = 1.0,   -- Baseline tick rate for continuous skills
    SKILL_BASE_DURATION = 10.0,   -- Baseline duration for temporary skills
    
    -- XP balance
    XP_BASE_DROP = 10,             -- Baseline XP drop from mobs
    XP_GROWTH_PER_LEVEL = 2,       -- How much XP drops grow per mob level
    XP_LEVEL_REQUIREMENT_MULTIPLIER = 1.5, -- How much XP is needed per level (exponential)
    
    -- Spawn balance
    MOB_SPAWN_INTERVAL = 2.0,     -- Seconds between spawn attempts
    MOB_SPAWN_MIN_DISTANCE = 400,  -- Min distance from player
    MOB_SPAWN_MAX_DISTANCE = 600,  -- Max distance from player
    BOSS_SPAWN_INTERVAL = 600.0,   -- Boss every 10 minutes
    MOB_LEVEL_UP_INTERVAL = 60.0   -- Mobs level up every minute
}

return Balansed
