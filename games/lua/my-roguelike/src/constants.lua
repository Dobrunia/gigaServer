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

-- === BOSS ===
Constants.BOSS_SPAWN_INTERVAL = 600.0       -- Boss every 10 minutes

-- === UI ===
Constants.HUD_HEIGHT = 120
Constants.HUD_PADDING = 10
Constants.SKILL_ICON_SIZE = 64  -- Square skill slots (Dota-style)
Constants.MENU_BUTTON_WIDTH = 200
Constants.MENU_BUTTON_HEIGHT = 60
Constants.CHAR_CARD_WIDTH = 600
Constants.CHAR_CARD_HEIGHT = 200

-- === MINIMAP ===
Constants.MINIMAP_SIZE = 200                    -- Square minimap size
Constants.MINIMAP_PADDING = 10                 -- Distance from screen edge
Constants.MINIMAP_BORDER_WIDTH = 2             -- Border thickness
Constants.MINIMAP_PLAYER_SIZE = 4              -- Player dot size
Constants.MINIMAP_MOB_SIZE = 2                 -- Mob dot size
Constants.MINIMAP_PROJECTILE_SIZE = 1          -- Projectile dot size
Constants.MINIMAP_BACKGROUND_ALPHA = 0.7       -- Background transparency

-- === RENDERING ===
Constants.SPRITE_BATCH_SIZE = 1000          -- Max sprites per batch
Constants.DEBUG_DRAW_HITBOXES = true        -- Toggle hitbox rendering

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

