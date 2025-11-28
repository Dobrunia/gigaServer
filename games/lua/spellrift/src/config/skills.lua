-- базовый скилл

-- утрон в сек базовый 30
-- прирост в секунду 5
-- ЦЕЛЬ: любой скилл на уровне 1 должен давать примерно 30 DPS  
-- Каждый следующий уровень: +5 DPS (или +17% к текущему)

-- Универсальная формула DPS для любого типа скилла:

-- DPS = (Полный урон за один каст) ÷ (Реальное время между кастами)

-- Где:
-- Полный урон за один каст = 
--     Базовый урон 
--     + (DoT урон за тик × количество тиков за длительность)
--     × (множитель количества попаданий по типу скилла)
--     × 0.85 (шанс попадания)

-- Реальное время между кастами = 
--     Кулдаун + замах (windup) + задержка взрыва (armTime)

-- Множители количества попаданий (ожидаемое число хитов):
-- - Обычный projectile / melee без угла → ×1
-- - Melee cone (сектор) → от ×1.5 до ×4 (чем шире угол — тем больше)
-- - Volley (8 направлений) → ×6–7 (из 8 попадает ~80%)
-- - Orbital (топоры) → урон считается за всю длительность (damage / hitCooldown × duration)
-- - Aura → урон считается за всю длительность (damage / tickRate × duration)
-- - Ground AoE (гейзер) → × количество зон × 0.9
-- - Summon → берём его собственный DPS × длительность жизни

-- Пример расчёта (Fireball LVL1):
-- Полный урон = 40 + (8 × 5 тиков) = 80
-- Кулдаун = 3 сек
-- DPS = 80 ÷ 3 = 26.7 → нужно поднять урон на ~12% → будет ровно 30

-- ИТОГО: если после подсчёта по этой формуле у тебя выходит 28–35 DPS на 1 уровне — скилл идеально сбалансирован.
-- Если меньше 25 — слабый, если больше 45 — слишком сильный.

-- TODO:: отдельная математика для вражеских скиллов и скиллов с эффектами

local Skills = {}

Skills["fireball"] = {
    id = "fireball",
    name = "Fireball",
    description = "Shoots a fireball that deals damage to enemies",
    type = "projectile",
    isStartingSkill = true,
    can_be_selected = true,

    -- Базовые характеристики (DPS ~30: (53 + 8*5) * 0.85 / 3 = 26.4, ближе к 30)
    stats = {
        damage = 53,           -- Урон при попадании
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
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: (63 + 10*5) * 0.85 / 3 = 32.0)
        {
            damage = 63,
            debuffDamage = 10
        },
        -- Level 3: дольше DoT (DPS ~40: (63 + 12*6) * 0.85 / 3 = 38.3)
        {
            debuffDuration = 6.0,
            debuffDamage = 12
        },
        -- Level 4: быстрее кулдаун (DPS ~45: (63 + 12*6) * 0.85 / 2.5 = 46.0)
        {
            cooldown = 2.5
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
        speed = 200,
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

    -- Базовые характеристики (DPS ~30: 71 * 0.85 / 2 = 30.2)
    stats = {
        damage = 71,
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
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: 82 * 0.85 / 2 = 34.9)
        {
            damage = 82
        },
        -- Level 3: быстрее кулдаун (DPS ~40: 82 * 0.85 / 1.75 = 39.8)
        {
            cooldown = 1.75
        },
        -- Level 4: еще больше урона (DPS ~45: 95 * 0.85 / 1.75 = 46.1)
        {
            damage = 95
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

    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: 77 * 1.5 * 0.85 / 2.8 = 35.1)
        {
            damage = 77
        },
        -- Level 3: шире угол (DPS ~40: 77 * 1.8 * 0.85 / 2.8 = 42.0)
        {
            arcAngleDeg = 50
        },
        -- Level 4: быстрее кулдаун (DPS ~45: 77 * 1.8 * 0.85 / 2.4 = 49.0)
        {
            cooldown = 1.6
        }
    }
}

Skills["bear-cleave"] = {
    id = "bear-cleave",
    name = "Bear Cleave",
    description = "Cleaves the ground in front of the bear, dealing damage to enemies in a cone",
    type = "melee",

    -- Базовые характеристики (DPS ~30: 64 * 2.5 * 0.85 / 4.5 = 30.2)
    stats = {
        -- боевые
        damage = 64,
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

    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: 75 * 2.5 * 0.85 / 4.5 = 35.4)
        {
            damage = 75
        },
        -- Level 3: быстрее кулдаун (DPS ~40: 75 * 2.5 * 0.85 / 4.0 = 39.8)
        {
            cooldown = 3.5
        },
        -- Level 4: еще больше урона (DPS ~45: 87 * 2.5 * 0.85 / 4.0 = 46.2)
        {
            damage = 87
        }
    }
}

-- === VOLLEY SKILLS ===
Skills["crimson-volley"] = {
    id = "crimson-volley",
    name = "Crimson Volley",
    description = "Shoots a volley of crimson arrows in 8 directions",
    type = "volley",
    isStartingSkill = true,
    can_be_selected = true,

    -- Базовые характеристики (DPS ~30: 16 * 6.5 * 0.85 / 3 = 29.5)
    stats = {
        damage = 16,           -- Урон при попадании
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
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: 19 * 6.5 * 0.85 / 3 = 35.0)
        {
            damage = 19
        },
        -- Level 3: быстрее кулдаун (DPS ~40: 19 * 6.5 * 0.85 / 2.6 = 40.0)
        {
            cooldown = 2.6
        },
        -- Level 4: еще больше урона (DPS ~45: 22 * 6.5 * 0.85 / 2.6 = 45.6)
        {
            damage = 22
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
    can_be_selected = true,

    -- Базовые характеристики (DPS ~30: (5.3 / 0.4) * 3 * (8 / 12) = 26.5, округлим до 6)
    -- Средний DPS = (damage / hitCooldown) * projectileCount * (duration / cooldown)
    stats = {
        -- боевые
        damage = 6,                    -- Урон за попадание
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
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: (7 / 0.4) * 3 * (8 / 12) = 35.0)
        {
            damage = 7
        },
        -- Level 3: дольше длительность (DPS ~40: (7 / 0.4) * 3 * (9 / 12) = 39.4)
        {
            duration = 9.0
        },
        -- Level 4: еще больше урона (DPS ~45: (8 / 0.4) * 3 * (9 / 12) = 45.0)
        {
            damage = 8
        }
    }
}

-- == AURA SKILLS ===
Skills["satan-aura"] = {
    id = "satan-aura",
    name = "Satan Aura",
    description = "Creates a satan aura around the player that deals damage over time",
    type = "aura",
    isStartingSkill = true,
    can_be_selected = true,

    -- Базовые характеристики (DPS ~30: (16 / 0.3) * (8 / 14) = 30.5)
    -- Средний DPS = (damage / tickRate) * (duration / cooldown)
    stats = {
        damage = 16,
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

    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: (19 / 0.3) * (8 / 14) = 36.2)
        {
            damage = 19
        },
        -- Level 3: дольше длительность (DPS ~40: (19 / 0.3) * (9 / 14) = 40.7)
        {
            duration = 9.0
        },
        -- Level 4: еще больше урона (DPS ~45: (22 / 0.3) * (9 / 14) = 47.1)
        {
            damage = 22
        }
    },
}

-- === SUMMON SKILLS ===
Skills["bear"] = {
    id = "bear",
    name = "Bear",
    description = "Summons a bear that attacks enemies",
    type = "summon",
    isStartingSkill = true,
    can_be_selected = true,

    -- Базовые характеристики
    -- DPS медведя через bear-cleave: 64 * 2.5 * 0.85 / 4.5 = 30.2
    -- Средний DPS = 30.2 * (30 / 30) = 30.2 (медведь живет столько же, сколько кулдаун)
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
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    -- Улучшаем характеристики медведя, что косвенно повышает его DPS через bear-cleave
    upgrades = {
        -- Level 2: больше здоровья и урона медведя (через bear-cleave)
        {
            health = 130
        },
        -- Level 3: дольше живет (DPS ~40: 30.2 * (35 / 30) = 35.2, но медведь сильнее)
        {
            duration = 35.0
        },
        -- Level 4: еще больше здоровья и быстрее кулдаун
        {
            health = 160,
            cooldown = 26.0
        }
    }
}

-- === PERMANENT BUFF SKILLS ===
-- Постоянные баффы можно набирать бесконечно, без ограничений на количество
Skills["speed-buff"] = {
    id = "speed-buff",
    name = "Swiftness",
    description = "Increases movement speed permanently (+15)",
    type = "permanent_buff",
    can_be_selected = true,

    stats = {
        moveSpeedBonus = 15,  -- бонус к скорости движения
    },

    quads = {
        idle = {
            row = 1,
            col = 1
        }
    },
}

-- Skills["hp-buff"] = {
--     id = "hp-buff",
--     name = "Vitality",
--     description = "Increases maximum health permanently (+30)",
--     type = "permanent_buff",
--     can_be_selected = true,

--     stats = {
--         hpBonus = 30,  -- бонус к максимальному HP
--     },

--     quads = {
--         idle = {
--             row = 1,
--             col = 1
--         }
--     },
-- }

-- Skills["armor-buff"] = {
--     id = "armor-buff",
--     name = "Fortitude",
--     description = "Increases armor permanently (+3)",
--     type = "permanent_buff",
--     can_be_selected = true,

--     stats = {
--         armorBonus = 3,  -- бонус к армору
--     },

--     quads = {
--         idle = {
--             row = 1,
--             col = 1
--         }
--     },
-- }

-- Skills["pickup-buff"] = {
--     id = "pickup-buff",
--     name = "Magnetism",
--     description = "Increases pickup range for drops (+50)",
--     type = "permanent_buff",
--     can_be_selected = true,

--     stats = {
--         pickupRangeBonus = 50,  -- бонус к радиусу подбора
--     },

--     quads = {
--         idle = {
--             row = 1,
--             col = 1
--         }
--     },
-- }

-- === TEMPORARY BUFF SKILLS ===
-- Временные баффы имеют длительность и таймер
-- Skills["speed-burst"] = {
--     id = "speed-burst",
--     name = "Speed Burst",
--     description = "Temporarily increases movement speed (+30 for 10s)",
--     type = "temporary_buff",
--     can_be_selected = true,

--     stats = {
--         moveSpeedBonus = 30,  -- бонус к скорости движения
--         duration = 10.0,      -- длительность в секундах
--     },

--     quads = {
--         idle = {
--             row = 1,
--             col = 1
--         }
--     },
-- }

-- Skills["health-boost"] = {
--     id = "health-boost",
--     name = "Health Boost",
--     description = "Temporarily increases maximum health (+50 for 15s)",
--     type = "temporary_buff",
--     can_be_selected = true,

--     stats = {
--         hpBonus = 50,        -- бонус к максимальному HP
--         duration = 15.0,      -- длительность в секундах
--     },

--     quads = {
--         idle = {
--             row = 1,
--             col = 1
--         }
--     },
-- }

-- === GROUND AOE SKILLS ===
Skills["geyser"] = {
    id = "geyser",
    name = "Geyser",
    description = "Spawns red warning circles that explode after a delay",
    type = "ground_aoe",
    isStartingSkill = true,
    can_be_selected = true,
    
    -- Базовые характеристики (DPS ~30: 102 * 3 * 0.9 / 9.2 = 29.9)
    -- Реальное время = cooldown + armTime = 8.0 + 1.2 = 9.2
    stats = {
        -- Боевые
        damage = 102,              -- разовый урон при взрыве
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
    },
    -- Апгрейды по уровням (DPS: 30 → 35 → 40 → 45)
    upgrades = {
        -- Level 2: больше урона (DPS ~35: 119 * 3 * 0.9 / 9.2 = 34.9)
        {
            damage = 119
        },
        -- Level 3: больше зон (DPS ~40: 119 * 3.5 * 0.9 / 9.2 = 40.8)
        {
            spawnCount = 4
        },
        -- Level 4: быстрее кулдаун (DPS ~45: 119 * 3.5 * 0.9 / 8.0 = 46.9)
        {
            cooldown = 7.0
        }
    }
}
return Skills