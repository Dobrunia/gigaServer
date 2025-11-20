-- Базовый герой
-- базовое хп 100
-- прирост хп 5
-- базовый армор 3
-- прирост армора 0.3
-- скорость перед 250
-- прирост ск 5
-- радиус подбор опыта 100

local heroes = {
    ["сhronomancer"] = {
        id = "сhronomancer",
        name = "Chronomancer",
        baseHp = 90,
        hpGrowth = 4,
        baseArmor = 2,
        armorGrowth = 0.2,
        baseMoveSpeed = 230,
        speedGrowth = 5,
        width = 64,
        height = 64,
        pickupRange = 200,
        innateSkill = {
            id = "сhronomancer_innate",
            name = "Spell Mastery",
            description = "All skills have 30% shorter cooldowns",
            modifiers = {
                cooldownReduction = 0.3
            }
        },
        quads = {
            idle = {
                row = 1,
                col = 1
            },
            innateSkill = {
                row = 1,
                col = 2
            },
            walk = {
                startrow = 1,
                startcol = 3,
                endrow = 1,
                endcol = 4
            },
            cast = {
                row = 1,
                col = 5
            }
        }
    }
}

return heroes