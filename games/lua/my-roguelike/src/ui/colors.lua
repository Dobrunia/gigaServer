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
Colors.TEXT_ACCENT = {0.9, 0.7, 0.3, 1}   -- Gold

-- === BACKGROUND COLORS ===
Colors.BACKGROUND_PRIMARY = {0.1, 0.15, 0.25, 1}   -- Dark blue-gray
Colors.BACKGROUND_SECONDARY = {0.15, 0.2, 0.3, 1}  -- Slightly lighter
Colors.BACKGROUND_ACCENT = {0.2, 0.25, 0.35, 1}    -- Light accent

-- === COMPONENTS ===
Colors.CARD_DEFAULT = Colors.BACKGROUND_SECONDARY
Colors.CARD_HOVER = Colors.BACKGROUND_ACCENT
Colors.CARD_SELECTED = {0.2, 0.4, 0.2, 0.9}  -- Green for selected

Colors.BORDER_DEFAULT = Colors.SECONDARY
Colors.BORDER_SELECTED = {0.3, 0.7, 0.3, 1}      -- Green border

Colors.ZONE_PASSIVE = {0.1, 0.1, 0.2, 0.8}      -- Dark zone for passive abilities

-- === УТИЛИТЫ ===

function Colors.setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

function Colors.getColor(color)
    return color[1], color[2], color[3], color[4] or 1
end

return Colors
