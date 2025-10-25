local SpriteManager = {}
SpriteManager.__index = SpriteManager

-- Глобальные кеши спрайтов
local spriteCaches = {
    heroes = {},
    enemies = {},
    drops = {},
    skills = {},
    items = {}
}

function SpriteManager.loadHeroSprite(heroId)
    if not spriteCaches.heroes[heroId] then
        spriteCaches.heroes[heroId] = love.graphics.newImage("assets/heroes/" .. heroId .. "/spritesheet.png")
    end
    return spriteCaches.heroes[heroId]
end

function SpriteManager.loadEnemySprite(enemyId)
    if not spriteCaches.enemies[enemyId] then
        spriteCaches.enemies[enemyId] = love.graphics.newImage("assets/enemies/" .. enemyId .. "/spritesheet.png")
    end
    return spriteCaches.enemies[enemyId]
end

function SpriteManager.loadDropSprite(dropId)
    if not spriteCaches.drops[dropId] then
        spriteCaches.drops[dropId] = love.graphics.newImage("assets/drops/" .. dropId .. ".png")
    end
    return spriteCaches.drops[dropId]
end

function SpriteManager.loadSkillSprite(skillId)
    if not spriteCaches.skills[skillId] then
        spriteCaches.skills[skillId] = love.graphics.newImage("assets/skills/" .. skillId .. "/icon.png")
    end
    return spriteCaches.skills[skillId]
end

function SpriteManager.loadItemSprite(itemId)
    if not spriteCaches.items[itemId] then
        spriteCaches.items[itemId] = love.graphics.newImage("assets/items/" .. itemId .. ".png")
    end
    return spriteCaches.items[itemId]
end

-- Очистка кеша (если нужно)
function SpriteManager.clearCache(cacheType)
    if cacheType then
        spriteCaches[cacheType] = {}
    else
        -- Очищаем все кеши
        for k, v in pairs(spriteCaches) do
            spriteCaches[k] = {}
        end
    end
end

-- Получение информации о кеше
function SpriteManager.getCacheInfo()
    local info = {}
    for cacheType, cache in pairs(spriteCaches) do
        local count = 0
        for _ in pairs(cache) do count = count + 1 end
        info[cacheType] = count
    end
    return info
end

return SpriteManager