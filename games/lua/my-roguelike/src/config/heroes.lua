-- config/heroes.lua
-- Hero configurations (data-driven)
-- Each hero has: base stats, stat growth, innate skill
-- Starting skill is chosen separately from config/starting_skills.lua
-- Format:
-- {
--   id = "unique_id",
--   name = "Hero Name",
--   assetFolder = "foldername" (folder in assets/heroes/ containing sprite files),
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
--   baseCastSpeed = number (multiplier, 1.0 = normal),
--   castSpeedGrowth = number,
--   spriteSize = number (optional, display size in pixels, default: 64)
--   -- hitboxRadius calculated automatically: spriteSize * 0.4
--   innateSkill = table (passive modifier)
-- }

local heroes = {
    -- === BASELINE HERO (REFERENCE FOR BALANCE) ===
    -- {
    --     id = "baseline_hero",
    --     name = "Baseline Hero",
    --     spriteIndex = 1,
    --     
    --     baseHp = 100,        -- Standard HP
    --     hpGrowth = 15,       -- Moderate HP growth
    --     baseArmor = 2,        -- Some armor
    --     armorGrowth = 0.8,    -- Decent armor scaling
    --     baseMoveSpeed = 100,  -- Standard speed
    --     speedGrowth = 1.5,    -- Moderate speed growth
    --     baseCastSpeed = 1.0,  -- Normal cast speed
    --     castSpeedGrowth = 0.03,
    --     
    --     innateSkill = {
    --         id = "baseline_innate",
    --         name = "Balanced",
    --         description = "No special modifiers",
    --         modifiers = {}
    --     },
    -- },

    -- === MAGE (medium size) ===
    {
        id = "сhronomancer",
        name = "Chronomancer",
        assetFolder = "сhronomancer",  -- assets/heroes/сhronomancer/ folder
        -- Contains: i.png (idle), 1.png, 2.png (idle animation), a.png (attack)
        -- All sprites face RIGHT and are auto-scaled
        
        baseHp = 80,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 100,
        speedGrowth = 1,
        baseCastSpeed = 1.3,  -- Casts faster
        castSpeedGrowth = 0.05,

        -- Size parameters (optional, uses defaults if not specified)
        spriteSize = 64,      -- Display size in pixels (default: 64)

        innateSkill = {
            id = "сhronomancer_innate",
            name = "Spell Mastery",
            description = "All skills have 30% shorter cooldowns",
            modifiers = {
                cooldownReduction = 0.3
            }
        }
    }
}

return heroes

