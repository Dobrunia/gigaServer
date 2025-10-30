local enemies = {
    -- === MELEE MOB ===
    zombie = {
        id = "zombie",
        name = "Zombie",
        --type = "melee",
        baseHp = 50,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 60,
        speedGrowth = 5,
        baseDamage = 10,
        damageGrowth = 3,
        
        skills = {'zombie-cleave'},

        drop = {
            id = "xp",
            name = "XP",
            description = "XP",
            type = "xp",

            value = 10,
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

        width = 32,
        height = 32,

        -- Spawn parameters
        spawnWeight = 1,            -- Common mob (1=very common, 10=very rare)
        spawnStartTime = 0,         -- Can spawn from game start
        spawnEndTime = nil,         -- Spawns forever (no end time)
        spawnGroupSize = 1,         -- Single mob spawns

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
    },


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
    },

    satyr = {
        id = "satyr",
        name = "Satyr",
        type = "ranged",
        
        baseHp = 15,
        hpGrowth = 3,
        baseArmor = 0,
        armorGrowth = 0.2,
        baseMoveSpeed = 50,
        speedGrowth = 1,
        
        skills = {'satyr-boomerang'},

        drop = {
            id = "xp",
            name = "XP",
            description = "XP",
            type = "xp",

            value = 25,
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
        spawnWeight = 6,
        spawnStartTime = 0,
        spawnEndTime = nil,
        spawnGroupSize = 1,

        width = 32,
        height = 32,

        quads = {
            idle = {
                row = 1,
                col = 1,
            },
            walk = {
                startrow = 1,
                startcol = 7,
                endrow = 1,
                endcol = 18,
            },
            cast = {
                startrow = 1,
                startcol = 19, -- реализовать поддержку start/end, как возможный вариант
                endrow = 1,
                endcol = 27,
            },
            die = { -- реализовать поддержку
                startrow = 1,
                startcol = 28,
                endrow = 1,
                endcol = 31,
            }
        }
    }
}

return enemies

