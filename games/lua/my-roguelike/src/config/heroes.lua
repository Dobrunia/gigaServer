-- config/heroes.lua
-- Hero configurations (data-driven)
-- Each hero has: base stats, stat growth, innate skill, starting skill
-- Format:
-- {
--   id = "unique_id",
--   name = "Hero Name",
--   baseHp = number,
--   hpGrowth = number (per level),
--   baseArmor = number,
--   armorGrowth = number,
--   baseMoveSpeed = number,
--   speedGrowth = number,
--   baseCastSpeed = number (multiplier, 1.0 = normal),
--   castSpeedGrowth = number,
--   innateSkill = table (passive modifier),
--   startingSkill = table (first active skill)
-- }

local heroes = {
    -- === HERO 1: WARRIOR ===
    {
        id = "warrior",
        name = "Warrior",
        
        -- Base stats
        baseHp = 150,
        hpGrowth = 20,
        baseArmor = 5,
        armorGrowth = 1.5,
        baseMoveSpeed = 120,
        speedGrowth = 2,
        baseCastSpeed = 1.0,
        castSpeedGrowth = 0.02,
        
        -- Innate: +1 skill slot, more armor from items
        innateSkill = {
            id = "warrior_innate",
            name = "Tank",
            description = "Start with +50 HP, armor is 20% more effective",
            modifiers = {
                maxSkillSlots = 5,  -- Override default 4
                armorMultiplier = 1.2
            }
        },
        
        -- Starting skill
        startingSkill = {
            id = "slash",
            name = "Slash",
            type = "projectile",
            cooldown = 1.0,
            damage = 25,
            range = 200,
            projectileSpeed = 400,
            effect = nil
        }
    },
    
    -- === HERO 2: MAGE ===
    {
        id = "mage",
        name = "Mage",
        
        baseHp = 80,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 100,
        speedGrowth = 1,
        baseCastSpeed = 1.3,  -- Casts faster
        castSpeedGrowth = 0.05,
        
        innateSkill = {
            id = "mage_innate",
            name = "Spell Mastery",
            description = "All skills have 30% shorter cooldowns",
            modifiers = {
                cooldownReduction = 0.3
            }
        },
        
        startingSkill = {
            id = "fireball",
            name = "Fireball",
            type = "projectile",
            cooldown = 1.5,
            damage = 40,
            range = 400,
            projectileSpeed = 300,
            effect = {
                type = "poison",  -- Fire DOT
                duration = 3,
                damage = 5,
                tickRate = 0.5
            }
        }
    },
    
    -- === HERO 3: ROGUE ===
    {
        id = "rogue",
        name = "Rogue",
        
        baseHp = 100,
        hpGrowth = 12,
        baseArmor = 2,
        armorGrowth = 0.8,
        baseMoveSpeed = 150,  -- Fast
        speedGrowth = 3,
        baseCastSpeed = 1.1,
        castSpeedGrowth = 0.03,
        
        innateSkill = {
            id = "rogue_innate",
            name = "Poison Master",
            description = "All poison effects tick 2x faster (every 0.25s instead of 0.5s)",
            modifiers = {
                poisonTickRate = 0.25
            }
        },
        
        startingSkill = {
            id = "poison_dart",
            name = "Poison Dart",
            type = "projectile",
            cooldown = 0.8,
            damage = 15,
            range = 350,
            projectileSpeed = 500,
            effect = {
                type = "poison",
                duration = 5,
                damage = 8,
                tickRate = 0.5  -- Will be modified by innate
            }
        }
    },
    
    -- === HERO 4: TANK ===
    {
        id = "tank",
        name = "Tank",
        
        baseHp = 200,
        hpGrowth = 25,
        baseArmor = 8,
        armorGrowth = 2,
        baseMoveSpeed = 90,  -- Slow
        speedGrowth = 1,
        baseCastSpeed = 0.8,  -- Casts slower
        castSpeedGrowth = 0.01,
        
        innateSkill = {
            id = "tank_innate",
            name = "Immovable",
            description = "Cannot be slowed or rooted. +5 armor.",
            modifiers = {
                immuneToSlow = true,
                immuneToRoot = true,
                bonusArmor = 5
            }
        },
        
        startingSkill = {
            id = "ground_slam",
            name = "Ground Slam",
            type = "aoe",
            cooldown = 2.0,
            damage = 35,
            range = 150,
            radius = 150,
            effect = {
                type = "stun",
                duration = 1.5
            }
        }
    }
}

return heroes

