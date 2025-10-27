local Object = {}
Object.__index = Object

local DEFAULT_WIDTH = 64
local DEFAULT_HEIGHT = 64
local DEFAULT_ANIMATION_SPEED = 0.3

function Object.new(spriteSheet, x, y, width, height)
    local self = setmetatable({}, Object)
    self.x = x
    self.y = y
    self.width = width or DEFAULT_WIDTH
    self.height = height or DEFAULT_HEIGHT
    
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

function Object:setAnimationList(animationName, startRow, startCol, endCol, animationSpeed)
    self.animationsList[animationName] = {
        startRow = startRow,
        startCol = startCol,
        endCol = endCol,
        animationSpeed = animationSpeed or DEFAULT_ANIMATION_SPEED,
        totalFrames = endCol - startCol + 1
    }
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
    if self.spriteSheet and self.currentAnimation and self.animationsList[self.currentAnimation] then
        local anim = self.animationsList[self.currentAnimation]
        local currentCol = anim.startCol + self.currentAnimationFrame - 1
        
        -- Создаем quad для текущего кадра
        local quad = love.graphics.newQuad(
            (currentCol - 1) * self.width,           -- x
            (anim.startRow - 1) * self.height,      -- y
            self.width,                             -- width
            self.height,                            -- height
            self.spriteSheet:getWidth(),            -- image width
            self.spriteSheet:getHeight()            -- image height
        )
        
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y)
    end
end

return Object