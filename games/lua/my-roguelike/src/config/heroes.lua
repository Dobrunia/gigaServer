local heroes = {
    -- === MAGE ===
    {
        id = "сhronomancer",
        name = "Chronomancer",
        assetFolder = "сhronomancer",  -- assets/heroes/сhronomancer/ folder
        -- Contains: i.png (idle), 1.png, 2.png (idle animation), a.png (attack)
        -- All sprites face RIGHT and are auto-scaled
        
        baseHp = 80,
        hpGrowth = 10,
        baseArmor = 0,
        armorGrowth = 0.5,
        baseMoveSpeed = 100,
        speedGrowth = 1,
        baseCastSpeed = 1.3,  -- Casts faster
        castSpeedGrowth = 0.05,

        -- Size parameters (optional, uses defaults if not specified)
        spriteSize = 64,      -- Display size in pixels (default: 64)

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

