-- constants.lua
-- All game constants and magic numbers in one place
-- Public API: Constants table with all game parameters

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
Constants.MOB_SPAWN_INTERVAL = 2.0          -- Seconds between spawn attempts
Constants.MOB_SPAWN_MIN_DISTANCE = 400      -- Min distance from player
Constants.MOB_SPAWN_MAX_DISTANCE = 600      -- Max distance from player
Constants.MOB_LEVEL_UP_INTERVAL = 60.0      -- Mobs level up every 60 seconds
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
Constants.SKILL_BASE_COOLDOWN = 2.0         -- Baseline cooldown (seconds)
Constants.SKILL_BASE_DAMAGE = 25            -- Baseline damage
Constants.SKILL_BASE_RANGE = 300           -- Baseline range (pixels)
Constants.SKILL_BASE_PROJECTILE_SPEED = 250 -- Baseline projectile speed
Constants.SKILL_BASE_HITBOX_RADIUS = 6     -- Baseline hitbox radius
Constants.SKILL_BASE_AOE_RADIUS = 100       -- Baseline AOE radius
Constants.SKILL_BASE_TICK_RATE = 1.0        -- Baseline tick rate (seconds)
Constants.SKILL_BASE_ANIMATION_SPEED = 0.1  -- Baseline animation speed

-- === SKILL TYPE MULTIPLIERS ===
-- These modify base stats for different skill types
Constants.SKILL_PROJECTILE_DAMAGE_MULT = 1.0    -- Projectile damage multiplier
Constants.SKILL_PROJECTILE_COOLDOWN_MULT = 1.0  -- Projectile cooldown multiplier
Constants.SKILL_AOE_DAMAGE_MULT = 1.5           -- AOE damage multiplier (higher for area)
Constants.SKILL_AOE_COOLDOWN_MULT = 1.5         -- AOE cooldown multiplier (longer for area)
Constants.SKILL_BUFF_COOLDOWN_MULT = 2.0        -- Buff cooldown multiplier (longer for utility)
Constants.SKILL_SUMMON_COOLDOWN_MULT = 3.0      -- Summon cooldown multiplier (longest for allies)
Constants.SKILL_AURA_DAMAGE_MULT = 0.3          -- Aura damage multiplier (lower for continuous)
Constants.SKILL_AURA_COOLDOWN_MULT = 0.5        -- Aura cooldown multiplier (shorter for continuous)
Constants.SKILL_LASER_DAMAGE_MULT = 0.6         -- Laser damage multiplier (lower for continuous)
Constants.SKILL_LASER_COOLDOWN_MULT = 1.2       -- Laser cooldown multiplier

-- === SUMMON BASE STATS ===
Constants.SUMMON_BASE_HP = 50                   -- Baseline summon health
Constants.SUMMON_BASE_SPEED = 100               -- Baseline summon movement speed
Constants.SUMMON_BASE_ARMOR = 0                 -- Baseline summon armor

-- === BOSS ===
Constants.BOSS_SPAWN_INTERVAL = 600.0       -- Boss every 10 minutes

-- === RENDERING ===
Constants.SPRITE_BATCH_SIZE = 1000          -- Max sprites per batch
Constants.DEBUG_DRAW_HITBOXES = true        -- Toggle hitbox rendering
Constants.DEBUG_DRAW_DIRECTION_ARROW = false -- Toggle direction arrow rendering

-- === INPUT ===
Constants.GAMEPAD_DEADZONE = 0.25           -- Joystick deadzone
Constants.HOLD_THRESHOLD = 0.016            -- Min time to register as hold (1 frame)

-- === STATUS EFFECTS ===
Constants.STATUS_SLOW = "slow"
Constants.STATUS_POISON = "poison"
Constants.STATUS_ROOT = "root"
Constants.STATUS_STUN = "stun"

-- Poison default tick rate
Constants.POISON_TICK_RATE = 0.5

-- === DAMAGE & COMBAT ===
Constants.ARMOR_REDUCTION_FACTOR = 0.06     -- Each armor point reduces damage by 6%
Constants.MAX_ARMOR_REDUCTION = 0.75        -- Max 75% damage reduction

-- === DEBUG ===
Constants.DEBUG_ENABLED = true
Constants.DEBUG_FONT_SIZE = 12
Constants.DEBUG_LOG_FILE = "debug.log"

return Constants

