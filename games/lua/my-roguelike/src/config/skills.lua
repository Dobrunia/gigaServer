-- config/skills.lua
-- Skill configurations for level-up choices
-- Format:
-- {
--   id = "unique_id",
--   name = "Skill Name",
--   description = "What it does",
--   type = "projectile" | "aoe" | "buff",
--   cooldown = number (seconds),
--   damage = number (optional),
--   range = number (distance),
--   radius = number (for aoe),
--   projectileSpeed = number (for projectile),
--   effect = table (status effect: {type, duration, params})
-- }

local skills = {
    -- === PROJECTILE SKILLS ===
    {
        id = "ice_bolt",
        name = "Ice Bolt",
        description = "Shoots an ice projectile that slows enemies",
        type = "projectile",
        cooldown = 1.2,
        damage = 30,
        range = 400,
        projectileSpeed = 350,
        effect = {
            type = "slow",
            duration = 2,
            slowPercent = 50
        }
    },
    
    {
        id = "lightning_bolt",
        name = "Lightning",
        description = "Fast projectile with stun",
        type = "projectile",
        cooldown = 2.0,
        damage = 45,
        range = 500,
        projectileSpeed = 600,
        effect = {
            type = "stun",
            duration = 1
        }
    },
    
    {
        id = "acid_spit",
        name = "Acid Spit",
        description = "Projectile that applies poison DOT",
        type = "projectile",
        cooldown = 1.5,
        damage = 20,
        range = 350,
        projectileSpeed = 300,
        effect = {
            type = "poison",
            duration = 6,
            damage = 10,
            tickRate = 0.5
        }
    },
    
    -- === AOE SKILLS ===
    {
        id = "frost_nova",
        name = "Frost Nova",
        description = "Freezes enemies in area",
        type = "aoe",
        cooldown = 3.0,
        damage = 40,
        range = 0,  -- Cast at player position
        radius = 150,
        effect = {
            type = "root",
            duration = 2
        }
    },
    
    {
        id = "meteor",
        name = "Meteor",
        description = "Massive damage in area",
        type = "aoe",
        cooldown = 4.0,
        damage = 100,
        range = 200,  -- Cast ahead of player
        radius = 180,
        effect = nil
    },
    
    {
        id = "poison_cloud",
        name = "Poison Cloud",
        description = "Creates poison cloud at target location",
        type = "aoe",
        cooldown = 2.5,
        damage = 25,
        range = 150,
        radius = 120,
        effect = {
            type = "poison",
            duration = 5,
            damage = 8,
            tickRate = 0.5
        }
    },
    
    -- === BUFF SKILLS ===
    {
        id = "speed_boost",
        name = "Speed Boost",
        description = "Increase movement speed temporarily",
        type = "buff",
        cooldown = 8.0,
        damage = 0,
        effect = {
            type = "speed_buff",
            duration = 5,
            speedMultiplier = 1.5
        }
    },
    
    {
        id = "shield",
        name = "Shield",
        description = "Temporary armor boost",
        type = "buff",
        cooldown = 10.0,
        damage = 0,
        effect = {
            type = "armor_buff",
            duration = 6,
            bonusArmor = 10
        }
    },
    
    -- === SPECIAL SKILLS ===
    {
        id = "multi_shot",
        name = "Multi Shot",
        description = "Fires 3 projectiles in a cone",
        type = "projectile",
        cooldown = 1.8,
        damage = 25,
        range = 350,
        projectileSpeed = 400,
        projectileCount = 3,  -- Special: spawn multiple projectiles
        spreadAngle = 0.3,     -- Radians
        effect = nil
    },
    
    {
        id = "chain_lightning",
        name = "Chain Lightning",
        description = "Lightning that chains between enemies",
        type = "projectile",
        cooldown = 2.5,
        damage = 35,
        range = 400,
        projectileSpeed = 500,
        chainCount = 3,  -- Special: chains to 3 additional targets
        effect = {
            type = "stun",
            duration = 0.5
        }
    },
    
    -- === PASSIVE UPGRADES (treated as skills) ===
    {
        id = "damage_boost",
        name = "Damage Up",
        description = "+10% damage to all skills",
        type = "passive",
        modifiers = {
            damageMultiplier = 1.1
        }
    },
    
    {
        id = "cooldown_reduction",
        name = "Quick Cast",
        description = "-10% cooldown on all skills",
        type = "passive",
        modifiers = {
            cooldownReduction = 0.1
        }
    },
    
    {
        id = "extra_range",
        name = "Long Range",
        description = "+20% range on all skills",
        type = "passive",
        modifiers = {
            rangeMultiplier = 1.2
        }
    }
}

return skills

