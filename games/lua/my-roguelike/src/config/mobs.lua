-- config/mobs.lua
-- Mob configurations (data-driven)
-- Format:
-- {
--   id = "unique_id",
--   name = "Mob Name",
--   type = "melee" | "ranged",
--   assetFolder = "foldername" (folder in assets/mobs/ containing sprite files),
--   -- Sprite files in folder:
--   --   i.png - idle animation (standing)
--   --   1.png, 2.png - idle animation frames (optional)
--   --   a.png - attack animation (when attacking)
--   --   NOTE: All sprites should be oriented FACING RIGHT
--   baseHp = number,
--   hpGrowth = number (per level),
--   baseArmor = number,
--   armorGrowth = number,
--   baseMoveSpeed = number,
--   speedGrowth = number,
--   baseDamage = number,
--   damageGrowth = number,
--   attackSpeed = number (attacks per second),
--   attackRange = number (ranged only),
--   projectileSpeed = number (ranged only),
--   projectileHitboxRadius = number (ranged only, collision radius for projectile),
--   projectileAssetFolder = "foldername" (ranged only, folder in assets/),
--   -- Or legacy spritesheet approach:
--   projectileSpritesheet = "filename" (ranged only, spritesheet for projectiles),
--   projectileSpriteIndex = number (ranged only, sprite index for projectiles),
--   spriteSize = number (optional, display size in pixels, default: 32)
--   -- hitboxRadius calculated automatically: spriteSize * 0.375
--   xpDrop = number,
--   xpDropGrowth = number (per level),
--   xpDropSpritesheet = "filename" (spritesheet for XP drop, default "items"),
--   xpDropSpriteIndex = number (sprite index for XP drop, default 324),
--   spawnWeight = number (relative spawn probability, 1=common, 10=rare),
--   spawnStartTime = number (seconds from game start when mob can spawn),
--   spawnEndTime = number (seconds from game start when mob stops spawning, nil=forever),
--   spawnGroupSize = number (mobs per spawn group, default 1)
-- }

local mobs = {
    -- === BASELINE MOB (REFERENCE FOR BALANCE) ===
    -- {
    --     id = "baseline_mob",
    --     name = "Baseline Mob",
    --     type = "melee",
    --     spriteIndex = 1,
    --     
    --     baseHp = 50,         -- Standard mob HP
    --     hpGrowth = 8,        -- Moderate HP growth
    --     baseArmor = 0,        -- No armor
    --     armorGrowth = 0.3,    -- Low armor scaling
    --     baseMoveSpeed = 70,   -- Slightly slower than player
    --     speedGrowth = 1,      -- Standard speed growth
    --     baseDamage = 10,      -- Standard damage
    --     damageGrowth = 2,     -- Moderate damage scaling
    --     
    --     attackSpeed = 1.0,    -- 1 attack per second
    --     
    --     xpDrop = 10,         -- Standard XP
    --     xpDropGrowth = 2      -- Moderate XP scaling
    -- },

    -- === MELEE MOB ===
    {
        id = "zombie",
        name = "Zombie",
        type = "melee",
        assetFolder = "mobs/zombie",  -- assets/mobs/zombie/ folder with i.png

        baseHp = 50,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 60,
        speedGrowth = 5,
        baseDamage = 10,
        damageGrowth = 3,
        
        attackSpeed = 1.0,  -- 1 attack per second

        -- Size parameters (optional, uses defaults if not specified)
        spriteSize = 32,      -- Display size in pixels (default: 32)
        -- hitboxRadius calculated automatically: spriteSize * 0.375 (12px for 32px sprite)

        xpDrop = 10,
        xpDropGrowth = 2,
        xpDropSpritesheet = "items",  -- items.png from assets/
        -- xpDropSpriteIndex optional; default comes from Assets.images.xpDrop

        -- Spawn parameters
        spawnWeight = 1,           -- Common mob (1=very common, 10=very rare)
        spawnStartTime = 0,         -- Can spawn from game start
        spawnEndTime = nil,         -- Spawns forever (no end time)
        spawnGroupSize = 1,         -- Single mob spawns
    },


    -- === RANGED MOB ===
    {
        id = "fireclaw",
        name = "Fireclaw",
        type = "ranged",
        assetFolder = "mobs/fireclaw",
        
        baseHp = 30,
        hpGrowth = 5,
        baseArmor = 0,
        armorGrowth = 0.2,
        baseMoveSpeed = 40,
        speedGrowth = 1,
        baseDamage = 15,
        damageGrowth = 5,
        
        attackSpeed = 0.5,
        attackRange = 400,
        projectileSpeed = 100,
        projectileHitboxRadius = 4,
        projectileAssetFolder = "starting_skills/fireball",-- TODO:
        
        xpDrop = 15,
        xpDropGrowth = 3,
        xpDropSpritesheet = "items",
        
        -- Spawn parameters
        spawnWeight = 3,
        spawnStartTime = 0,
        spawnEndTime = nil,
        spawnGroupSize = 2,
    }
}

return mobs

