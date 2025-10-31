local World = require("src.world.world")
local Input = require("src.system.input")
local Camera = require("src.system.camera")
local Minimap = require("src.system.minimap")
local Map = require("src.world.map")
local Constants = require("src.constants")
local UIPauseMenu = require("src.ui.ui_pause_menu")
local UISkillUpgrade = require("src.ui.ui_skill_upgrade")
local SkillsConfig = require("src.config.skills")
local Skill = require("src.entity.skill")
local SpriteManager = require("src.utils.sprite_manager")
local HUD = require("src.ui.hud")

-- Подключаем отладку только если включена
local DebugDisplay = nil
if Constants.DEBUG_DRAW_FPS then
    DebugDisplay = require("src.system.debug_display")
end

local Game = {}
Game.__index = Game

-- Генерирует список доступных опций для выбора скиллов
local function generateUpgradeOptions(hero)
    local options = {}
    
    -- Получаем список скиллов героя
    local heroSkillIds = {}
    for _, skill in ipairs(hero.skills) do
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
            local nextLevel = skill.level + 1
            local upgradeIndex = nextLevel - 1
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
            return {}
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
    else
        -- Есть свободные слоты - смешиваем опции
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
    
    if #options == 0 then
        return {}
    end
    
    -- Случайно выбираем 3 опции
    if #options > 3 then
        for i = #options, 2, -1 do
            local j = math.random(i)
            options[i], options[j] = options[j], options[i]
        end
        local selected = {}
        for i = 1, 3 do
            table.insert(selected, options[i])
        end
        return selected
    end
    
    return options
end

function Game:enter(selectedHeroId, selectedSkillId)
  self.input = Input.new()
  self.input:snapshotNow()
  
  self.map = Map.new()
  self.world = World.new(self.map.width, self.map.height)
  self.camera = Camera.new()
  self.minimap = Minimap.new(self.map.width, self.map.height)

  self.isPaused = false
  self.uiPauseMenu = UIPauseMenu.new()
  self.hud = HUD.new()
  self.isSkillUpgradeScreen = false
  self.uiSkillUpgrade = nil
  
  -- Инициализируем отладку только если включена
  if DebugDisplay then
    self.debugDisplay = DebugDisplay.new()
  end

  -- fixed timestep аккумулятор
  self._accum = 0
  -- игровое время
  self.gameTime = 0
  -- инициализация мира
  self.world:setup(selectedHeroId, selectedSkillId, self.map.width, self.map.height)
  
  -- Сохраняем выбранные параметры для рестарта
  self.selectedHeroId = selectedHeroId
  self.selectedSkillId = selectedSkillId
  
  -- Статистика игры
  self.gameStats = {
    level = 1,
    time = 0,
    enemiesKilled = 0,
    damageDealt = 0
  }
end

function Game:exit()
  -- Полная очистка мира и ссылок при выходе из состояния
  if self.world and self.world.dispose then
    self.world:dispose()
  end
  self.world = nil
  self.map = nil
  self.camera = nil
  self.minimap = nil
  self.uiPauseMenu = nil
  self.uiSkillUpgrade = nil
  self.hud = nil
  self.debugDisplay = nil
end

function Game:update(dt)
  -- обновляем ввод на реальном dt (чтобы клики/нажатия были отзывчивы)
  self.input:update(dt)
  
  -- обновляем отладочную информацию (только если не на паузе)
  if self.debugDisplay and not self.isPaused then
    local hero = self.world.heroes and self.world.heroes[1]
    self.debugDisplay:update(dt, self.world, hero, self.camera)
  end

  -- пауза
  if self.input.isEscapePressed and self.input:isEscapePressed() then
    self.isPaused = not self.isPaused
    return
  end

  if self.isPaused then
    -- обновляем UI паузы и обрабатываем клики
    local clicked = self.uiPauseMenu:update(dt, self.input)
    if clicked == "resume" then
      self.isPaused = false
    elseif clicked == "restart" then
      -- полный рестарт текущей игры с тем же героем/скиллом
      return {
        state = "game",
        selectedHeroId = self.selectedHeroId,
        selectedSkillId = self.selectedSkillId
      }
    elseif clicked == "main_menu" then
      -- выход в главное меню
      return {
        state = "main_menu",
        gameStats = nil,
        selectedHeroId = nil,
        selectedSkillId = nil
      }
    end
    return -- не обновляем игру, но input работает
  end
  
  -- Экран выбора скиллов при повышении уровня
  if self.isSkillUpgradeScreen then
    if self.uiSkillUpgrade then
      local selected = self.uiSkillUpgrade:update(dt, self.input)
      if selected then
        -- Применяем выбранный вариант
        local hero = self.world.heroes and self.world.heroes[1]
        if hero then
          if selected.type == "new_skill" then
            local newSkill = Skill.new(selected.id, 1, hero)
            table.insert(hero.skills, newSkill)
          elseif selected.type == "upgrade" then
            selected.skill:levelUp()
          end
        end
        -- Закрываем экран выбора
        self.isSkillUpgradeScreen = false
        self.uiSkillUpgrade = nil
      end
    else
      -- Если UI не создан (нет опций), просто закрываем экран
      self.isSkillUpgradeScreen = false
    end
    return -- не обновляем игру, но input работает
  end
  
  -- обновляем игровое время (только если не на паузе)
  self.gameTime = self.gameTime + dt

  -- защитим от гигантских dt (сворачивание окна и т.п.)
  if dt > 0.25 then dt = 0.25 end

  -- === FIXED TIMESTEP ===
  self._accum = self._accum + dt
  local step = Constants.FIXED_DT
  local maxN = Constants.MAX_FRAME_SKIP

  local steps = 0
  while self._accum >= step and steps < maxN do
    -- шаг симуляции мира строго фиксированным квантовом времени
    self.world:update(step)
    self._accum = self._accum - step
    steps = steps + 1
  end

  -- если не успели “догнать” за кадр — сбросим остаток, чтобы не войти в спираль смерти
  if steps == maxN then
    self._accum = 0
  end

  -- Обработка движения героя при зажатой ПКМ
  local hero = self.world.heroes and self.world.heroes[1]
  if hero then
    -- Проверяем, нужно ли показать экран выбора скиллов
    if hero.needsSkillChoice then
      hero.needsSkillChoice = false  -- сбрасываем флаг
      local options = generateUpgradeOptions(hero)
      if #options > 0 then
        self.isSkillUpgradeScreen = true
        self.uiSkillUpgrade = UISkillUpgrade.new(hero, options)
      end
      -- Если нет опций, просто продолжаем игру
      return -- не обновляем игру в этом кадре, показываем экран выбора
    end
    
    -- Проверяем, не умер ли герой
    if hero.isDead then
      -- Обновляем статистику перед переходом к Game Over
      self.gameStats.level = hero.level or 1
      self.gameStats.time = self.gameTime
      self.gameStats.enemiesKilled = self.world.enemiesKilled or 0
      self.gameStats.damageDealt = hero.damageDealt or 0
      
      -- Возвращаем переход к Game Over
      return {
        state = "game_over",
        gameStats = self.gameStats,
        selectedHeroId = self.selectedHeroId,
        selectedSkillId = self.selectedSkillId
      }
    end
    
    -- Движение только при зажатой ПКМ
    if self.input:isRightMouseDown() then
      local mx, my = self.input:getMousePosition()
      -- Конвертируем экранные координаты в мировые
      local worldX, worldY = self.camera:screenToWorld(mx, my)
      
      -- Вычисляем направление движения
      local dx = worldX - hero.x
      local dy = worldY - hero.y
      local distance = math.sqrt(dx * dx + dy * dy)
      
      -- Нормализуем и применяем скорость
      if distance > 5 then -- минимальное расстояние для движения
        dx = (dx / distance) * hero.moveSpeed * dt
        dy = (dy / distance) * hero.moveSpeed * dt
        hero:changePosition(dx, dy)
      end
    end

    -- === ЛКМ: прицельный режим для направленных скиллов ===
    if self.input:isLeftMouseDown() then
      local wx, wy = self.input:getMouseWorldPosition(self.camera)
      hero:setAimPoint(wx, wy)
    elseif self.input:isLeftMouseReleased() then
      hero:clearAim()
    end
    
    -- камера следует за героем после логических шагов
    self.camera:update(hero.x, hero.y)
  end
end

function Game:draw()
  if self.isPaused then
    self.uiPauseMenu:draw()
    return
  elseif self.isSkillUpgradeScreen then
    if self.uiSkillUpgrade then
      self.uiSkillUpgrade:draw()
    end
    return
  else
    -- всё, что “в мире”, рисуем под камерой
    self.camera:apply()
    self.map:draw()
    self.world:draw()
    self.camera:clear()

    -- оверлеи/экранные UI вне камеры (чтобы не скроллились)
    local hero = self.world.heroes and self.world.heroes[1]
    if hero then
      self.minimap:draw(hero, self.world.enemies, self.world.projectiles, self.camera)
      -- HUD (нижняя часть экрана)
      self.hud:draw(hero, self.gameTime)
    end
    
    -- отладочная информация (левый верхний угол)
    if self.debugDisplay then
      self.debugDisplay:draw()
    end
  end
end

function Game:resize(w, h)
  if self.uiPauseMenu and self.uiPauseMenu.resize then
    self.uiPauseMenu:resize(w, h)
  end
end

return Game
