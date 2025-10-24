-- constants.lua
-- All game constants and magic numbers in one place
-- Public API: Constants table with all game parameters
-- Imports balance values from balansed.lua for centralized balance control

local Balansed = require("src.config.balansed")

local Constants = {}

-- === GAME TIMING ===
Constants.FIXED_DT = 1/60                   -- Fixed timestep for logic (60Hz)
Constants.MAX_FRAME_SKIP = 5                -- Max physics steps per frame

-- === MAP ===
Constants.MAP_WIDTH = 3200
Constants.MAP_HEIGHT = 2400
Constants.MAP_BOUNDARY_WIDTH = 10           -- White border thickness

-- === CAMERA ===
Constants.CAMERA_LERP_SPEED = 5             -- Camera smoothing
Constants.CULLING_MARGIN = 100              -- Extra pixels to render outside view

-- === SPATIAL HASH ===
Constants.SPATIAL_CELL_SIZE = 128           -- Grid cell size for spatial hash

-- === PLAYER ===
Constants.PLAYER_DEFAULT_PICKUP_RADIUS = 80
Constants.PLAYER_DEFAULT_SPRITE_SIZE = 64    -- Default hero sprite size if not specified in config

-- === MOBS ===
Constants.MOB_SPAWN_INTERVAL = Balansed.CONSTANTS.MOB_SPAWN_INTERVAL
Constants.MOB_SPAWN_MIN_DISTANCE = Balansed.CONSTANTS.MOB_SPAWN_MIN_DISTANCE
Constants.MOB_SPAWN_MAX_DISTANCE = Balansed.CONSTANTS.MOB_SPAWN_MAX_DISTANCE
Constants.MOB_LEVEL_UP_INTERVAL = Balansed.CONSTANTS.MOB_LEVEL_UP_INTERVAL
Constants.MOB_AI_UPDATE_RATE = 1/10         -- AI decisions 10Hz
Constants.MOB_DEFAULT_SPRITE_SIZE = 32      -- Default mob sprite size if not specified in config

-- === MOB DEFAULT STATS ===
Constants.MOB_DEFAULT_HP_GROWTH = 0         -- Default HP growth per level
Constants.MOB_DEFAULT_ARMOR_GROWTH = 0      -- Default armor growth per level
Constants.MOB_DEFAULT_SPEED_GROWTH = 0      -- Default speed growth per level
Constants.MOB_DEFAULT_DAMAGE_GROWTH = 0     -- Default damage growth per level
Constants.MOB_DEFAULT_XP_GROWTH = 0         -- Default XP drop growth per level
Constants.MOB_DEFAULT_ATTACK_SPEED = 1.0    -- Default attacks per second
Constants.MOB_DEFAULT_ATTACK_RANGE = 200    -- Default attack range for ranged mobs
Constants.MOB_DEFAULT_PROJECTILE_SPEED = 150 -- Default projectile speed
Constants.MOB_DEFAULT_PROJECTILE_RADIUS = 14 -- Default projectile hitbox radius
Constants.MOB_DEFAULT_PROJECTILE_ANIMATION_SPEED = 0.15 -- Default projectile animation speed

-- === PROJECTILES ===
Constants.PROJECTILE_POOL_SIZE = 500        -- Pre-allocated projectile pool
Constants.PROJECTILE_SPRITE_SIZE = 16
Constants.PROJECTILE_HITBOX_RADIUS = 6

-- === XP DROPS ===
Constants.XP_DROP_SPRITE_SIZE = 16
Constants.XP_DROP_LIFETIME = 30.0           -- Disappears after 30 seconds

-- === SKILLS ===
Constants.SKILL_CHOICE_COUNT = 3            -- Number of skills to choose from on level up
Constants.MAX_ACTIVE_SKILLS = 4             -- Default max skill slots (can be modified by innate)

-- === SKILL BASE STATS (BALANCE REFERENCE) ===
-- These are baseline values for skill balance calculations
Constants.SKILL_BASE_COOLDOWN = Balansed.CONSTANTS.SKILL_BASE_COOLDOWN
Constants.SKILL_BASE_DAMAGE = Balansed.CONSTANTS.SKILL_BASE_DAMAGE
Constants.SKILL_BASE_RANGE = Balansed.CONSTANTS.SKILL_BASE_RANGE
Constants.SKILL_BASE_PROJECTILE_SPEED = 250 -- Baseline projectile speed
Constants.SKILL_BASE_HITBOX_RADIUS = 6     -- Baseline hitbox radius
Constants.SKILL_BASE_AOE_RADIUS = Balansed.CONSTANTS.SKILL_BASE_AOE_RADIUS
Constants.SKILL_BASE_TICK_RATE = Balansed.CONSTANTS.SKILL_BASE_TICK_RATE
Constants.SKILL_BASE_DURATION = Balansed.CONSTANTS.SKILL_BASE_DURATION
Constants.SKILL_BASE_ANIMATION_SPEED = 0.1  -- Baseline animation speed
Constants.SKILL_DIRECTION_THRESHOLD = 0.7   -- Dot product threshold for direction matching

-- === SKILL TYPE MULTIPLIERS ===
-- These modify base stats for different skill types
Constants.SKILL_AURA_DAMAGE_MULT = Balansed.SKILL_TYPE_MULTIPLIERS.AURA_DAMAGE
Constants.SKILL_LASER_DAMAGE_MULT = Balansed.SKILL_TYPE_MULTIPLIERS.LASER_DAMAGE

-- === ORBITAL SKILL CONSTANTS ===
-- Baseline values from balansed.lua
Constants.ORBITAL_BASE_COUNT = Balansed.BASELINE_ORBITAL_SKILL.orbitalCount
Constants.ORBITAL_BASE_RADIUS = Balansed.BASELINE_ORBITAL_SKILL.orbitalRadius
Constants.ORBITAL_BASE_SPEED = Balansed.BASELINE_ORBITAL_SKILL.orbitalSpeed
Constants.ORBITAL_BASE_DAMAGE = Balansed.BASELINE_ORBITAL_SKILL.damage
Constants.ORBITAL_BASE_DURATION = Balansed.BASELINE_ORBITAL_SKILL.duration
Constants.ORBITAL_BASE_HITBOX_RADIUS = Balansed.BASELINE_ORBITAL_SKILL.hitboxRadius
Constants.ORBITAL_BASE_ANIMATION_SPEED = Balansed.BASELINE_ORBITAL_SKILL.animationSpeed

-- Technical constants (not in balansed.lua)
Constants.ORBITAL_HIT_COOLDOWN = 0.1             -- Minimum time between hits on same target
Constants.ORBITAL_COLLISION_QUERY_RADIUS = 50    -- Extra radius for spatial hash queries
Constants.ORBITAL_SPIN_SPEED = 8.0               -- Orbital sprite spin speed (radians/sec)
Constants.ORBITAL_PLAYER_COLOR_R = 0.8           -- Player orbital color (orange)
Constants.ORBITAL_PLAYER_COLOR_G = 0.4
Constants.ORBITAL_PLAYER_COLOR_B = 0.2
Constants.ORBITAL_MOB_COLOR_R = 0.8              -- Mob orbital color (red)
Constants.ORBITAL_MOB_COLOR_G = 0.2
Constants.ORBITAL_MOB_COLOR_B = 0.2

-- === SUMMON BASE STATS ===
Constants.SUMMON_BASE_HP = Balansed.BASELINE_SUMMON_SKILL.summonHp
Constants.SUMMON_BASE_SPEED = Balansed.BASELINE_SUMMON_SKILL.summonSpeed
Constants.SUMMON_BASE_ARMOR = Balansed.BASELINE_SUMMON_SKILL.summonArmor

-- === BOSS ===
Constants.BOSS_SPAWN_INTERVAL = Balansed.CONSTANTS.BOSS_SPAWN_INTERVAL

-- === RENDERING ===
Constants.SPRITE_BATCH_SIZE = 1000          -- Max sprites per batch
Constants.DEBUG_DRAW_HITBOXES = true        -- Toggle hitbox rendering
Constants.DEBUG_DRAW_DIRECTION_ARROW = false -- Toggle direction arrow rendering
Constants.DEBUG_DRAW_DAMAGE_NUMBERS = true   -- Toggle damage numbers display above mobs

-- === INPUT ===
Constants.GAMEPAD_DEADZONE = 0.25           -- Joystick deadzone
Constants.HOLD_THRESHOLD = 0.016            -- Min time to register as hold (1 frame)

-- === STATUS EFFECTS ===
Constants.STATUS_SLOW = "slow"
Constants.STATUS_POISON = "poison"
Constants.STATUS_ROOT = "root"
Constants.STATUS_STUN = "stun"

-- Status effect defaults
Constants.SLOW_DEFAULT_PERCENT = 50         -- Default slow percentage
Constants.POISON_DEFAULT_DAMAGE = 5         -- Default poison damage per tick
Constants.POISON_TICK_RATE = 0.5            -- Poison default tick rate

-- === DAMAGE & COMBAT ===
Constants.ARMOR_REDUCTION_FACTOR = 0.06     -- Each armor point reduces damage by 6%
Constants.MAX_ARMOR_REDUCTION = 0.75        -- Max 75% damage reduction

-- === DEBUG ===
Constants.DEBUG_ENABLED = true
Constants.DEBUG_FONT_SIZE = 12
Constants.DEBUG_LOG_FILE = "debug.log"

return Constants

