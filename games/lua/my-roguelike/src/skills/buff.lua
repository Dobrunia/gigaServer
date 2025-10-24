-- skills/buff.lua
-- Buff skill implementation
-- Public API: buff:cast(caster, skill), buff:update(dt, player)

local BuffSkill = {}
BuffSkill.__index = BuffSkill

function BuffSkill.new()
    local self = setmetatable({}, BuffSkill)
    return self
end

-- === CASTING ===

function BuffSkill:cast(caster, skill)
    if skill.buffEffect then
        -- Store original value if not already stored
        if skill.buffEffect.type == "damageMultiplier" then
            if not caster.originalDamageMultiplier then
                caster.originalDamageMultiplier = caster.damageMultiplier
            end
            caster.damageMultiplier = skill.buffEffect.multiplier
            
            -- Store buff info for duration tracking
            -- Remove existing buff of same type
            for i = #caster.activeBuffs, 1, -1 do
                if caster.activeBuffs[i].type == "damageMultiplier" then
                    table.remove(caster.activeBuffs, i)
                end
            end
            
            -- Add new buff
            table.insert(caster.activeBuffs, {
                type = "damageMultiplier",
                startTime = love.timer.getTime(),
                duration = skill.buffEffect.duration,
                multiplier = skill.buffEffect.multiplier,
                skill = skill  -- Store skill reference for icon
            })
        end
    end
end

-- === UPDATE ===

function BuffSkill:update(dt, player)
    if not player or not player.activeBuffs then
        return
    end
    
    local currentTime = love.timer.getTime()
    
    -- Update and remove expired buffs
    for i = #player.activeBuffs, 1, -1 do
        local buff = player.activeBuffs[i]
        
        -- Check if buff expired
        if currentTime >= buff.startTime + buff.duration then
            -- Restore original value
            if buff.type == "damageMultiplier" then
                player.damageMultiplier = player.originalDamageMultiplier
                player.originalDamageMultiplier = nil
            end
            
            table.remove(player.activeBuffs, i)
        end
    end
end

return BuffSkill
