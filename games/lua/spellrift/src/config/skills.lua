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

Skills["satyr-boomerang"] = {
    id = "satyr-boomerang",
    name = "Satyr boomerang",
    description = "Shoots a satyr boomerang and roots",
    type = "projectile",
    
    stats = {
        damage = 5,
        cooldown = 5.0,
        range = 700,
        speed = 220,
        radius = 20,
        faceDirection = true,

        debuffType = "root",  -- реализовать поддержку ( спрайт проигрывать за время длительности с 1 по 7 и назад до 1)
        debuffDuration = 2.5,
    },


    quads = {
        idle = {
            row = 1,
            col = 6
        },
        fly = {
            startrow = 1,
            startcol = 1,
            endrow = 1,
            endcol = 11,
            loop = false,  -- анимация проигрывается один раз (не зацикливается)
        }
    },

    upgrades = {
        {
            debuffDuration = 3.0,  -- реализовать поддержку если еще не
        },
        {
            debuffDuration = 3.5,
        },
        {
            debuffDuration = 4.0,
        }
    }
}

-- === MELEE PROJECTILE SKILLS ===
Skills["slash6"] = {
    id = "slash6",
    name = "Slash6",
    description = "Slashes the ground in front",
    type = "projectile",

    stats = {
        damage = 30,
        cooldown = 2.0,
        range = 100,
        speed = 100,
        radius = 14,
        faceDirection = true,  -- спрайт зеркалируется по горизонтали в зависимости от направления движения
    },

    quads = {
        idle = {
            row = 1,
            col = 5
        },
        fly = {
            startrow = 1,
            startcol = 1,
            endrow = 1,
            endcol = 10,
            loop = false,  -- анимация проигрывается один раз (не зацикливается)
        }
    },
}

-- === MELEE SKILLS ===
Skills["zombie-cleave"] = {
    id = "zombie-cleave",
    name = "Zombie Cleave",
    description = "Cleaves the ground in front of the zombie, dealing damage to enemies in a cone",
    type = "melee",

    stats = {
        -- === БОЕВЫЕ ПАРАМЕТРЫ ===
        damage = 35,           -- урон при попадании
        cooldown = 2.0,        -- время перезарядки скилла (секунды)
        range = 80,            -- триггер-дистанция для AI (если не передан tx,ty)
        hitMaxTargets = 0,     -- максимальное количество целей (0 = без лимита)
        knockback = 0,         -- сила отталкивания при попадании

        -- === ГЕОМЕТРИЯ СЕКТОРА ===
        arcAngleDeg = 30,      -- угол сектора в градусах (360 = полный круг)
        arcInnerRadius = 0,    -- внутренний радиус сектора (0 = от центра)
        arcOffsetDeg = 0,      -- поворот сектора относительно направления атаки

        -- === ТАЙМИНГИ ===
        windup = 0.8,          -- время замаха (секунды) - анимация подготовки
        active = 0.05,         -- окно урона (секунды) - когда наносится урон

        -- === ПОВЕДЕНИЕ НАВЕДЕНИЯ ===
        followAim = true,            -- следовать за целью/курсором (true) или использовать facing (false)
        directionMode = "free",      -- режим направления: "free" | "horizontal" | "vertical"
        trackDuringWindup = true,    -- сектор "прилипает" к цели во время замаха
        lockMovement = false,        -- блокировать движение кастера во время замаха
        centerOffset = 10,           -- смещение центра атаки вперед по направлению

        -- === ВИЗУАЛ ТЕЛЕГРАФА ===
        telegraphColor = {1,1,1},    -- цвет предварительного показа сектора (RGB)
        telegraphAlpha = 0.15,       -- прозрачность предварительного показа
    },

    upgrades = {
        { damage = 80, cooldown = 0.85, arcAngleDeg = 140 },
        { damage = 100, cooldown = 0.7, arcAngleDeg = 160 },
    }
}

Skills["bear-cleave"] = {
    id = "bear-cleave",
    name = "Bear Cleave",
    description = "Cleaves the ground in front of the bear, dealing damage to enemies in a cone",
    type = "melee",

    stats = {
        -- боевые
        damage = 40,
        cooldown = 4.0,
        range = 80,            -- триггер-дистанция для AI (если не передан tx,ty)
        hitMaxTargets = 0,     -- 0 = без лимита
        knockback = 0,

        -- геометрия сектора
        arcAngleDeg = 120,     -- 360 = круг
        arcInnerRadius = 0,
        arcOffsetDeg = 0,

        -- тайминги
        windup = 0.5,         -- замах
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
        { damage = 60, cooldown = 1.5},
        { damage = 80, cooldown = 1,},
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
        hitCooldown = 0.4, -- интервал между уронами по одной цели

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

-- == AURA SKILLS ===
Skills["satan-aura"] = {
    id = "satan-aura",
    name = "Satan Aura",
    description = "Creates a satan aura around the player that deals damage over time",
    type = "aura",
    isStartingSkill = true,

    stats = {
        damage = 5,
        cooldown = 14.0,
        radius = 200,
        tickRate = 0.3, -- Частота тиков урона по цели за секунду
        duration = 8.0, 

        debuffType = nil,
        debuffDuration = 0,
        debuffDamage = 0,
        debuffTickRate = 0,
    },

    quads = {
        idle = {
            row = 1,
            col = 1
        },
        fly = {
            startrow = 1,
            startcol = 3,
            endrow = 1,
            endcol = 3,
        }
    },

    upgrades = {
        {
            duration = 10.0, 
        },
        {
            damage = 10,
            radius = 250,
        },
        {
            tickRate = 0.2,
        },
    },
}

-- === SUMMON SKILLS ===
Skills["bear"] = {
    id = "bear",
    name = "Bear",
    description = "Summons a bear that attacks enemies",
    type = "summon",
    isStartingSkill = true,

    stats = {
        health = 100,
        armor = 5,
        moveSpeed = 80,
        cooldown = 30.0,
        duration = 30.0,  -- длительность существования
        followDistance = 500,  -- дистанция следования за героем
    },

    width = 64,
    height = 64,
    skills = {'bear-cleave'},

    quads = {
        idle = {
            row = 1,
            col = 1
        },
        walk = {
            startrow = 1,
            startcol = 2,
            endrow = 1,
            endcol = 4
        },
        cast = {
            startrow = 1,
            startcol = 5,
            endrow = 1,
            endcol = 6
        }
    },
}

-- === GROUND AOE SKILLS ===
Skills["geyser"] = {
    id = "geyser",
    name = "Geyser",
    description = "Spawns red warning circles that explode after a delay",
    type = "ground_aoe",
    isStartingSkill = true,

    stats = {
        -- Боевые
        damage = 40,              -- разовый урон при взрыве
        cooldown = 8.0,           -- КД умения

        -- Геометрия зоны
        radius = 80,              -- радиус круга (визуал + хитбокс)
        
        -- Телеграф/задержка
        armTime = 1.2,            -- время «зарядки» (мигает красным), после чего взрыв
        zoneLifetime = 0.7,       -- сколько зона живёт после взрыва (для эффектов/затухания)
        warningBlinkSpeed = 3.0,  -- скорость мигания (Гц)
        color = {0.65, 0.85, 1.0}, -- базовый цвет телеграфа (нежно-голубой, RGB)
        warningAlphaMin = 0.15,   -- минимальная альфа в мигании
        warningAlphaMax = 0.65,   -- максимальная альфа в мигании

        -- Спавн зон
        spawnMode = "on_target",  -- "on_target" (под ногами цели) | "around_caster" (в радиусе от кастера в случайном месте)
        spawnCount = 3,           -- сколько максимум зон создать за активацию применять к РАЗНЫМ ЦЕЛЯМ (если цель 1 то зона 1)
        spawnInterval = 0.2,      -- задержка между спавнами зон (серия)
        spawnRadiusMin = 100,     -- мин. дистанция спавна от кастера (для around_caster) отображать при Constants.DEBUG_DRAW_HITBOXES = true
        spawnRadiusMax = 700,     -- макс. дистанция спавна от кастера (для around_caster) отображать при Constants.DEBUG_DRAW_HITBOXES = true

        -- Наведение/цель
        followTargetDuringArm = false,-- если true, зона «прилипает» к цели во время armTime (обычно false)ъ
        followTargetSpeed = 100,      -- скорость следования за целью (если followTargetDuringArm = true)

        -- Опциональные эффекты
        debuffType = nil,         -- тип дебаффа после взрыва (если нужен)
        debuffDuration = 0.0,
        debuffDamage = 0,
        debuffTickRate = 0.0,
    },

    -- Опционально: кадры для визуала зоны (если используешь атлас для анимированной заливки)
    quads = {
        idle = { row = 1, col = 1 },
        fly = { startrow = 1, startcol = 2, endrow = 1, endcol = 11 },
    }
}
return Skills