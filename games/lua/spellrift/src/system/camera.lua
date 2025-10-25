local Camera = {}
Camera.__index = Camera

function Camera.new(viewHeight)
    local self = setmetatable({}, Camera)

    -- позиция камеры в мировых координатах
    self.x = 0
    self.y = 0

    -- "высота" камеры над миром — можно думать как масштаб
    self.viewHeight = viewHeight or 1

    -- размеры экрана
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()

    return self
end

-- обновить позицию камеры (центр на объекте)
function Camera:update(targetX, targetY)
    self.x = targetX
    self.y = targetY
end

-- применить камеру перед отрисовкой мира
function Camera:apply()
    love.graphics.push()
    -- центрируем игрока в центре экрана
    love.graphics.translate(self.w / 2, self.h / 2)
    -- учитываем "высоту" камеры (масштаб)
    love.graphics.scale(1 / self.viewHeight)
    -- сдвигаем мир, чтобы нужная точка оказалась в центре
    love.graphics.translate(-self.x, -self.y)
end

-- снять камеру после отрисовки
function Camera:clear()
    love.graphics.pop()
end

-- пересчитать размер при изменении окна
function Camera:resize(w, h)
    self.w = w
    self.h = h
end

return Camera
