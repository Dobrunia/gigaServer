local SpriteManager = require("src.utils.sprite_manager")

local Object = {}
Object.__index = Object

local DEFAULT_WIDTH = 64
local DEFAULT_HEIGHT = 64
local DEFAULT_ANIMATION_SPEED = 0.3

function Object.new(spriteSheet, x, y, config)
    local self = setmetatable({}, Object)
    self.x = x
    self.y = y
    
    -- Используем tileWidth/tileHeight из конфига, если есть, иначе width/height, иначе дефолты
    self.width = (config and config.tileWidth) or (config and config.width) or DEFAULT_WIDTH
    self.height = (config and config.tileHeight) or (config and config.height) or DEFAULT_HEIGHT
    
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
    local anim = {
        startRow = startRow,
        startCol = startCol,
        endCol   = endCol,
        animationSpeed = animationSpeed or DEFAULT_ANIMATION_SPEED,
        totalFrames    = endCol - startCol + 1,
        quads = {}  -- предкэш кадров
    }

    -- Предкэшируем все кадры через SpriteManager.getQuad
    for i = 0, (anim.totalFrames - 1) do
        local col = startCol + i
        anim.quads[i + 1] = SpriteManager.getQuad(self.spriteSheet, col, startRow, self.width, self.height)
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
        return SpriteManager.getQuad(self.spriteSheet, currentCol, anim.startRow, self.width, self.height)
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
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y)
    end
end

return Object