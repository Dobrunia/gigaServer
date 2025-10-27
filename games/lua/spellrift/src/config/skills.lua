local Skills = {}

-- Пример скилла "Огненный шар"
Skills["fireball"] = {
    id = "fireball",
    name = "Огненный шар",
    description = "Запускает огненный шар, который наносит урон врагам",
    type = "projectile",
    isStartingSkill = true,
    
    -- Базовые характеристики
    stats = {
        damage = 40,           -- Урон при попадании
        cooldown = 3.0,        -- Кулдаун скилла
        range = 250,           -- Дальность полета
        speed = 180,           -- Скорость снаряда
        radius = 15,           -- Радиус попадания
        
        -- Параметры дебаффа
        debuffType = "burn", -- Тип дебаффа
        debuffDuration = 5.0, -- Длительность отравления
        debuffDamage = 8,     -- Урон за тик
        debuffTickRate = 1.0  -- Частота тиков
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

return Skills