local World = require("src.world.world")
local Input = require("src.system.input")
local Camera = require("src.system.camera")
local Minimap = require("src.system.minimap")
local Map = require("src.world.map")
local Constants = require("src.constants")
local UIPauseMenu = require("src.ui.ui_pause_menu")
local HUD = require("src.ui.hud")

-- Подключаем отладку только если включена
local DebugDisplay = nil
if Constants.DEBUG_DRAW_FPS then
    DebugDisplay = require("src.system.debug_display")
end

local Game = {}
Game.__index = Game

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
