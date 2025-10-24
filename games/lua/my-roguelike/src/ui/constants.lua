-- ui/constants.lua
-- UI-specific constants
-- Public API: UIConstants table with UI parameters

local UIConstants = {}

-- === FONT SIZES ===
UIConstants.FONT_LARGE = 30    -- Large font for titles and headers
UIConstants.FONT_MEDIUM = 24   -- Medium font for main content
UIConstants.FONT_SMALL = 18    -- Small font for secondary info

-- === ICON SIZES ===
UIConstants.ICON_STAT_SIZE = UIConstants.FONT_MEDIUM -- Size for stat icons (HP, armor, speed, etc.)

-- === MENU ===
UIConstants.MENU_BUTTON_WIDTH = 220
UIConstants.MENU_BUTTON_HEIGHT = 60
UIConstants.BUTTON_BORDER_WIDTH = 2
UIConstants.BUTTON_BORDER_RADIUS = 8

-- === CARDS ===
UIConstants.CARDS_START_Y = 100
UIConstants.CARD_WIDTH = 500
UIConstants.CARD_HEIGHT = 390
UIConstants.CARD_BORDER_RADIUS = 8
UIConstants.CARD_SPACING = 40
UIConstants.CARD_PADDING = 20
UIConstants.CARD_ELEMENTS_OFFSET_Y = 100
UIConstants.CARD_ELEMENTS_OFFSET_X = 100
UIConstants.CARDS_PER_ROW = 1
-- CARDS SPRITES
UIConstants.CARD_MAIN_SPRITE_SIZE = 64
UIConstants.CARD_INNATE_SPRITE_SIZE = 40
-- CARD DESCRIPTION
UIConstants.CARD_DESCRIPTION_HEIGHT = UIConstants.CARD_INNATE_SPRITE_SIZE + UIConstants.CARD_PADDING * 2
UIConstants.CARD_DESCRIPTION_WIDTH = UIConstants.CARD_WIDTH - UIConstants.CARD_PADDING * 2

-- == HUD ==
UIConstants.HUD_HEIGHT = 200
UIConstants.HUD_PADDING = 20
UIConstants.HUD_ELEMENTS_OFFSET_Y = 20
-- SKILLS
UIConstants.SKILL_ICON_SIZE = 64
UIConstants.SKILL_SPACING = 10
UIConstants.SKILL_COOLDOWN_RADIUS_OFFSET = UIConstants.SKILL_ICON_SIZE - 5

-- === TIMER POSITION ===
UIConstants.START_Y = 20

-- === MINIMAP ===
UIConstants.MINIMAP_SIZE = 200                    -- Square minimap size
UIConstants.MINIMAP_PADDING = 10                 -- Distance from screen edge
UIConstants.MINIMAP_BORDER_WIDTH = 2             -- Border thickness
UIConstants.MINIMAP_PLAYER_SIZE = 4              -- Player dot size
UIConstants.MINIMAP_MOB_SIZE = 2                 -- Mob dot size
UIConstants.MINIMAP_PROJECTILE_SIZE = 1          -- Projectile dot size
UIConstants.MINIMAP_BACKGROUND_ALPHA = 0.7       -- Background transparency

return UIConstants
