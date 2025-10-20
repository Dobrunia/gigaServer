-- main.lua
-- Точка входа для LÖVE

-- Подключаем менеджер игры (в src/init.lua)
local Game = require("src.init")

function love.load(args)
    -- Настройка окна
    love.window.setTitle("Doblike")
    love.window.setMode(1280, 720, {
        resizable = true,
        vsync = 1,
        minwidth = 800,
        minheight = 600
    })
    
    -- инициализация RNG, шрифтов и т.п.
    math.randomseed(os.time())
    love.graphics.setDefaultFilter("nearest", "nearest")
    Game:load()
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end

function love.keypressed(key, scancode, isrepeat)
    Game:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch, presses)
    Game:mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    Game:mousemoved(x, y, dx, dy)
end

-- Коротко: main.lua только проксирует вызовы LÖVE в модуль Game. Это облегчает масштабирование и тестирование.