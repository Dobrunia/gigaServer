local mobs = {
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
        projectileAssetFolder = "skills/poison-fireball",
        
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

