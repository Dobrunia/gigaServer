local heroes = {
    ["сhronomancer"] = {
        id = "сhronomancer",
        name = "Chronomancer",
        baseHp = 80,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 100,
        speedGrowth = 1,
        width = 64,
        height = 64,
        innateSkill = {
            id = "сhronomancer_innate",
            name = "Spell Mastery",
            description = "All skills have 30% shorter cooldowns",
            modifiers = {
                cooldownReduction = 0.3
            }
        }
    }
}

return heroes