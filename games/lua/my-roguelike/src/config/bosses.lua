-- config/bosses.lua
-- Boss configurations (similar to mobs but stronger)
-- Bosses are just powerful mobs with special stats
-- Format: Same as mobs.lua, but includes spriteIndex (from monsters.png)

local bosses = {
    -- === BOSS 1: ZOMBIE LORD ===
    {
        id = "zombie_lord",
        name = "Zombie Lord",
        type = "melee",
        spriteIndex = 67,  -- Lich from monsters.png (row 5, col 3)
        
        baseHp = 500,
        hpGrowth = 100,
        baseArmor = 5,
        armorGrowth = 2,
        baseMoveSpeed = 80,
        speedGrowth = 2,
        baseDamage = 40,
        damageGrowth = 10,
        
        attackSpeed = 1.2,
        
        xpDrop = 200,
        xpDropGrowth = 50
    },
    
    -- === BOSS 2: DARK SORCERER ===
    {
        id = "dark_sorcerer",
        name = "Dark Sorcerer",
        type = "ranged",
        spriteIndex = 84,  -- Cultist from monsters.png (row 6, col 4)
        
        baseHp = 400,
        hpGrowth = 80,
        baseArmor = 2,
        armorGrowth = 1,
        baseMoveSpeed = 60,
        speedGrowth = 1,
        baseDamage = 60,
        damageGrowth = 15,
        
        attackSpeed = 0.8,
        attackRange = 500,
        projectileSpeed = 250,
        
        xpDrop = 250,
        xpDropGrowth = 60
    },
    
    -- === BOSS 3: GIANT OGRE ===
    {
        id = "giant_ogre",
        name = "Giant Ogre",
        type = "melee",
        spriteIndex = 17,  -- Ettin from monsters.png (row 2, col 1)
        
        baseHp = 800,
        hpGrowth = 150,
        baseArmor = 10,
        armorGrowth = 3,
        baseMoveSpeed = 50,
        speedGrowth = 1,
        baseDamage = 70,
        damageGrowth = 20,
        
        attackSpeed = 0.5,  -- Slow but devastating
        
        xpDrop = 300,
        xpDropGrowth = 80
    }
}

return bosses

