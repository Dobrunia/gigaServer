local UIConstants = require("src.ui.ui_constants")

local UIPauseMenu = {}
UIPauseMenu.__index = UIPauseMenu

function UIPauseMenu.new()
  local self = setmetatable({}, UIPauseMenu)
  self.title = "Pause"

  -- размеры/позиция кнопки будут рассчитаны из размеров окна
  local w, h = love.graphics.getDimensions()
  self:setupLayout(w, h)

  -- шрифты (опционально можно заменить на твои)
  self.fontTitle = love.graphics.newFont(UIConstants.FONT_LARGE)
  self.fontBtn = love.graphics.newFont(UIConstants.FONT_MEDIUM)

  -- состояния наведения/нажатия
  self.isHover = false
  self.isDown = false

  return self
end

function UIPauseMenu:setupLayout(w, h)
  self.cx, self.cy = w * 0.5, h * 0.5
  self.btnW, self.btnH = math.min(280, w * 0.6), 56
  self.btnX, self.btnY = self.cx - self.btnW * 0.5, self.cy - self.btnH * 0.5
  self.titleY = self.btnY - 80
end

local function pointInRect(px, py, x, y, w, h)
  return (px >= x and px <= x + w and py >= y and py <= y + h)
end

-- Возвращает "resume", если была нажата кнопка
function UIPauseMenu:update(dt, input)
  local mx, my = input:getMousePosition()

  self.isHover = pointInRect(mx, my, self.btnX, self.btnY, self.btnW, self.btnH)

  -- фиксируем нажатие/отжатие ЛКМ
  local clicked = false
  if input.isLeftMousePressed and input:isLeftMousePressed() then
    self.isDown = self.isHover
  end
  if input.isLeftMouseReleased and input:isLeftMouseReleased() then
    clicked = self.isHover and self.isDown
    self.isDown = false
  end

  if clicked then
    return "resume"
  end
  return nil
end

function UIPauseMenu:draw()
  -- Заголовок
  love.graphics.setFont(self.fontTitle)
  love.graphics.printf(self.title, 0, self.titleY, love.graphics.getWidth(), "center")

  -- Кнопка
  local r = 10
  love.graphics.setFont(self.fontBtn)

  -- фон кнопки (разные альфы для hover/pressed)
  if self.isDown then
    love.graphics.setColor(1, 1, 1, 0.15)
  elseif self.isHover then
    love.graphics.setColor(1, 1, 1, 0.10)
  else
    love.graphics.setColor(1, 1, 1, 0.07)
  end
  love.graphics.rectangle("fill", self.btnX, self.btnY, self.btnW, self.btnH, r, r)

  -- рамка
  if self.isHover then
    love.graphics.setColor(1, 1, 1, 0.8)
  else
    love.graphics.setColor(1, 1, 1, 0.5)
  end
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", self.btnX, self.btnY, self.btnW, self.btnH, r, r)

  -- текст
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Resume", self.btnX, self.btnY + (self.btnH - self.fontBtn:getHeight())*0.5, self.btnW, "center")
end

return UIPauseMenu
