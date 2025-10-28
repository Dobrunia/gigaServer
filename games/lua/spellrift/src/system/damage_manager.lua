local DamageNumber = require("src.system.damage_number")

local DamageManager = {}
DamageManager.__index = DamageManager

function DamageManager.new()
    local self = setmetatable({}, DamageManager)
    self.damageNumbers = {}
    return self
end

function DamageManager:addDamageNumber(x, y, damage, color)
    local damageNumber = DamageNumber.new(x, y, damage, color)
    table.insert(self.damageNumbers, damageNumber)
end

function DamageManager:update(dt)
    for i = #self.damageNumbers, 1, -1 do
        local damageNumber = self.damageNumbers[i]
        damageNumber:update(dt)
        
        if not damageNumber:isActive() then
            table.remove(self.damageNumbers, i)
        end
    end
end

function DamageManager:draw()
    for _, damageNumber in ipairs(self.damageNumbers) do
        damageNumber:draw()
    end
end

return DamageManager
