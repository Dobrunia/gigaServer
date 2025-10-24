-- config/starting_skills.lua
-- Starting skill configurations (data-driven)
-- After character selection, player chooses ONE starting skill from this pool
-- These skills occupy the first active skill slot
--
-- === STARTING SKILL TYPES AND PARAMETERS ===
--
-- COMMON PARAMETERS (all skill types):
--   id = "unique_id"                    -- Unique identifier
--   name = "Skill Name"                 -- Display name
--   description = "What it does"        -- Tooltip description
--   assetFolder = "foldername"          -- Folder in assets/ containing sprite files
--   animationSpeed = number             -- Animation speed (default: 0.1)
--   effect = table                      -- Status effect: {type, duration, params} (optional)
--
-- SPRITE FILES IN FOLDER:
--   i.png - icon for UI/menu (any size, auto-scaled)
--   h.png - hit effect (optional, any size, auto-scaled)
--   1.png, 2.png, 3.png... - flight animation frames (any size, auto-scaled)
--   aura.png - aura visual effect around player (for aura skills only)
--   NOTE: All sprites should be oriented FACING RIGHT
--
-- TYPE: "projectile" (ranged attack that travels to target)
--   cooldown = number                   -- Skill cooldown in seconds (base: 2.0)
--   damage = number                     -- Damage dealt on hit (base: 25)
--   range = number                      -- Maximum travel distance (base: 300)
--   projectileSpeed = number            -- Travel speed of projectile (base: 250)
--   hitboxRadius = number               -- Collision radius of projectile (base: 6)
--
-- TYPE: "aoe" (area of effect around caster by default)
--   cooldown = number                   -- Skill cooldown in seconds (base: 3.0, mult: 1.5x)
--   damage = number                     -- Damage dealt to all targets in radius (base: 37.5, mult: 1.5x)
--   radius = number                     -- Area of effect radius (base: 100)
--   
--   Optional for projectile-triggered AOE (explodes on impact):
--   range = number                      -- Projectile travel distance (base: 300)
--   projectileSpeed = number            -- Projectile travel speed (base: 250)
--   hitboxRadius = number               -- Projectile collision radius (base: 6)
--
-- TYPE: "buff" (applies beneficial effect to caster)
--   cooldown = number                   -- Skill cooldown in seconds (base: 4.0, mult: 2.0x)
--   buffEffect = table                  -- Buff effect: {type, duration, params}
--
-- TYPE: "summon" (spawns allied creature)
--   cooldown = number                   -- Skill cooldown in seconds (base: 6.0, mult: 3.0x)
--   damage = number                     -- Summon's attack damage (base: 25)
--   summonSpeed = number                -- Summon's movement speed (base: 100)
--   summonHp = number                   -- Summon's health points (base: 50)
--   summonArmor = number                -- Summon's armor value (base: 0)
--
-- TYPE: "aura" (continuous area effect around caster)
--   cooldown = number                   -- Aura activation cooldown (base: 1.0, mult: 0.5x)
--   damage = number                     -- Damage per tick (base: 7.5, mult: 0.3x)
--   radius = number                     -- Aura radius (base: 100)
--   tickRate = number                   -- Damage application frequency (base: 1.0)
--   duration = number                    -- Aura duration in seconds (base: 10.0)
--   REQUIRES: i.png (UI icon) + aura.png (visual effect around player)
--
-- TYPE: "laser" (continuous beam attack to single target)
--   cooldown = number                   -- Skill cooldown in seconds (base: 2.4, mult: 1.2x)
--   range = number                      -- Maximum beam range (base: 300)
--   damage = number                     -- Damage per tick (base: 15, mult: 0.6x)
--   tickRate = number                   -- Damage application frequency (base: 1.0)

local startingSkills = {
    -- === TEST STARTING SKILLS FOR ALL TYPES ===
    
    -- PROJECTILE SKILL
    {
        id = "fireball",
        name = "Fireball",
        description = "Shoots a burning projectile that deals damage over time",
        type = "projectile",
        cooldown = 3,
        damage = 40,
        range = 400,
        projectileSpeed = 300,
        hitboxRadius = 14,
        assetFolder = "starting_skills/fireballl",
        animationSpeed = 0.15,
        effect = {
            type = "burning",
            duration = 3,
            damage = 5,
            tickRate = 0.5
        }
    },
    {
        id = "crimson-volley",
        name = "Crimson Volley",
        description = "Стреляет кровавыми стрелами во всех направлениях",
        type = "projectile",
        cooldown = 8,
        damage = 30,
        range = 300,
        projectileSpeed = 400,
        hitboxRadius = 14,
        assetFolder = "skills/crimson-volley",
        animationSpeed = 0.05,
    },
    
    -- AOE SKILL
    -- BUFF SKILL
    -- SUMMON SKILL
    -- AURA SKILL
    {
        id = "satan-aura",
        name = "Satan Aura",
        description = "Creates a satan aura around the player that deals damage over time",
        assetFolder = "skills/satan-aura",
        type = "aura",
        cooldown = 14,
        damage = 5,
        radius = 200,
        tickRate = 0.3,
        duration = 8,
    },
    -- LASER SKILL
}

return startingSkills

