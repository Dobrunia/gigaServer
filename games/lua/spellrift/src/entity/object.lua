local SpriteManager = require("src.utils.sprite_manager")
local Constants = require("src.constants")

local Object = {}
Object.__index = Object

local DEFAULT_WIDTH = 64
local DEFAULT_HEIGHT = 64
local DEFAULT_ANIMATION_SPEED = 0.3

function Object.new(spriteSheet, x, y, targetWidth, targetHeight)
    local self = setmetatable({}, Object)
    self.x = x
    self.y = y
    
    -- Базовый размер спрайта всегда 64x64
    self.baseWidth = DEFAULT_WIDTH
    self.baseHeight = DEFAULT_HEIGHT
    
    -- Целевой размер в пикселях (из конфига)
    self.targetWidth = targetWidth or DEFAULT_WIDTH
    self.targetHeight = targetHeight or DEFAULT_HEIGHT
    
    -- Рассчитываем масштаб относительно базового размера
    self.scaleWidth = self.targetWidth / self.baseWidth
    self.scaleHeight = self.targetHeight / self.baseHeight
    
    -- Эффективные размеры для коллизий (равны целевому размеру)
    self.effectiveWidth = self.targetWidth
    self.effectiveHeight = self.targetHeight
    
    self.spriteSheet = spriteSheet
    self.currentAnimation = "idle"
    self.currentAnimationTime = 0
    self.currentAnimationFrame = 1
    self.animationsList = {}
    return self
end

function Object:changePosition(x, y)
    self.x = self.x + x
    self.y = self.y + y
end

function Object:setScale(scaleWidth, scaleHeight)
    self.scaleWidth = scaleWidth
    self.scaleHeight = scaleHeight
    self.targetWidth = self.baseWidth * self.scaleWidth
    self.targetHeight = self.baseHeight * self.scaleHeight
    self.effectiveWidth = self.targetWidth
    self.effectiveHeight = self.targetHeight
end

function Object:setSize(targetWidth, targetHeight)
    self.targetWidth = targetWidth
    self.targetHeight = targetHeight
    self.scaleWidth = self.targetWidth / self.baseWidth
    self.scaleHeight = self.targetHeight / self.baseHeight
    self.effectiveWidth = self.targetWidth
    self.effectiveHeight = self.targetHeight
end

function Object:setAnimationList(animationName, startRow, startCol, endCol, animationSpeed)
    local anim = {
        startRow = startRow,
        startCol = startCol,
        endCol = endCol,
        animationSpeed = animationSpeed or DEFAULT_ANIMATION_SPEED,
        totalFrames = endCol - startCol + 1,
        quads = {}  -- предкэш кадров
    }

    -- Предкэшируем все кадры через SpriteManager.getQuad
    for i = 0, (anim.totalFrames - 1) do
        local col = startCol + i
        anim.quads[i + 1] = SpriteManager.getQuad(self.spriteSheet, col, startRow, self.baseWidth, self.baseHeight)
    end

    self.animationsList[animationName] = anim
end

function Object:getCurrentQuad()
    if not (self.currentAnimation and self.animationsList[self.currentAnimation]) then
        return nil
    end
    local anim = self.animationsList[self.currentAnimation]
    -- если по какой-то причине quads не был заполнен — подстрахуемся
    if anim.quads and anim.quads[self.currentAnimationFrame] then
        return anim.quads[self.currentAnimationFrame]
    else
        -- fallback: безопасно получить quad "на лету"
        local currentCol = anim.startCol + self.currentAnimationFrame - 1
        return SpriteManager.getQuad(self.spriteSheet, currentCol, anim.startRow, self.baseWidth, self.baseHeight)
    end
end

function Object:playAnimation(animationName)
    if self.animationsList[animationName] then
        self.currentAnimation = animationName
        self.currentAnimationTime = 0
        self.currentAnimationFrame = 1
    end
end

function Object:update(dt)
    if self.currentAnimation and self.animationsList[self.currentAnimation] then
        local anim = self.animationsList[self.currentAnimation]
        self.currentAnimationTime = self.currentAnimationTime + dt
        
        if self.currentAnimationTime >= anim.animationSpeed then
            self.currentAnimationTime = 0
            self.currentAnimationFrame = self.currentAnimationFrame + 1
            
            if self.currentAnimationFrame > anim.totalFrames then
                self.currentAnimationFrame = 1
            end
        end
    end
end

function Object:draw()
    if not (self.spriteSheet and self.currentAnimation and self.animationsList[self.currentAnimation]) then
        return
    end
    local quad = self:getCurrentQuad()
    if quad then
        local sx = (self.facing == -1) and -1 or 1
        local ox = (sx == -1) and self.baseWidth or 0
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y, 0, sx * self.scaleWidth, self.scaleHeight, ox, 0)
    end
    
    -- Рисуем хитбокс если включена отладка
    if Constants.DEBUG_DRAW_HITBOXES then
        love.graphics.setColor(0, 1, 0, 0.5) -- зеленый полупрозрачный
        love.graphics.rectangle("line", self.x, self.y, self.effectiveWidth, self.effectiveHeight)
        love.graphics.setColor(1, 1, 1, 1) -- сбрасываем цвет
    end
end

return Object