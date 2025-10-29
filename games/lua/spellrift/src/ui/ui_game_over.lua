local Constants = require("src.constants")

local UIGameOver = {}
UIGameOver.__index = UIGameOver

-- Константы для UI
local UI_CONSTANTS = {
    FONT_LARGE = 48,
    FONT_MEDIUM = 24,
    FONT_SMALL = 18,
    BUTTON_WIDTH = 200,
    BUTTON_HEIGHT = 50,
    BUTTON_PADDING = 10,
    BUTTON_SPACING = 20,
    CARD_WIDTH = 400,
    CARD_HEIGHT = 300,
    CARD_PADDING = 20
}

-- Цвета
local Colors = {
    BACKGROUND = {0, 0, 0, 0.8},
    CARD_BG = {0.1, 0.1, 0.1, 0.9},
    CARD_BORDER = {0.3, 0.3, 0.3, 1},
    TEXT_PRIMARY = {1, 1, 1, 1},
    TEXT_ACCENT = {1, 0.8, 0, 1},
    BUTTON_NORMAL = {0.2, 0.2, 0.2, 0.9},
    BUTTON_HOVER = {0.3, 0.3, 0.3, 0.9},
    BUTTON_PRESSED = {0.1, 0.1, 0.1, 0.9},
    BUTTON_BORDER = {0.5, 0.5, 0.5, 1}
}

function UIGameOver.new()
    local self = setmetatable({}, UIGameOver)
    
    -- Кеш шрифтов
    self.fontLarge = love.graphics.newFont(UI_CONSTANTS.FONT_LARGE)
    self.fontMedium = love.graphics.newFont(UI_CONSTANTS.FONT_MEDIUM)
    self.fontSmall = love.graphics.newFont(UI_CONSTANTS.FONT_SMALL)
    
    -- Состояние кнопок
    self.buttons = {
        {
            text = "Restart",
            action = "restart",
            x = 0, y = 0, -- будет установлено в draw
            width = UI_CONSTANTS.BUTTON_WIDTH,
            height = UI_CONSTANTS.BUTTON_HEIGHT,
            hovered = false,
            pressed = false
        },
        {
            text = "Main Menu",
            action = "menu",
            x = 0, y = 0, -- будет установлено в draw
            width = UI_CONSTANTS.BUTTON_WIDTH,
            height = UI_CONSTANTS.BUTTON_HEIGHT,
            hovered = false,
            pressed = false
        }
    }
    
    -- Статистика игры
    self.gameStats = {
        level = 1,
        time = 0,
        enemiesKilled = 0,
        damageDealt = 0
    }
    
    return self
end

function UIGameOver:update(dt, input)
    if not input then return nil end
    
    local mouseX, mouseY = input:getMousePosition()
    local mousePressed = input:isLeftMousePressed()
    local mouseDown = input:isLeftMouseDown()
    
    -- Обновляем состояние кнопок
    for _, button in ipairs(self.buttons) do
        button.hovered = mouseX >= button.x and mouseX <= button.x + button.width and
                        mouseY >= button.y and mouseY <= button.y + button.height
        
        if button.hovered and mousePressed then
            button.pressed = true
        elseif not mouseDown then
            if button.pressed and button.hovered then
                return button.action
            end
            button.pressed = false
        end
    end
    
    return nil
end

function UIGameOver:draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Полупрозрачный фон
    love.graphics.setColor(Colors.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Центральная карточка
    local cardX = (screenW - UI_CONSTANTS.CARD_WIDTH) / 2
    local cardY = (screenH - UI_CONSTANTS.CARD_HEIGHT) / 2
    
    -- Фон карточки
    love.graphics.setColor(Colors.CARD_BG)
    love.graphics.rectangle("fill", cardX, cardY, UI_CONSTANTS.CARD_WIDTH, UI_CONSTANTS.CARD_HEIGHT, 8, 8)
    
    -- Граница карточки
    love.graphics.setColor(Colors.CARD_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", cardX, cardY, UI_CONSTANTS.CARD_WIDTH, UI_CONSTANTS.CARD_HEIGHT, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Заголовок
    love.graphics.setFont(self.fontLarge)
    love.graphics.setColor(Colors.TEXT_ACCENT)
    local titleText = "GAME OVER"
    local titleWidth = self.fontLarge:getWidth(titleText)
    local titleX = cardX + (UI_CONSTANTS.CARD_WIDTH - titleWidth) / 2
    local titleY = cardY + UI_CONSTANTS.CARD_PADDING
    love.graphics.print(titleText, titleX, titleY)
    
    -- Статистика
    local statsY = titleY + UI_CONSTANTS.FONT_LARGE + 20
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    
    local statsText = {
        "Level: " .. self.gameStats.level,
        "Time: " .. self:formatTime(self.gameStats.time),
        "Enemies Killed: " .. self.gameStats.enemiesKilled,
        "Damage Dealt: " .. math.floor(self.gameStats.damageDealt)
    }
    
    for i, text in ipairs(statsText) do
        love.graphics.print(text, cardX + UI_CONSTANTS.CARD_PADDING, statsY + (i - 1) * 30)
    end
    
    -- Кнопки
    local buttonsY = cardY + UI_CONSTANTS.CARD_HEIGHT - UI_CONSTANTS.BUTTON_HEIGHT - UI_CONSTANTS.CARD_PADDING
    local totalButtonsWidth = #self.buttons * UI_CONSTANTS.BUTTON_WIDTH + (#self.buttons - 1) * UI_CONSTANTS.BUTTON_SPACING
    local buttonsStartX = cardX + (UI_CONSTANTS.CARD_WIDTH - totalButtonsWidth) / 2
    
    for i, button in ipairs(self.buttons) do
        button.x = buttonsStartX + (i - 1) * (UI_CONSTANTS.BUTTON_WIDTH + UI_CONSTANTS.BUTTON_SPACING)
        button.y = buttonsY
        
        self:drawButton(button)
    end
end

function UIGameOver:drawButton(button)
    -- Цвет кнопки в зависимости от состояния
    local buttonColor = Colors.BUTTON_NORMAL
    if button.pressed then
        buttonColor = Colors.BUTTON_PRESSED
    elseif button.hovered then
        buttonColor = Colors.BUTTON_HOVER
    end
    
    -- Фон кнопки
    love.graphics.setColor(buttonColor)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
    
    -- Граница кнопки
    love.graphics.setColor(Colors.BUTTON_BORDER)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setLineWidth(1)
    
    -- Текст кнопки
    love.graphics.setFont(self.fontMedium)
    love.graphics.setColor(Colors.TEXT_PRIMARY)
    local textWidth = self.fontMedium:getWidth(button.text)
    local textHeight = self.fontMedium:getHeight()
    local textX = button.x + (button.width - textWidth) / 2
    local textY = button.y + (button.height - textHeight) / 2
    love.graphics.print(button.text, textX, textY)
end

function UIGameOver:setGameStats(stats)
    self.gameStats = stats or self.gameStats
end

function UIGameOver:formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

function UIGameOver:resize(w, h)
    -- Можно добавить логику для изменения размера UI при изменении окна
end

return UIGameOver
