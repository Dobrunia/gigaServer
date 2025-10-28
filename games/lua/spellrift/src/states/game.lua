local World = require("src.world.world")
local Input = require("src.system.input")
local Camera = require("src.system.camera")
local Minimap = require("src.system.minimap")
local Map = require("src.world.map")
local Constants = require("src.constants")
local UIPauseMenu = require("src.ui.ui_pause_menu")

local Game = {}
Game.__index = Game

function Game:enter(selectedHeroId, selectedSkillId)
  self.input = Input.new()
  self.input:snapshotNow()
  
  self.world = World.new()
  self.camera = Camera.new()
  self.minimap = Minimap.new()
  self.map = Map.new()

  self.isPaused = false
  self.uiPauseMenu = UIPauseMenu.new()

  -- fixed timestep аккумулятор
  self._accum = 0
  -- инициализация мира
  self.world:setup(selectedHeroId, selectedSkillId)
end

function Game:update(dt)
  -- обновляем ввод на реальном dt (чтобы клики/нажатия были отзывчивы)
  self.input:update(dt)

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
    end
    return -- не обновляем игру, но input работает
  end

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
    self.minimap:draw()
  end
end

function Game:resize(w, h)
  if self.uiPauseMenu and self.uiPauseMenu.resize then
    self.uiPauseMenu:resize(w, h)
  end
end

return Game
