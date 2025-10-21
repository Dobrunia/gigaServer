-- assets.lua
-- Asset loading and caching system
-- Public API: Assets.load(), Assets.get(type, name), Assets.getQuad(sheet, index)
-- Dependencies: utils.lua

local Utils = require("src.utils")

local Assets = {
    images = {},
    fonts = {},
    sounds = {},
    spritesheets = {},
    quads = {},
    loaded = false
}

-- === SPRITE SHEET CONFIGURATION ===

-- Sprite dimensions (32x32 tiles)
local SPRITE_SIZE = 32
local TILES_PER_ROW = 16

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

-- === QUAD GENERATION ===

-- Generate quads for a spritesheet
-- @param image: the loaded image
-- @param tileSize: size of each tile (default 32)
-- @param tilesPerRow: number of tiles per row (default 16)
-- @return table of quads indexed from 1
local function generateQuads(image, tileSize, tilesPerRow)
    tileSize = tileSize or SPRITE_SIZE
    tilesPerRow = tilesPerRow or TILES_PER_ROW
    
    local imageWidth, imageHeight = image:getDimensions()
    local cols = math.floor(imageWidth / tileSize)
    local rows = math.floor(imageHeight / tileSize)
    
    local quads = {}
    local index = 1
    
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            quads[index] = love.graphics.newQuad(
                col * tileSize,
                row * tileSize,
                tileSize,
                tileSize,
                imageWidth,
                imageHeight
            )
            index = index + 1
        end
    end
    
    return quads
end

-- === LOADING ===

function Assets.load()
    Utils.log("Loading assets...")
    
    -- Load fonts
    Assets.fonts.default = love.graphics.newFont(16)
    Assets.fonts.large = love.graphics.newFont(32)
    Assets.fonts.small = love.graphics.newFont(12)
    Assets.fonts.debug = love.graphics.newFont(10)
    
    -- === LOAD SPRITESHEETS ===
    
    -- Load tiles spritesheet (for map/environment)
    local tilesSuccess, tilesImage = pcall(love.graphics.newImage, "assets/tiles.png")
    if tilesSuccess then
        Assets.spritesheets.tiles = tilesImage
        Assets.quads.tiles = generateQuads(tilesImage)
        Utils.log("Loaded tiles spritesheet (" .. #Assets.quads.tiles .. " tiles)")
    else
        Utils.logError("Failed to load tiles.png - using placeholder")
        Assets.spritesheets.tiles = createPlaceholder(512, 512, 0.15, 0.2, 0.15)
    end
    
    -- Load rogues/heroes spritesheet
    local roguesSuccess, roguesImage = pcall(love.graphics.newImage, "assets/rogues.png")
    if roguesSuccess then
        Assets.spritesheets.rogues = roguesImage
        Assets.quads.rogues = generateQuads(roguesImage)
        Utils.log("Loaded rogues spritesheet (" .. #Assets.quads.rogues .. " sprites)")
    else
        Utils.logError("Failed to load rogues.png - using placeholder: " .. tostring(roguesImage))
        Assets.spritesheets.rogues = createPlaceholder(512, 512, 0.2, 0.8, 0.2)
        Assets.quads.rogues = {}
    end
    
    -- Load monsters spritesheet
    local monstersSuccess, monstersImage = pcall(love.graphics.newImage, "assets/monsters.png")
    if monstersSuccess then
        Assets.spritesheets.monsters = monstersImage
        Assets.quads.monsters = generateQuads(monstersImage)
        Utils.log("Loaded monsters spritesheet (" .. #Assets.quads.monsters .. " sprites)")
    else
        Utils.logError("Failed to load monsters.png - using placeholder: " .. tostring(monstersImage))
        Assets.spritesheets.monsters = createPlaceholder(512, 512, 0.9, 0.2, 0.2)
        Assets.quads.monsters = {}
    end
    
    -- === CREATE SPRITE REFERENCES ===
    -- Map named sprites to specific quad indices based on sprite definitions
    
    -- Player sprites (from rogues.png) - 7×7 GRID (49 quads total)
    -- Formula: (row-1) × 7 + col
    
    -- Row 1: dwarf, elf, ranger, rogue, bandit (indices 1-7)
    Assets.images.playerDwarf = 1    -- 1.a: (1-1)×7+1 = 1
    Assets.images.playerElf = 2      -- 1.b: (1-1)×7+2 = 2
    Assets.images.playerRanger = 3   -- 1.c
    Assets.images.playerRogue = 4    -- 1.d
    Assets.images.player = 2         -- default to elf
    
    -- Row 2: knights (indices 8-14)
    Assets.images.playerKnight = 8        -- 2.a: (2-1)×7+1 = 8
    Assets.images.playerFighter = 9       -- 2.b: (2-1)×7+2 = 9
    Assets.images.playerFemaleKnight = 10 -- 2.c: (2-1)×7+3 = 10
    
    -- Row 3: clerics/monks (indices 15-21)
    Assets.images.playerMonk = 15    -- 3.a: (3-1)×7+1 = 15
    Assets.images.playerPriest = 16  -- 3.b: (3-1)×7+2 = 16
    
    -- Row 4: barbarians (indices 22-28)
    Assets.images.playerBarbarian = 22  -- 4.a: (4-1)×7+1 = 22
    
    -- Row 5: wizards (indices 29-35)
    Assets.images.playerWizard = 30     -- 5.b: (5-1)×7+2 = 30 (male wizard)
    Assets.images.playerDruid = 31      -- 5.c: (5-1)×7+3 = 31
    
    -- Mob sprites (from monsters.png)
    -- Row 1: orcs and goblins
    Assets.images.mobOrc = 1         -- 1.a orc
    Assets.images.mobGoblin = 3      -- 1.c goblin
    Assets.images.mobOrcBlademaster = 4  -- 1.d
    Assets.images.mobGoblinArcher = 6    -- 1.f
    
    -- Row 2: ettins/trolls
    Assets.images.mobEttin = 17      -- 2.a
    Assets.images.mobTroll = 19      -- 2.c
    
    -- Row 3: slimes
    Assets.images.mobSlime = 33      -- 3.a small slime
    Assets.images.mobBigSlime = 34   -- 3.b big slime
    
    -- Row 5: undead (starting at index 65)
    Assets.images.mobSkeleton = 65        -- 5.a
    Assets.images.mobSkeletonArcher = 66  -- 5.b
    Assets.images.mobLich = 67            -- 5.c (boss)
    Assets.images.mobZombie = 69          -- 5.e
    
    -- Row 7: creatures (starting at index 97)
    Assets.images.mobCentipede = 97   -- 7.a
    Assets.images.mobSpider = 105     -- 7.i
    Assets.images.mobRat = 108        -- 7.l
    
    -- Row 9: dragons (starting at index 129)
    Assets.images.mobDrake = 130      -- 9.b
    Assets.images.mobDragon = 131     -- 9.c (boss)
    
    -- Default mob sprites
    Assets.images.mobMelee = 1        -- default to orc
    Assets.images.mobRanged = 6       -- default to goblin archer
    Assets.images.boss = 67           -- default to lich
    
    -- Projectile sprites from items.png
    -- 24.a arrow = (24-1) * 16 + 1 = 369
    -- 24.c bolt = (24-1) * 16 + 3 = 371
    Assets.images.projectilePlayer = 371  -- Bolt for player projectiles
    Assets.images.projectileMob = 371     -- Bolt for mob projectiles
    
    -- Load items spritesheet for XP drops, potions, etc
    local itemsSuccess, itemsImage = pcall(love.graphics.newImage, "assets/items.png")
    if itemsSuccess then
        Assets.spritesheets.items = itemsImage
        Assets.quads.items = generateQuads(itemsImage)
        Utils.log("Loaded items spritesheet (" .. #Assets.quads.items .. " items)")
    else
        Utils.logError("Failed to load items.png - using placeholder: " .. tostring(itemsImage))
        Assets.spritesheets.items = createPlaceholder(512, 512, 0.5, 0.5, 0.6)
        Assets.quads.items = {}
    end
    
    -- XP drop (use blue potion sprite from items.png - 21.d = row 21, col 4)
    -- Index calculation: (row-1) * 16 + col = (21-1) * 16 + 4 = 324
    Assets.images.xpDrop = 324  -- Blue potion index
    
    -- Skill icons (placeholder for now)
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
    
    -- Map texture - use tile quads or placeholder
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

function Assets.getSpritesheet(name)
    return Assets.spritesheets[name]
end

function Assets.getQuad(sheetName, index)
    if Assets.quads[sheetName] and Assets.quads[sheetName][index] then
        return Assets.quads[sheetName][index]
    end
    return nil
end

-- Get spritesheet and quad for a sprite index
-- Returns: spritesheet, quad
function Assets.getSprite(sheetName, index)
    local sheet = Assets.spritesheets[sheetName]
    local quad = Assets.getQuad(sheetName, index)
    return sheet, quad
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

