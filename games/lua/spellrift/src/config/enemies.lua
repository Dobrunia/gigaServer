local enemies = {
    -- === MELEE MOB ===
    -- zombie = {
    --     id = "zombie",
    --     name = "Zombie",
    --     --type = "melee",
    --     baseHp = 50,
    --     hpGrowth = 10,
    --     baseArmor = 0,
    --     armorGrowth = 0.5,
    --     baseMoveSpeed = 60,
    --     speedGrowth = 5,
    --     baseDamage = 10,
    --     damageGrowth = 3,
        
    --     xpDrop = 10,
    --     xpDropGrowth = 2,
    --     xpDropSpritesheet = "items",

    --     -- Spawn parameters
    --     spawnWeight = 1,            -- Common mob (1=very common, 10=very rare)
    --     spawnStartTime = 0,         -- Can spawn from game start
    --     spawnEndTime = nil,         -- Spawns forever (no end time)
    --     spawnGroupSize = 1,         -- Single mob spawns

    --     quads = {
    --         idle = {
    --             row = 1,
    --             col = 1,
    --             tileWidth = 64,
    --             tileHeight = 64
    --         },
    --         walk = {
    --             startrow = 1,
    --             startcol = 2,
    --             endrow = 1,
    --             endcol = 3,
    --             tileWidth = 64,
    --             tileHeight = 64,
    --         },
    --         cast = {
    --             row = 1,
    --             col = 4,
    --             tileWidth = 64,
    --             tileHeight = 64,
    --         }
    --     }
    -- },


    -- === RANGED MOB ===
    fireclaw = {
        id = "fireclaw",
        name = "Fireclaw",
        type = "ranged",
        
        baseHp = 30,
        hpGrowth = 5,
        baseArmor = 0,
        armorGrowth = 0.2,
        baseMoveSpeed = 40,
        speedGrowth = 1,
        
        skills = {'green-fireball'},

        drop = {
            id = "xp",
            name = "XP",
            description = "XP",
            type = "xp",

            value = 15,
            valueGrowth = 3,

            width = 32,
            height = 32,
        
            quads = {
                idle = {
                    row = 1,
                    col = 1
                }
            }
        },
        
        -- Spawn parameters
        spawnWeight = 3,
        spawnStartTime = 0,
        spawnEndTime = nil,
        spawnGroupSize = 2,

        width = 32,
        height = 32,

        quads = {
            idle = {
                row = 1,
                col = 1,
            },
            walk = {
                startrow = 1,
                startcol = 2,
                endrow = 1,
                endcol = 3,
            },
            cast = {
                row = 1,
                col = 4,
            }
        }
    }
}

return enemies

