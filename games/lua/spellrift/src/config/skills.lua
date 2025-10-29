local Skills = {}

Skills["fireball"] = {
    id = "fireball",
    name = "Fireball",
    description = "Shoots a fireball that deals damage to enemies",
    type = "projectile",
    isStartingSkill = true,
    
    -- Базовые характеристики
    stats = {
        damage = 40,           -- Урон при попадании
        cooldown = 3.0,        -- Кулдаун скилла
        range = 250,           -- Дальность полета
        speed = 180,           -- Скорость снаряда
        radius = 15,           -- Радиус проджектаила
        
        -- Параметры дебаффа
        debuffType = "burn", -- Тип дебаффа
        debuffDuration = 5.0, -- Длительность отравления
        debuffDamage = 8,     -- Урон за тик
        debuffTickRate = 1.0  -- Частота тиков
    },

    width = 32,
    height = 32,

    quads = {
        idle = {
            row = 1,
            col = 1
        },
        fly = {
            startrow = 1,
            startcol = 2,
            endrow = 1,
            endcol = 4,
        },
        hit = {
            row = 1,
            col = 5,
        }
    },
    -- Апгрейды по уровням
    upgrades = {
        -- Level 2: больше урона и дольше
        {
            damage = 60,
            debuffDuration = 6.0,
            debuffDamage = 12
        },
        -- Level 3: быстрее кулдаун и сильнее
        {
            damage = 80,
            cooldown = 2.5,
            debuffDuration = 7.0,
            debuffDamage = 15,
            debuffTickRate = 0.8
        },
        -- Level 4: максимальная мощь
        {
            damage = 100,
            cooldown = 2.0,
            range = 300,
            debuffDuration = 8.0,
            debuffDamage = 20,
            debuffTickRate = 0.6
        }
    }
}

Skills["green-fireball"] = {
    id = "green-fireball",
    name = "Green Fireball",
    description = "Shoots a green fireball that deals damage to enemies",
    type = "projectile",
    
    -- Базовые характеристики
    stats = {
        damage = 20,           -- Урон при попадании
        cooldown = 3.0,        -- Кулдаун скилла
        range = 250,           -- Дальность полета
        speed = 100,           -- Скорость снаряда
        radius = 15,           -- Радиус проджектаила
        
        -- Параметры дебаффа
        debuffType = "burn", -- Тип дебаффа
        debuffDuration = 3.0, -- Длительность отравления
        debuffDamage = 5,     -- Урон за тик
        debuffTickRate = 0.3  -- Частота тиков
    },

    width = 32,
    height = 32,

    quads = {
        idle = {
            row = 1,
            col = 1
        },
        fly = {
            startrow = 1,
            startcol = 2,
            endrow = 1,
            endcol = 4,
        },
        hit = {
            row = 1,
            col = 5,
        }
    },
    -- Апгрейды по уровням
    upgrades = {
        -- Level 2: больше урона и дольше
        {
            damage = 30,
            debuffDuration = 4.0,
            debuffDamage = 7
        },
        -- Level 3: быстрее кулдаун и сильнее
        {
            damage = 40,
            cooldown = 2.5,
            debuffDuration = 5.0,
            debuffDamage = 9,
            debuffTickRate = 0.5
        },
        -- Level 4: максимальная мощь
        {
            damage = 50,
            cooldown = 2.0,
            range = 250,
            debuffDuration = 6.0,
            debuffDamage = 12,
            debuffTickRate = 0.4
        }
    }
}

-- === MELEE SKILL ===
Skills["zombie-cleave"] = {
    id = "zombie-cleave",
    name = "Zombie Cleave",
    description = "Cleaves the ground in front of the zombie, dealing damage to enemies in a cone",
    type = "melee",

    stats = {
        -- боевые
        damage = 35,
        cooldown = 2.0,
        range = 80,            -- триггер-дистанция для AI (если не передан tx,ty)
        hitMaxTargets = 0,     -- 0 = без лимита
        knockback = 0,

        -- геометрия сектора
        arcAngleDeg = 30,     -- 360 = круг
        arcRadius = 80,
        arcInnerRadius = 0,
        arcOffsetDeg = 0,

        -- тайминги
        windup = 0.8,         -- замах
        active = 0.05,         -- окно урона

        -- поведение наведения
        followAim = true,            -- брать направление от цели/курсора
        directionMode = "free",      -- "free" | "horizontal" | "vertical"
        trackDuringWindup = true,    -- сектор «прилипает» во время замаха
        lockMovement = false,        -- при желании можно учитывать во внешней логике
        centerOffset = 10,           -- слегка вынести удар вперёд

        -- визуал телеграфа
        telegraphColor = {1,1,1},
        telegraphAlpha = 0.15,
    },

    upgrades = {
        { damage = 80, cooldown = 0.85, arcAngleDeg = 140 },
        { damage = 100, cooldown = 0.7, arcAngleDeg = 160 },
    }
}

return Skills