-- config/mobs.lua
-- Mob configurations (data-driven)
-- Format:
-- {
--   id = "unique_id",
--   name = "Mob Name",
--   type = "melee" | "ranged",
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
    -- === MELEE MOB ===
    {
        id = "zombie",
        name = "Zombie",
        type = "melee",
        
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
    },
    
    -- === FAST MELEE MOB ===
    {
        id = "ghoul",
        name = "Ghoul",
        type = "melee",
        
        baseHp = 30,
        hpGrowth = 7,
        baseArmor = 0,
        armorGrowth = 0.2,
        baseMoveSpeed = 120,  -- Fast
        speedGrowth = 2,
        baseDamage = 8,
        damageGrowth = 2,
        
        attackSpeed = 1.5,  -- Fast attacks
        
        xpDrop = 8,
        xpDropGrowth = 1.5
    },
    
    -- === RANGED MOB ===
    {
        id = "archer",
        name = "Skeleton Archer",
        type = "ranged",
        
        baseHp = 40,
        hpGrowth = 8,
        baseArmor = 0,
        armorGrowth = 0.3,
        baseMoveSpeed = 70,
        speedGrowth = 1,
        baseDamage = 12,
        damageGrowth = 3,
        
        attackSpeed = 0.8,  -- Slower than melee
        attackRange = 300,
        projectileSpeed = 200,
        
        xpDrop = 12,
        xpDropGrowth = 2
    },
    
    -- === STRONG RANGED MOB ===
    {
        id = "mage_mob",
        name = "Dark Mage",
        type = "ranged",
        
        baseHp = 35,
        hpGrowth = 6,
        baseArmor = 0,
        armorGrowth = 0.2,
        baseMoveSpeed = 50,
        speedGrowth = 0.5,
        baseDamage = 20,
        damageGrowth = 5,
        
        attackSpeed = 0.5,  -- Slow but powerful
        attackRange = 400,
        projectileSpeed = 150,
        
        xpDrop = 15,
        xpDropGrowth = 3
    },
    
    -- === TANK MELEE MOB ===
    {
        id = "ogre",
        name = "Ogre",
        type = "melee",
        
        baseHp = 120,
        hpGrowth = 20,
        baseArmor = 3,
        armorGrowth = 1,
        baseMoveSpeed = 40,  -- Very slow
        speedGrowth = 0.5,
        baseDamage = 25,
        damageGrowth = 5,
        
        attackSpeed = 0.6,  -- Slow but hard-hitting
        
        xpDrop = 25,
        xpDropGrowth = 4
    }
}

return mobs

