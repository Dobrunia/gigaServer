local UIConstants = require("src.ui.ui_constants")
local heroes = require("src.config.heroes")

local HeroSelect = {}
HeroSelect.__index = HeroSelect

local CARD_WIDTH = 500
local CARD_HEIGHT = 390
local CARD_SPACING = 40
local CARDS_PER_ROW = 3
local CARDS_START_Y = 100
local CARD_BORDER_RADIUS = 8
local CARD_PADDING = 20
local CARD_MAIN_SPRITE_SIZE = 128
local CARD_ELEMENTS_OFFSET_Y = 100
local CARD_ELEMENTS_OFFSET_X = 100

local MAIN_CARD_BACKGROUND =
local SMALL_CARD_BACKGROUND = 

local CARD_INNATE_SPRITE_SIZE = 40
local CARD_DESCRIPTION_HEIGHT= CARD_INNATE_SPRITE_SIZE + CARD_PADDING * 2


local ICON_STAT_SIZE = UIConstants.FONT_MEDIUM

function HeroSelect.new()
    local self = setmetatable({}, HeroSelect)

    -- Получаем список всех персонажей
    self.characters = {}
    self:loadCharacters()
    return self
end

function HeroSelect:loadCharacters()
    -- Проходим по всем персонажам из конфига
    for heroId, heroConfig in pairs(heroes) do
        local character = {
            sprite = SpriteManager.loadHeroSprite(heroId), -- TODO: мб без кэша надо
            config = heroConfig
        }
        
        table.insert(self.characters, character)
    end
end

-- === DRAW ===

function HeroSelect:draw()
    Colors.setColor(MAIN_CARD_BACKGROUND)
    love.graphics.clear()
    
    -- Title
    love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
    Colors.setColor(UIConstants.COLOR_TEXT_PRIMARY)
    love.graphics.printf("Choose Your Hero", 0, UIConstants.START_Y, love.graphics.getWidth(), "center")
    
    -- Hero cards grid
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Calculate grid positioning
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, character in ipairs(self.characters) do
        local hero = character.config
        local sprite = character.sprite

        local row = math.floor((i - 1) / CARDS_PER_ROW)
        local col = ((i - 1) % CARDS_PER_ROW)
        
        local cardX = startX + col * (CARD_WIDTH + CARD_SPACING)
        local cardY = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)
        
        love.graphics.rectangle("fill", cardX, cardY, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
        
        -- Card border
        Colors.setColor(MAIN_CARD_BACKGROUND)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cardX, cardY, CARD_WIDTH, CARD_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
        love.graphics.setLineWidth(1)
        
        -- Hero name
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_LARGE))
        Colors.setColor(UIConstants.COLOR_TEXT_PRIMARY)
        local nameX = cardX + CARD_PADDING
        local nameY = cardY + CARD_PADDING
        love.graphics.print(hero.name, nameX, nameY)
        
        -- Hero sprite
        local spriteX = nameX + CARD_MAIN_SPRITE_SIZE / 2
        local spriteY = nameY + CARD_ELEMENTS_OFFSET_Y

        -- Используем SpriteManager.getQuad для создания quad
        local spriteIdleQuad = SpriteManager.getQuad(spriteSheet, 1, 1, 64, 64)   
        -- Scale sprite to fit configured size in card
        local targetSize = CARD_MAIN_SPRITE_SIZE
        local scale = targetSize / 64
        love.graphics.draw(spriteSheet, spriteIdleQuad, spriteX, spriteY, 0, scale, scale, 32, 32)

        -- Key stats with growth (moved to right side) with icons
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))

        local statsX = spriteX + CARD_ELEMENTS_OFFSET_X
        local statsY = spriteY - CARD_MAIN_SPRITE_SIZE / 2
        local statsOffset = ICON_STAT_SIZE + 10

        -- HP with heart icon
        local hpIcon = Icons.getHP()
        Icons.drawWithText(hpIcon, hero.baseHp .. " (+" .. hero.hpGrowth .. ")", statsX, statsY, ICON_STAT_SIZE)
        
        -- Armor with shield icon
        local armorY = statsY + statsOffset
        local armorIcon = Icons.getArmor()
        Icons.drawWithText(armorIcon, hero.baseArmor .. " (+" .. hero.armorGrowth .. ")", statsX, armorY, ICON_STAT_SIZE)
        
        -- Speed with shoe icon
        local speedY = armorY + statsOffset
        local speedIcon = Icons.getSpeed()
        Icons.drawWithText(speedIcon, hero.baseMoveSpeed .. " (+" .. hero.speedGrowth .. ")", statsX, speedY, ICON_STAT_SIZE)
        
        -- Cast Speed with hourglass icon
        local castSpeedY = speedY + statsOffset
        local castIcon = Icons.getCastSpeed()
        Icons.drawWithText(castIcon, hero.baseCastSpeed .. "x (+" .. hero.castSpeedGrowth .. ")", statsX, castSpeedY, ICON_STAT_SIZE)
        
        -- Passive ability description with icon (description section)
        local innateY = castSpeedY + CARD_ELEMENTS_OFFSET_Y - 60
        local innateX = cardX + CARD_PADDING
        
        Colors.setColor(SMALL_CARD_BACKGROUND)
        love.graphics.rectangle("fill", innateX, innateY, CARD_WIDTH - CARD_PADDING * 2, CARD_DESCRIPTION_HEIGHT, CARD_BORDER_RADIUS, CARD_BORDER_RADIUS)
        
        -- Draw innate skill icon (properly centered in panel)
        local iconX = innateX + CARD_PADDING + CARD_INNATE_SPRITE_SIZE / 2
        local iconY = innateY + CARD_PADDING + CARD_INNATE_SPRITE_SIZE / 2
        local iconSize = CARD_INNATE_SPRITE_SIZE

        -- Используем SpriteManager.getQuad для innate skill
        local spriteInnateQuad = SpriteManager.getQuad(spriteSheet, 2, 1, 64, 64)
        love.graphics.setColor(1, 1, 1, 1)  -- White for sprites
        local scale = iconSize / 64
        love.graphics.draw(spriteSheet, spriteInnateQuad, iconX, iconY, 0, scale, scale, 32, 32)
        
        love.graphics.setFont(love.graphics.newFont(UIConstants.FONT_SMALL))
        Colors.setColor(UIConstants.COLOR_TEXT_PRIMARY)
        local descriptionX = iconX + CARD_PADDING + iconSize / 2
        local descriptionY = iconY - 10
        love.graphics.printf(hero.innateSkill.description, descriptionX, descriptionY, CARD_WIDTH - CARD_ELEMENTS_OFFSET_X - CARD_PADDING, "left")
    end
end

-- === INPUT ===

function HeroSelect:handleClick(x, y, heroes)
    local screenW = love.graphics.getWidth()
    
    -- Calculate grid positioning
    local totalWidth = (CARD_WIDTH * CARDS_PER_ROW) + (CARD_SPACING * (CARDS_PER_ROW - 1))
    local startX = (screenW - totalWidth) / 2
    
    for i, hero in ipairs(heroes) do
        local row = math.floor((i - 1) / CARDS_PER_ROW)
        local col = ((i - 1) % CARDS_PER_ROW)
        
        local cardX = startX + col * (CARD_WIDTH + CARD_SPACING)
        local cardY = CARDS_START_Y + row * (CARD_HEIGHT + CARD_SPACING)
        
        -- Check if click is within this card
        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT then
            return i  -- Return hero index
        end
    end
    
    return nil
end

return HeroSelect

