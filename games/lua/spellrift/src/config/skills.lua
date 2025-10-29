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
        radius = 14,           -- Радиус проджектаила
        
        -- Параметры дебаффа
        debuffType = "burn", -- Тип дебаффа
        debuffDuration = 5.0, -- Длительность отравления
        debuffDamage = 8,     -- Урон за тик
        debuffTickRate = 1.0  -- Частота тиков
    },


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
        radius = 14,           -- Радиус проджектаила
        
        -- Параметры дебаффа
        debuffType = "burn", -- Тип дебаффа
        debuffDuration = 3.0, -- Длительность отравления
        debuffDamage = 5,     -- Урон за тик
        debuffTickRate = 0.3  -- Частота тиков
    },


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

-- === MELEE SKILLS ===
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

-- === VOLLEY SKILLS ===
Skills["crimson-volley"] = {
    id = "crimson-volley",
    name = "Crimson Volley",
    description = "Shoots a volley of crimson arrows in 8 directions",
    type = "volley",
    isStartingSkill = true,
    
    -- Базовые характеристики
    stats = {
        damage = 30,           -- Урон при попадании
        cooldown = 3.0,        -- Кулдаун скилла
        range = 300,           -- Дальность полета
        speed = 300,           -- Скорость снаряда
        radius = 14,           -- Радиус проджектаила
        direction = 8,         -- Количество направлений (4 = крест, 8 = + диагонали)
    },


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
            damage = 40,
            range = 350,
        },
        -- Level 3: быстрее кулдаун и сильнее
        {
            damage = 50,
            cooldown = 2.5,
            range = 400,
        },
        -- Level 4: максимальная мощь
        {
            damage = 60,
            cooldown = 1.5,
        }
    }
}

-- === ORBITAL SKILLS ===
Skills["axe-whirlwind"] = {
    id = "axe-whirlwind",
    name = "Axe Whirlwind",
    description = "Flying axes orbit around you, dealing damage to enemies",
    type = "orbital",
    isStartingSkill = true,
    stats = {
        -- боевые
        damage = 15,                    -- Урон за попадание
        cooldown = 12.0,                 -- Кулдаун скилла
        radius = 20,                    -- Радиус проджектайла
        
        -- орбитальные параметры
        duration = 8.0,                -- Длительность существования
        orbitRadius = 200,              -- Радиус орбиты вокруг кастера
        orbitSpeed = 2,               -- Скорость вращения вокруг кастера (рад/сек)
        projectileCount = 3,            -- Количество топоров
        
        -- вращение проджектайлов
        selfRotationSpeed = 3.0,        -- Скорость вращения топора вокруг своей оси
        
        -- поведение
        followCaster = true,            -- Следовать за кастером
        destroyOnCasterDeath = true,    -- Уничтожать при смерти кастера
        destroyOnHit = false,           -- Уничтожать топор при попадании (false = постоянные)
        
        -- дебаффы (опционально)
        debuffType = nil,               -- Тип дебаффа
        debuffDuration = 0,             -- Длительность дебаффа
        debuffDamage = 0,               -- Урон дебаффа
        debuffTickRate = 0,             -- Частота тиков дебаффа
    },
    quads = {
        idle = {
            row = 1,
            col = 1
        },
        fly = {
            startrow = 1,
            startcol = 2,
            endrow = 1,
            endcol = 2,
        }
    },
}
return Skills