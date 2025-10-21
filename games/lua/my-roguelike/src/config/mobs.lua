-- config/mobs.lua
-- Mob configurations (data-driven)
-- Format:
-- {
--   id = "unique_id",
--   name = "Mob Name",
--   type = "melee" | "ranged",
--   spritesheet = "filename" (spritesheet file from assets/, without .png),
--   spriteIndex = number (index in spritesheet, 1-based),
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
--   xpDrop = number,
--   xpDropGrowth = number (per level)
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
        spritesheet = "monsters",  -- monsters.png from assets/
        spriteIndex = 27,  -- Zombie from monsters.png (5.f zombie)
        
        baseHp = 50,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 60,
        speedGrowth = 1,
        baseDamage = 10,
        damageGrowth = 3,
        
        attackSpeed = 1.0,  -- 1 attack per second
        
        xpDrop = 10,
        xpDropGrowth = 2
    }
}

return mobs

