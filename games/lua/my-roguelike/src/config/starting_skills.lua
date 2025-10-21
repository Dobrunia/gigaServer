-- config/starting_skills.lua
-- Starting skill configurations (data-driven)
-- After character selection, player chooses ONE starting skill from this pool
-- These skills occupy the first active skill slot
-- Format:
-- {
--   id = "unique_id",
--   name = "Skill Name",
--   description = "What the skill does",
--   type = "projectile" | "aoe" | "buff" | "summon",
--   cooldown = number (seconds),
--   damage = number (base damage),
--   range = number (pixels),
--   projectileSpeed = number (pixels/sec, if type = projectile),
--   effect = table (optional status effect)
-- }

local startingSkills = {
    -- === BASELINE SKILL (REFERENCE FOR BALANCE) ===
    -- {
    --     id = "basic_attack",
    --     name = "Basic Attack",
    --     description = "Standard projectile attack",
    --     type = "projectile",
    --     cooldown = 2.0,
    --     damage = 25,
    --     range = 300,
    --     projectileSpeed = 250
    -- },

    -- === FIREBALL ===
    {
        id = "fireball",
        name = "Fireball",
        description = "Shoots a burning projectile that deals damage over time",
        type = "projectile",
        cooldown = 1.5,
        damage = 40,
        range = 400,
        projectileSpeed = 300,
        effect = {
            type = "poison",  -- Fire DOT (reusing poison mechanics)
            duration = 3,
            damage = 5,
            tickRate = 0.5
        }
    },

    -- === ICE SHARD ===
    {
        id = "ice_shard",
        name = "Ice Shard",
        description = "Launches a freezing projectile that slows enemies",
        type = "projectile",
        cooldown = 2.0,
        damage = 30,
        range = 350,
        projectileSpeed = 280,
        effect = {
            type = "slow",
            duration = 2,
            slowPercent = 0.5  -- 50% slow
        }
    },

    -- === POISON DART ===
    {
        id = "poison_dart",
        name = "Poison Dart",
        description = "Fast projectile with strong poison effect",
        type = "projectile",
        cooldown = 1.8,
        damage = 20,
        range = 380,
        projectileSpeed = 350,
        effect = {
            type = "poison",
            duration = 5,
            damage = 8,
            tickRate = 0.5
        }
    },

    -- === ARCANE BOLT ===
    {
        id = "arcane_bolt",
        name = "Arcane Bolt",
        description = "Pure magic damage with fast cooldown",
        type = "projectile",
        cooldown = 1.2,
        damage = 35,
        range = 320,
        projectileSpeed = 320
    }
}

return startingSkills

