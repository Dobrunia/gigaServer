local Icons = {}

local base_url = "assets/icons/"

-- === STAT ICONS ===
Icons.HP = "heart.png"
Icons.ARMOR = "shield.png"
Icons.SPEED = "shoe.png"
Icons.CAST_SPEED = "hourglass.png"
-- Icons.XP = "⭐"
-- Icons.LEVEL = "📈"

-- -- === SKILL STAT ICONS ===
-- Icons.DAMAGE = "⚔️"
-- Icons.COOLDOWN = "⏱️"
-- Icons.RANGE = "📏"

-- -- === SKILL TYPE ICONS ===
Icons.SKILL_MELEE = "melee.png"
-- Icons.SKILL_RANGED = "🏹"
-- Icons.SKILL_MAGIC = "✨"
-- Icons.SKILL_UTILITY = "🔧"



-- === UTILITY FUNCTIONS ===
function Icons.getHP()
    return love.graphics.newImage(base_url .. Icons.HP)
end
function Icons.getArmor()
    return love.graphics.newImage(base_url .. Icons.ARMOR)
end
function Icons.getSpeed()
    return love.graphics.newImage(base_url .. Icons.SPEED)
end
function Icons.getCastSpeed()
    return love.graphics.newImage(base_url .. Icons.CAST_SPEED)
end
function Icons.getSkillMelee()
    return love.graphics.newImage(base_url .. Icons.SKILL_MELEE)
end

-- === ICON DRAWING HELPERS ===
function Icons.drawWithText(icon, text, x, y, size)
    size = size or 16
    local iconW, iconH = icon:getDimensions()
    local scale = size / math.max(iconW, iconH)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(icon, x, y, 0, scale, scale, iconW/2, iconH/2)
    
    if text then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, x + size/2 + 4, y - 4)
    end
end

return Icons
