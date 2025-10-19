-- main.lua
-- Точка входа для LÖVE

-- Подключаем менеджер игры (в src/init.lua)
local Game = require("src.init")

function love.load(args)
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

-- Коротко: main.lua только проксирует вызовы LÖVE в модуль Game. Это облегчает масштабирование и тестирование.