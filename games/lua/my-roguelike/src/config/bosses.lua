-- config/bosses.lua
-- Boss configurations (similar to mobs but stronger)
-- Bosses are just powerful mobs with special stats
-- Format: Same as mobs.lua, includes spritesheet and spriteIndex

local bosses = {}

-- === BASELINE BOSS (REFERENCE FOR BALANCE) ===
-- {
--     id = "baseline_boss",
--     name = "Baseline Boss",
--     type = "melee",
--     spriteIndex = 1,
--     
--     baseHp = 200,        -- 4x stronger than average mob
--     hpGrowth = 30,        -- Grows faster than mobs
--     baseArmor = 5,        -- Moderate armor
--     armorGrowth = 1.0,    -- Good armor scaling
--     baseMoveSpeed = 80,   -- Slightly slower than player
--     speedGrowth = 2,      -- Decent speed growth
--     baseDamage = 25,      -- 2.5x mob damage
--     damageGrowth = 5,     -- Strong damage scaling
--     
--     attackSpeed = 0.8,    -- Slower than mobs but hits harder
--     
--     xpDrop = 100,         -- 10x mob XP
--     xpDropGrowth = 20     -- High XP scaling
-- }

return bosses

