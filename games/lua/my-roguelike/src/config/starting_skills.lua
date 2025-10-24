local startingSkills = {
    -- PROJECTILE SKILL
    {
        id = "fireball",
        name = "Fireball",
        description = "Shoots a burning projectile that deals damage over time",
        type = "projectile",
        cooldown = 3,
        damage = 40,
        range = 400,
        projectileSpeed = 300,
        hitboxRadius = 14,
        assetFolder = "skills/fireballl",
        animationSpeed = 0.15,
        effect = {
            type = "burning",
            duration = 3,
            damage = 5,
            tickRate = 0.5
        }
    },
    {
        id = "crimson-volley",
        name = "Crimson Volley",
        description = "Стреляет кровавыми стрелами во всех направлениях",
        type = "projectile",
        cooldown = 8,
        damage = 30,
        range = 300,
        projectileSpeed = 400,
        hitboxRadius = 14,
        assetFolder = "skills/crimson-volley",
        animationSpeed = 0.05,
        direction = 8,
    },
    
    -- ORBITAL SKILL
    {
        id = "axe-whirlwind",
        name = "Axe Whirlwind",
        description = "Flying axes orbit around you, dealing damage to enemies",
        type = "orbital",
        cooldown = 4,
        damage = 15,
        orbitalCount = 3,
        orbitalRadius = 100,
        orbitalSpeed = 1.5,
        duration = 5,
        hitboxRadius = 20,
        assetFolder = "skills/axe-whirlwind",
        spinSpeed = 6.0
    },
    
    -- AOE SKILL
    -- BUFF SKILL
    -- SUMMON SKILL
    -- AURA SKILL
    {
        id = "satan-aura",
        name = "Satan Aura",
        description = "Creates a satan aura around the player that deals damage over time",
        assetFolder = "skills/satan-aura",
        type = "aura",
        cooldown = 14,
        damage = 5,
        radius = 200,
        tickRate = 0.3,
        duration = 8,
    },
    -- LASER SKILL
}

return startingSkills

