local UIConstants = require("src.ui.ui_constants")

local UIMainMenu = {}
UIMainMenu.__index = UIMainMenu

local MENU_BUTTON_WIDTH = 200
local MENU_BUTTON_HEIGHT = 40

local COLOR_BUTTON_DEFAULT = {0.2, 0.2, 0.2, 1}
local COLOR_BUTTON_HOVER = {0.4, 0.4, 0.4, 1}
local BUTTON_BORDER = {0.8, 0.8, 0.8, 1}
local BUTTON_BORDER_RADIUS = 8

function UIMainMenu.new()
    local self = setmetatable({}, UIMainMenu)
    -- кнопки: старт и альманах
    self.buttons = {
        { id = "start",   label = "START GAME", x = 0, y = 0, w = MENU_BUTTON_WIDTH, h = MENU_BUTTON_HEIGHT },
        { id = "almanac", label = "ALMANAC",    x = 0, y = 0, w = MENU_BUTTON_WIDTH, h = MENU_BUTTON_HEIGHT },
    }

    -- шрифты
    self.fontTitle = love.graphics.newFont(UIConstants.FONT_LARGE)
    self.fontBtn = love.graphics.newFont(UIConstants.FONT_MEDIUM)

    -- Вычислим позиции кнопок один раз
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local totalH = MENU_BUTTON_HEIGHT * #self.buttons + 12 * (#self.buttons - 1)
    local startY = (h - totalH) / 2
    local x = (w - MENU_BUTTON_WIDTH) / 2
    for i = 1, #self.buttons do
        local b = self.buttons[i]
        b.x = x
        b.y = startY + (i - 1) * (MENU_BUTTON_HEIGHT + 12)
    end

    return self
end

function UIMainMenu:isButtonHovered(x, y)
    -- совместимость: ховер по первой кнопке (start)
    local b = self.buttons and self.buttons[1]
    if not b then return false end
    return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

function UIMainMenu:hitTest(x, y)
    if not self.buttons then return nil end
    for i = 1, #self.buttons do
        local b = self.buttons[i]
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            return b.id
        end
    end
    return nil
end

function UIMainMenu:draw()
    love.graphics.setColor(COLOR_BUTTON_DEFAULT)

    love.graphics.setFont(self.fontTitle)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DOBLIKE ROGUELIKE", 0, UIConstants.START_Y * 6, love.graphics.getWidth(), "center")

    -- Подложка под блок кнопок (затемнение как в паузе)
    local padding = 16
    local top = self.buttons[1].y - padding
    local bottom = self.buttons[#self.buttons].y + self.buttons[#self.buttons].h + padding
    local left = self.buttons[1].x - padding
    local right = self.buttons[1].x + self.buttons[1].w + padding
    local panelW = right - left
    local panelH = bottom - top
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", left, top, panelW, panelH, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", left, top, panelW, panelH, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
    love.graphics.setColor(1, 1, 1, 1)

    -- Кнопки
    local mx, my = love.mouse.getPosition()
    for i = 1, #self.buttons do
        local b = self.buttons[i]
        local hovered = (mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h)

        -- фон
        if hovered then
            love.graphics.setColor(1, 1, 1, 0.10)
        else
            love.graphics.setColor(1, 1, 1, 0.07)
        end
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)

        -- рамка
        love.graphics.setColor(hovered and {1,1,1,0.8} or {1,1,1,0.5})
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", b.x, b.y, b.w, b.h, BUTTON_BORDER_RADIUS, BUTTON_BORDER_RADIUS)
        love.graphics.setLineWidth(1)

        -- текст
        love.graphics.setFont(self.fontBtn)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(b.label, b.x, b.y + (b.h - self.fontBtn:getHeight()) * 0.5, b.w, "center")
    end
end

return UIMainMenu
