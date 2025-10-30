local UIConstants = require("src.ui.ui_constants")

local UIPauseMenu = {}
UIPauseMenu.__index = UIPauseMenu

function UIPauseMenu.new()
  local self = setmetatable({}, UIPauseMenu)
  self.title = "Pause"

  -- кнопки (должны быть до setupLayout)
  self.buttons = {
    { id = "resume",    label = "Resume",    x = 0, y = 0, w = 0, h = 0, isHover = false, isDown = false },
    { id = "restart",   label = "Restart",   x = 0, y = 0, w = 0, h = 0, isHover = false, isDown = false },
    { id = "main_menu", label = "Main Menu", x = 0, y = 0, w = 0, h = 0, isHover = false, isDown = false },
  }

  -- размеры/позиция будут рассчитаны из размеров окна
  local w, h = love.graphics.getDimensions()
  self:setupLayout(w, h)

  -- шрифты (опционально можно заменить на твои)
  self.fontTitle = love.graphics.newFont(UIConstants.FONT_LARGE)
  self.fontBtn = love.graphics.newFont(UIConstants.FONT_MEDIUM)

  return self
end

function UIPauseMenu:setupLayout(w, h)
  self.cx, self.cy = w * 0.5, h * 0.5
  local btnW, btnH = math.min(320, w * 0.6), 56
  local gap = 12
  local totalH = btnH * #self.buttons + gap * (#self.buttons - 1)
  local startY = self.cy - totalH * 0.5
  local x = self.cx - btnW * 0.5

  for i = 1, #self.buttons do
    local b = self.buttons[i]
    b.x, b.y, b.w, b.h = x, startY + (i - 1) * (btnH + gap), btnW, btnH
  end

  self.titleY = startY - 80
end

local function pointInRect(px, py, x, y, w, h)
  return (px >= x and px <= x + w and py >= y and py <= y + h)
end

function UIPauseMenu:resize(w, h)
    self:setupLayout(w, h)
end

function UIPauseMenu:update(dt, input)
    -- экранные координаты подходят: input:getMousePosition() уже берёт love.mouse.getPosition()
    local mx, my = input:getMousePosition()

  local clicked = input:isLeftMousePressed()
  local isDown = input:isLeftMouseDown()

  for i = 1, #self.buttons do
    local b = self.buttons[i]
    b.isHover = (mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h)
    b.isDown = b.isHover and isDown
    if b.isHover and clicked then
      return b.id
    end
  end

  return nil
end  

function UIPauseMenu:draw()
  -- затемняем фон (поверх того, что уже отрисовал предыдущий state, если менеджер так делает)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Заголовок
  love.graphics.setFont(self.fontTitle)
  love.graphics.printf(self.title, 0, self.titleY, love.graphics.getWidth(), "center")

  -- Кнопки
  local r = 10
  love.graphics.setFont(self.fontBtn)

  for i = 1, #self.buttons do
    local b = self.buttons[i]

    -- фон
    if b.isDown then
      love.graphics.setColor(1, 1, 1, 0.15)
    elseif b.isHover then
      love.graphics.setColor(1, 1, 1, 0.10)
    else
      love.graphics.setColor(1, 1, 1, 0.07)
    end
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, r, r)

    -- рамка
    if b.isHover then
      love.graphics.setColor(1, 1, 1, 0.8)
    else
      love.graphics.setColor(1, 1, 1, 0.5)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", b.x, b.y, b.w, b.h, r, r)

    -- текст
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(b.label, b.x, b.y + (b.h - self.fontBtn:getHeight())*0.5, b.w, "center")
  end
end

return UIPauseMenu
