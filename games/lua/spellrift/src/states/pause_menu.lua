local Input = require("src.system.input")
local UIPauseMenu = require("src.ui.ui_pause_menu")

local PauseMenu = {}
PauseMenu.__index = PauseMenu

function PauseMenu:enter()
  self.input = Input.new()
  self.ui = UIPauseMenu.new()

  self.w, self.h = love.graphics.getDimensions()
end

function PauseMenu:update(dt)
  self.input:update(dt)

  -- ESC → продолжить
  if self.input.isEscapePressed and self.input:isEscapePressed() then
    self:resumeGame()
    return
  end

  -- Клик по кнопке → продолжить
  local clicked = self.ui:update(dt, self.input)
  if clicked == "resume" then
    self:resumeGame()
    return
  end
end

-- Рисуем только затемнение и UI. Предполагается, что сам Game не обновляется пока это состояние активно.
function PauseMenu:draw()
  -- затемняем фон (поверх того, что уже отрисовал предыдущий state, если менеджер так делает)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", 0, 0, self.w, self.h)
  love.graphics.setColor(1, 1, 1, 1)

  self.ui:draw()
end

function PauseMenu:resumeGame()
  -- 1) если менеджер поддерживает стек состояний — просто pop
  if self.manager and self.manager.pop then
    self.manager:pop()
    return
  end
  -- 2) иначе — дергаем колбэк, если передан
  if self.ctx and type(self.ctx.onResume) == "function" then
    self.ctx.onResume()
  end
end

function PauseMenu:exit()
  self.ui = nil
  self.input = nil
  self.ctx = nil
end

return PauseMenu
