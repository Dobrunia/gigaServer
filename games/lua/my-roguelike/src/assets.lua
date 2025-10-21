-- assets.lua
-- Asset loading and caching system
-- Public API: Assets.load(), Assets.get(type, name)
-- Dependencies: utils.lua

local Utils = require("src.utils")

local Assets = {
    images = {},
    fonts = {},
    sounds = {},
    loaded = false
}

-- === PLACEHOLDER GENERATION ===

-- Generate colored rectangle as placeholder sprite
local function createPlaceholder(width, height, r, g, b)
    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(r, g, b, 1)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", 1, 1, width - 2, height - 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
    return canvas
end

-- === LOADING ===

function Assets.load()
    Utils.log("Loading assets...")
    
    -- Load fonts
    Assets.fonts.default = love.graphics.newFont(16)
    Assets.fonts.large = love.graphics.newFont(32)
    Assets.fonts.small = love.graphics.newFont(12)
    Assets.fonts.debug = love.graphics.newFont(10)
    
    -- Load or create placeholder images
    -- TODO: Replace with actual sprite loading from assets/ directory
    
    -- Player sprites (placeholder: green)
    Assets.images.player = createPlaceholder(32, 32, 0.2, 0.8, 0.2)
    
    -- Mob sprites (placeholder: red/orange)
    Assets.images.mobMelee = createPlaceholder(32, 32, 0.9, 0.2, 0.2)
    Assets.images.mobRanged = createPlaceholder(32, 32, 0.9, 0.5, 0.2)
    Assets.images.boss = createPlaceholder(64, 64, 0.7, 0.1, 0.7)
    
    -- Projectile sprites (placeholder: yellow/cyan)
    Assets.images.projectilePlayer = createPlaceholder(16, 16, 1, 1, 0.3)
    Assets.images.projectileMob = createPlaceholder(16, 16, 1, 0.5, 0.5)
    
    -- XP drop (placeholder: blue)
    Assets.images.xpDrop = createPlaceholder(16, 16, 0.3, 0.5, 1)
    
    -- Skill icons (placeholder: colored squares)
    Assets.images.skillDefault = createPlaceholder(48, 48, 0.5, 0.5, 0.8)
    Assets.images.skillEmpty = createPlaceholder(48, 48, 0.2, 0.2, 0.2)
    
    -- Status effect icons (small)
    Assets.images.statusSlow = createPlaceholder(16, 16, 0.5, 0.5, 1)
    Assets.images.statusPoison = createPlaceholder(16, 16, 0.2, 0.8, 0.2)
    Assets.images.statusRoot = createPlaceholder(16, 16, 0.6, 0.4, 0.2)
    Assets.images.statusStun = createPlaceholder(16, 16, 1, 1, 0.2)
    
    -- UI elements
    Assets.images.menuBg = createPlaceholder(1280, 720, 0.1, 0.1, 0.15)
    Assets.images.hudBg = createPlaceholder(1280, 120, 0, 0, 0)
    
    -- Map texture (simple gradient for now)
    Assets.images.mapTexture = createPlaceholder(3200, 2400, 0.15, 0.2, 0.15)
    
    -- TODO: Load sounds
    -- Assets.sounds.hit = love.audio.newSource("assets/sounds/hit.ogg", "static")
    -- Assets.sounds.levelup = love.audio.newSource("assets/sounds/levelup.ogg", "static")
    -- etc.
    
    Assets.loaded = true
    Utils.log("Assets loaded successfully")
end

-- === ACCESS ===

function Assets.getImage(name)
    return Assets.images[name]
end

function Assets.getFont(name)
    return Assets.fonts[name] or Assets.fonts.default
end

function Assets.getSound(name)
    return Assets.sounds[name]
end

-- === SPRITE LOADING (for future real assets) ===

function Assets.loadImage(name, path)
    local success, img = pcall(love.graphics.newImage, path)
    if success then
        Assets.images[name] = img
        Utils.log("Loaded image: " .. name)
        return true
    else
        Utils.logError("Failed to load image: " .. path)
        return false
    end
end

function Assets.loadSound(name, path, sourceType)
    sourceType = sourceType or "static"
    local success, sound = pcall(love.audio.newSource, path, sourceType)
    if success then
        Assets.sounds[name] = sound
        Utils.log("Loaded sound: " .. name)
        return true
    else
        Utils.logError("Failed to load sound: " .. path)
        return false
    end
end

return Assets

