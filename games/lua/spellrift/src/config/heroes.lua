local heroes = {
    ["сhronomancer"] = {
        id = "сhronomancer",
        name = "Chronomancer",
        baseHp = 1180,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 100,
        speedGrowth = 1,
        width = 64,
        height = 64,
        pickupRange = 100,
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