-- colors.lua
-- Color palette for the game UI
-- Centralized color management with primary, secondary, and accent color system

local Colors = {}

-- === PRIMARY COLORS ===
Colors.PRIMARY = {0.2, 0.3, 0.5, 1}        -- Deep blue
Colors.SECONDARY = {0.4, 0.4, 0.5, 1}      -- Neutral gray  
Colors.ACCENT = {0.8, 0.6, 0.2, 1}         -- Golden yellow

-- === TEXT COLORS ===
Colors.TEXT_PRIMARY = {1, 1, 1, 1}         -- Pure white
Colors.TEXT_SECONDARY = {0.8, 0.8, 0.9, 1} -- Light gray
Colors.TEXT_ACCENT = {0.9, 0.7, 0.3, 1}    -- Gold
Colors.TEXT_DIM = {0.7, 0.7, 0.7, 1}       -- Dimmed text

-- === BACKGROUND COLORS ===
Colors.BACKGROUND_PRIMARY = {0.1, 0.15, 0.25, 1}   -- Dark blue-gray
Colors.BACKGROUND_SECONDARY = {0.15, 0.2, 0.3, 1}  -- Slightly lighter
Colors.BACKGROUND_ACCENT = {0.2, 0.25, 0.35, 1}    -- Light accent
Colors.BACKGROUND_DARK = {0, 0, 0, 0.7}            -- Dark overlay
Colors.BACKGROUND_DARKER = {0, 0, 0, 0.8}          -- Darker overlay

-- === BUTTON COLORS ===
Colors.BUTTON_DEFAULT = {0.2, 0.2, 0.3, 0.8}       -- Default button
Colors.BUTTON_HOVER = {0.3, 0.6, 0.3, 0.8}         -- Hover state (green)
Colors.BUTTON_BORDER = {0.5, 0.5, 0.6, 1}          -- Button border

-- === CARD COLORS ===
Colors.CARD_DEFAULT = Colors.BACKGROUND_SECONDARY
Colors.CARD_HOVER = Colors.BACKGROUND_ACCENT
Colors.CARD_SELECTED = {0.2, 0.4, 0.2, 0.9}        -- Green for selected

Colors.BORDER_DEFAULT = Colors.SECONDARY
Colors.BORDER_SELECTED = {0.3, 0.7, 0.3, 1}        -- Green border

Colors.ZONE_PASSIVE = {0.1, 0.1, 0.2, 0.8}         -- Dark zone for passive abilities

-- === HUD COLORS ===
Colors.HUD_BACKGROUND = {0, 0, 0, 0.7}             -- HUD background
Colors.HUD_CARD_BG = {0, 0, 0, 0.7}                -- Card background in HUD
Colors.HUD_CARD_BORDER = {0.3, 0.3, 0.4, 1}        -- Card border in HUD

-- === BAR COLORS ===
Colors.BAR_BACKGROUND = {0.2, 0.2, 0.2, 0.8}       -- Bar background
Colors.BAR_HP = {0.8, 0.2, 0.2, 1}                 -- HP bar (red)
Colors.BAR_XP = {0.3, 0.5, 1, 1}                   -- XP bar (blue)
Colors.BAR_COOLDOWN = {1, 0.5, 0, 1}               -- Cooldown bar (orange)
Colors.BAR_READY = {0.2, 1, 0.2, 0.8}              -- Ready indicator (green)

-- === OVERLAY COLORS ===
Colors.OVERLAY_COOLDOWN = {0, 0, 0, 0.6}           -- Cooldown overlay
Colors.OVERLAY_EMPTY = {0.5, 0.5, 0.5, 0.5}        -- Empty slot overlay
Colors.OVERLAY_PAUSE = {0, 0, 0, 0.7}              -- Pause screen overlay

-- === GAME OVER COLORS ===
Colors.GAME_OVER_BG = {0.1, 0.05, 0.05, 1}         -- Dark red background
Colors.GAME_OVER_TITLE = {1, 0.3, 0.3, 1}          -- Red title

-- === STATUS EFFECT COLORS ===
Colors.STATUS_SLOW = {0.4, 0.6, 1, 0.9}  -- Blue for slow
Colors.STATUS_POISON = {0.1, 0.9, 0.1, 0.9}  -- Green for poison
Colors.STATUS_ROOT = {0.6, 0.4, 0.2, 0.9}  -- Brown for root
Colors.STATUS_STUN = {1, 1, 0.2, 0.9}  -- Yellow for stun
Colors.STATUS_UNKNOWN = {0.5, 0.5, 0.5, 0.9}  -- Gray for unknown

-- === УТИЛИТЫ ===

function Colors.setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

function Colors.getColor(color)
    return color[1], color[2], color[3], color[4] or 1
end

return Colors
