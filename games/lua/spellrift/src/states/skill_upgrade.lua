local UISkillUpgrade = require("src.ui.ui_skill_upgrade")
local SkillsConfig = require("src.config.skills")
local Skill = require("src.entity.skill")
local SpriteManager = require("src.utils.sprite_manager")
local Input = require("src.system.input")

local SkillUpgrade = {}
SkillUpgrade.__index = SkillUpgrade

-- Генерирует список доступных опций для выбора
local function generateUpgradeOptions(hero)
    local options = {}
    
    -- Получаем список скиллов героя
    local heroSkills = {}
    local heroSkillIds = {}
    for _, skill in ipairs(hero.skills) do
        heroSkills[skill.id] = skill
        heroSkillIds[skill.id] = true
    end
    
    -- Собираем доступные новые скиллы
    local availableNewSkills = {}
    for id, cfg in pairs(SkillsConfig) do
        if cfg.can_be_selected and not heroSkillIds[id] then
            local sprite = SpriteManager.loadSkillSprite(id)
            table.insert(availableNewSkills, {
                id = id,
                config = cfg,
                sprite = sprite
            })
        end
    end
    
    -- Собираем доступные улучшения
    local availableUpgrades = {}
    for _, skill in ipairs(hero.skills) do
        if skill:canLevelUp() then
            -- upgrades индексируются с 1, где upgrades[1] это улучшение для level 2
            local nextLevel = skill.level + 1
            local upgradeIndex = nextLevel - 1  -- для level 2 берём upgrades[1]
            if skill.upgrades and skill.upgrades[upgradeIndex] then
                local upgrade = skill.upgrades[upgradeIndex]
                local cfg = SkillsConfig[skill.id]
                local sprite = SpriteManager.loadSkillSprite(skill.id)
                table.insert(availableUpgrades, {
                    skill = skill,
                    config = cfg,
                    upgrade = upgrade,
                    sprite = sprite
                })
            end
        end
    end
    
    -- Определяем, что можно предлагать
    local hasFreeSlots = #hero.skills < hero.maxSkillSlots
    local hasUpgrades = #availableUpgrades > 0
    
    -- Если все слоты заняты, предлагаем только улучшения
    if not hasFreeSlots then
        if not hasUpgrades then
            -- Ничего нельзя предложить
            return {}
        end
        -- Только улучшения
        for _, upgrade in ipairs(availableUpgrades) do
            table.insert(options, {
                type = "upgrade",
                skill = upgrade.skill,
                config = upgrade.config,
                upgrade = upgrade.upgrade,
                sprite = upgrade.sprite
            })
        end
    else
        -- Есть свободные слоты - можно предлагать и новые скиллы, и улучшения
        -- Смешиваем опции
        for _, newSkill in ipairs(availableNewSkills) do
            table.insert(options, {
                type = "new_skill",
                id = newSkill.id,
                config = newSkill.config,
                sprite = newSkill.sprite
            })
        end
        
        for _, upgrade in ipairs(availableUpgrades) do
            table.insert(options, {
                type = "upgrade",
                skill = upgrade.skill,
                config = upgrade.config,
                upgrade = upgrade.upgrade,
                sprite = upgrade.sprite
            })
        end
    end
    
    -- Если нечего предложить
    if #options == 0 then
        return {}
    end
    
    -- Случайно выбираем 3 опции
    if #options > 3 then
        -- Перемешиваем и берем первые 3
        for i = #options, 2, -1 do
            local j = math.random(i)
            options[i], options[j] = options[j], options[i]
        end
        -- Берем только первые 3
        local selected = {}
        for i = 1, math.min(3, #options) do
            table.insert(selected, options[i])
        end
        return selected
    end
    
    return options
end

function SkillUpgrade:enter(hero, savedHeroId, savedSkillId)
    self.hero = hero
    self.savedHeroId = savedHeroId
    self.savedSkillId = savedSkillId
    self.input = Input.new()
    self.input:snapshotNow()
    
    -- Генерируем опции для выбора
    local options = generateUpgradeOptions(hero)
    
    if #options == 0 then
        -- Нет доступных опций - сразу возвращаемся в игру
        self.noOptions = true
        return
    end
    
    self.ui = UISkillUpgrade.new(hero, options)
end

function SkillUpgrade:exit()
    self.hero = nil
    self.ui = nil
    self.input = nil
end

function SkillUpgrade:update(dt)
    if not self.input then
        return nil
    end
    
    self.input:update(dt)
    
    -- Если нет опций, сразу возвращаемся
    if self.noOptions then
        return {
            state = "game",
            selectedHeroId = self.savedHeroId,
            selectedSkillId = self.savedSkillId,
            resume = true
        }
    end
    
    if not self.ui then
        return {
            state = "game",
            selectedHeroId = self.savedHeroId,
            selectedSkillId = self.savedSkillId,
            resume = true
        }
    end
    
    -- Обновляем UI и обрабатываем выбор
    local selected = self.ui:update(dt, self.input)
    
    if selected then
        -- Применяем выбранный вариант
        if selected.type == "new_skill" then
            -- Добавляем новый скилл
            local newSkill = Skill.new(selected.id, 1, self.hero)
            table.insert(self.hero.skills, newSkill)
        elseif selected.type == "upgrade" then
            -- Улучшаем существующий скилл
            selected.skill:levelUp()
        end
        
        -- Возвращаемся в игру - используем сохраненные параметры
        return {
            state = "game",
            selectedHeroId = self.savedHeroId,
            selectedSkillId = self.savedSkillId,
            resume = true
        }
    end
    
    return nil
end

function SkillUpgrade:draw()
    if self.noOptions or not self.ui then
        return
    end
    
    self.ui:draw()
end

function SkillUpgrade:resize(w, h)
    -- UI сам обрабатывает размер экрана
end

return SkillUpgrade

