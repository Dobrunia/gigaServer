# TODO - Next Steps

---

## 📋 PROJECT CONTEXT FOR AI ASSISTANTS

### Overview

This is a **performance-optimized roguelike** built with **LÖVE (Love2D) 11.4+** in **Lua**.

**Architecture**: Data-driven, modular, ECS-inspired with OOP via Lua metatables.  
**Performance**: Fixed timestep (60Hz), spatial hashing (O(1) queries), object pooling, Canvas rendering.  
**Code Style**: Clean, commented, no magic numbers, local-first, single responsibility.

### Project Structure

```
/my-roguelike/
├── main.lua              # Entry point - ONLY proxies LÖVE callbacks to src.game
├── conf.lua              # LÖVE window/module configuration
└── src/                  # ALL game code lives here
    ├── constants.lua     # ALL magic numbers go here (never hardcode values)
    ├── utils.lua         # Pure functions: math, geometry, XP calc, etc.
    ├── assets.lua        # Asset loading with placeholders
    ├── input.lua         # Keyboard + gamepad abstraction
    ├── camera.lua        # 2D camera with culling
    ├── spatial_hash.lua  # Uniform grid for fast spatial queries
    ├── pool.lua          # Generic object pooling
    ├── map.lua           # Map rendering (Canvas-based)
    ├── skills.lua        # Skill system, auto-casting, effects
    ├── spawn_manager.lua # Mob/boss/XP spawning logic
    ├── game.lua          # Main game loop with fixed timestep
    ├── entity/
    │   ├── base_entity.lua # Base class: HP, status effects, collision
    │   ├── player.lua      # Player: XP, skills, leveling
    │   ├── mob.lua         # Mobs: AI (chase/attack states)
    │   └── projectile.lua  # Pooled projectiles
    ├── ui/
    │   ├── menu.lua        # Menu/character select
    │   └── hud.lua         # In-game HUD
    └── config/
        ├── heroes.lua      # Hero definitions (data-driven)
        ├── mobs.lua        # Mob types
        ├── skills.lua      # Skill database
        └── bosses.lua      # Boss definitions
```

### 🚨 CRITICAL RULES - READ BEFORE IMPLEMENTING

#### 1. **NO GLOBAL VARIABLES**

- Everything must be `local`
- Modules return tables: `local MyModule = {}; return MyModule`
- Use `require("src.module_name")` for dependencies

#### 2. **Data-Driven Everything**

- New heroes/mobs/skills → ONLY edit `src/config/*.lua` files
- NO hardcoded stats in code
- Balance changes = config changes, not code changes

#### 3. **Where to Add New Features**

| Feature Type      | File to Edit                 | What to Do                                               |
| ----------------- | ---------------------------- | -------------------------------------------------------- |
| New hero          | `src/config/heroes.lua`      | Add table entry with stats                               |
| New mob type      | `src/config/mobs.lua`        | Add table entry (melee/ranged)                           |
| New skill         | `src/config/skills.lua`      | Add skill definition                                     |
| New status effect | `src/entity/base_entity.lua` | Add to `updateStatusEffects()` and `getEffectiveSpeed()` |
| UI element        | `src/ui/*.lua`               | Create new UI module or extend existing                  |
| Game constant     | `src/constants.lua`          | Add named constant, use it everywhere                    |
| Utility function  | `src/utils.lua`              | Add pure function (no side effects)                      |
| New entity type   | `src/entity/new_type.lua`    | Inherit from `base_entity.lua`                           |

#### 4. **Code Style Requirements**

```lua
-- ✅ GOOD: Clear, local, commented
local function calculateDamage(base, armor)
    -- Apply armor reduction formula
    local reduction = 1 - math.min(Constants.MAX_ARMOR_REDUCTION, armor * Constants.ARMOR_REDUCTION_FACTOR)
    return base * reduction
end

-- ❌ BAD: Global, magic numbers, no comments
function dmg(b, a)
    return b * (1 - math.min(0.75, a * 0.06))
end
```

#### 5. **Entity System Pattern**

- **Base class**: `src/entity/base_entity.lua` (HP, status effects, collision)
- **Inheritance**: `setmetatable({}, {__index = BaseEntity})`
- **Required methods**: `new()`, `update(dt)`, `draw()`
- **Status effects**: Use `entity:addStatusEffect(type, duration, params)`

#### 6. **Performance Patterns**

- **Object pooling**: Use `src/pool.lua` for projectiles/particles (avoid creating tables in loops)
- **Spatial hash**: Use `src/spatial_hash.lua` for proximity queries (NEVER iterate all entities)
- **Canvas**: Static renders → draw once to Canvas, reuse (see `src/map.lua`)
- **Culling**: Check `camera:isPointVisible()` before drawing

#### 7. **Module Dependencies**

```
game.lua → requires ALL systems
  ├─ constants.lua (required by: utils, all systems)
  ├─ utils.lua (required by: most modules)
  ├─ assets.lua → utils
  ├─ input.lua → constants
  ├─ camera.lua → constants, utils
  ├─ spatial_hash.lua → constants
  ├─ pool.lua (standalone)
  ├─ map.lua → constants
  ├─ skills.lua → constants, utils
  ├─ spawn_manager.lua → constants, utils, entity.mob
  ├─ entity/*.lua → constants, utils, base_entity
  └─ ui/*.lua → constants, utils, assets
```

#### 8. **Testing Your Changes**

```bash
# Run game
love .

# Check for errors in console
# Test with Constants.DEBUG_ENABLED = true in src/constants.lua
```

#### 9. **Common Pitfalls to Avoid**

- ❌ Don't create new global state in `game.lua` - use existing tables (mobs, projectiles, xpDrops)
- ❌ Don't bypass object pooling - use `projectilePool:acquire()` / `:release()`
- ❌ Don't iterate all entities - use `spatialHash:queryNearby()`
- ❌ Don't add magic numbers - add to `src/constants.lua`
- ❌ Don't modify config structure - add fields, don't change existing ones
- ❌ Don't create circular dependencies - follow dependency tree above

#### 10. **Implementation Checklist**

Before implementing any TODO:

- [ ] Read relevant existing code first
- [ ] Identify correct file(s) to modify from table above
- [ ] Check if similar code exists (copy pattern)
- [ ] Add constants to `src/constants.lua` first
- [ ] Use `local` everywhere
- [ ] Add comments explaining "why", not "what"
- [ ] Test in game (`love .`)
- [ ] Update `PROJECT_README.md` if adding new feature

---

## Immediate Improvements (Priority: High)

### 1. **Replace Placeholder Graphics**

**Files to edit**: `src/assets.lua`  
**Implementation**:

```lua
-- In Assets.load(), replace createPlaceholder() calls with:
Assets.images.player = love.graphics.newImage("assets/player.png")
Assets.images.mobMelee = love.graphics.newImage("assets/mob_melee.png")
-- etc.

-- For sprite sheets:
local sheet = love.graphics.newImage("assets/spritesheet.png")
Assets.quads.player = love.graphics.newQuad(0, 0, 32, 32, sheet:getDimensions())
```

**Don't**: Create new asset loading system, modify existing structure  
**Do**: Replace placeholder creation with `love.graphics.newImage()` calls

---

### 2. **Skill Choice UI on Level Up**

**Files to edit**:

- `src/ui/skill_choice.lua` (create new)
- `src/game.lua` (integrate UI)
- `src/constants.lua` (add UI constants)

**Implementation**:

```lua
-- 1. Create src/ui/skill_choice.lua (copy pattern from menu.lua)
local SkillChoice = {}
function SkillChoice:show(skillOptions) -- receives 3 skills
function SkillChoice:draw()
function SkillChoice:handleInput() -- returns selected skill or nil

-- 2. In src/game.lua, in fixedUpdate():
-- After player:gainXP(), check for level up
if self.player.needsSkillChoice then
    self.mode = "skill_choice"
    self.pendingSkillChoice = self:getRandomSkills(3)
end

-- 3. Add new update mode:
elseif self.mode == "skill_choice" then
    self:updateSkillChoice(dt)
```

**Constants to add**: `SKILL_CHOICE_CARD_WIDTH`, `SKILL_CHOICE_CARD_HEIGHT`  
**Don't**: Create complex menu system, modify player's skill array directly  
**Do**: Pause game, show 3 cards, on selection call `player:addSkill(selectedSkill)`

---

### 3. **Game Over / Victory Screen**

**Files to edit**:

- `src/ui/game_over.lua` (create new)
- `src/game.lua` (add game_over mode)
- `src/game.lua` (track stats: mobsKilled)

**Implementation**:

```lua
-- 1. In src/game.lua, add stats tracking:
self.stats = { mobsKilled = 0, bossesKilled = 0 }

-- 2. When mob dies in fixedUpdate():
self.stats.mobsKilled = self.stats.mobsKilled + 1

-- 3. Check player death:
if not self.player.alive then
    self.mode = "game_over"
    self.finalStats = { time = self.gameTime, level = self.player.level, kills = self.stats.mobsKilled }
end

-- 4. Create src/ui/game_over.lua:
function GameOver:draw(stats)
    -- Show stats, "Restart" and "Menu" buttons
```

**Don't**: Create new game loop, modify existing modes heavily  
**Do**: Add `game_over` mode alongside `menu`, `char_select`, `playing`

---

### 4. **Fix Camera-to-World Mouse Coordinates**

**Files to edit**: `src/game.lua` (handleInput method)

**Implementation**:

```lua
-- In src/game.lua, function Game:handleInput(dt):
-- Replace existing mouse aim code with:
if Input.mouse.left then
    local mouseX, mouseY = Input.getMousePosition()
    local worldX, worldY = self.camera:screenToWorld(mouseX, mouseY) -- FIX: Use camera conversion
    local aimX, aimY = Utils.directionTo(self.player.x, self.player.y, worldX, worldY)
    self.player:setAimDirection(aimX, aimY)
end
```

**Don't**: Modify camera.lua or input.lua  
**Do**: Use existing `camera:screenToWorld()` in game.lua input handling

---

### 5. **SpriteBatch Implementation**

**Files to edit**:

- `src/game.lua` (create SpriteBatches in load())
- `src/game.lua` (use in drawPlaying())
- `src/constants.lua` (add SPRITE_BATCH_SIZE if needed)

**Implementation**:

```lua
-- 1. In Game:load():
self.mobBatches = {
    melee = love.graphics.newSpriteBatch(Assets.getImage("mobMelee"), 1000),
    ranged = love.graphics.newSpriteBatch(Assets.getImage("mobRanged"), 1000)
}

-- 2. In Game:drawPlaying(), replace mob draw loop:
self.mobBatches.melee:clear()
self.mobBatches.ranged:clear()
for _, mob in ipairs(self.mobs) do
    if self.camera:isPointVisible(mob.x, mob.y) then
        local batch = mob.mobType == "melee" and self.mobBatches.melee or self.mobBatches.ranged
        batch:add(mob.x, mob.y, mob.rotation, 1, 1, 16, 16) -- adjust origin
    end
end
love.graphics.draw(self.mobBatches.melee)
love.graphics.draw(self.mobBatches.ranged)
```

**Don't**: Modify mob.lua draw method, create new rendering system  
**Do**: Use SpriteBatch in game.lua, clear/rebuild each frame

## Features (Priority: Medium)

### 6. **Sound System**

**Files to edit**:

- `src/assets.lua` (load sounds)
- `src/game.lua` (play sounds on events)
- `src/constants.lua` (add volume constants)

**Implementation**:

```lua
-- 1. In Assets.load():
Assets.sounds.hit = love.audio.newSource("assets/sounds/hit.ogg", "static")
Assets.sounds.levelup = love.audio.newSource("assets/sounds/levelup.ogg", "static")

-- 2. In game.lua events:
-- When mob takes damage: Assets.getSound("hit"):play()
-- When player levels up: Assets.getSound("levelup"):play()
```

**Don't**: Create audio manager, complex mixing  
**Do**: Load in assets.lua, play directly with `:play()`, set volume with `:setVolume()`

---

### 7. **Particle Effects**

**Files to edit**:

- `src/particle_effects.lua` (create new)
- `src/game.lua` (update/draw particles)
- `src/pool.lua` (reuse for particle pool)

**Implementation**:

```lua
-- 1. Create particle pool similar to projectile pool
self.particlePool = Pool.new(
    function() return love.graphics.newParticleSystem(texture, 100) end,
    function(ps) ps:reset() end, 50
)

-- 2. Emit on events:
-- When mob dies: spawn particle at mob.x, mob.y
-- Reuse ParticleSystem objects via pool
```

**Don't**: Create per-frame particles without pooling  
**Do**: Use `love.graphics.newParticleSystem`, pool them, emit on events

---

### 8. **Boss Mechanics**

**Files to edit**:

- `src/entity/mob.lua` (add boss-specific AI)
- `src/config/bosses.lua` (add special abilities in config)

**Implementation**:

```lua
-- 1. In src/entity/mob.lua, add to update():
if self.isBoss and self.specialAbility then
    self:updateBossAbility(dt)
end

-- 2. Add method:
function Mob:updateBossAbility(dt)
    if self.abilityTimer <= 0 then
        if self.specialAbility == "aoe_slam" then
            -- Spawn AOE attack
        end
        self.abilityTimer = self.abilityCooldown
    end
end

-- 3. In config/bosses.lua, add fields:
specialAbility = "aoe_slam",
abilityCooldown = 5.0
```

**Don't**: Create separate boss entity class  
**Do**: Use `isBoss` flag + config-driven abilities in mob.lua

### 9. **More Status Effects**

**Files to edit**:

- `src/entity/base_entity.lua` (add effect types)
- `src/constants.lua` (add effect constants)

**Implementation**:

```lua
-- In base_entity.lua, updateStatusEffects():
elseif effect.type == "burn" then
    -- Similar to poison but different tick rate/damage
    local tickRate = effect.params.tickRate or 0.3
    -- ... same pattern as poison

elseif effect.type == "confusion" then
    -- In mob.lua AI update, check hasStatusEffect("confusion")
    -- Randomize movement direction

elseif effect.type == "vulnerability" then
    -- In takeDamage(), check for vulnerability
    -- if self:hasStatusEffect("vulnerability") then
    --     actualDamage = actualDamage * 1.5
```

**Constants**: `BURN_TICK_RATE`, `VULNERABILITY_MULTIPLIER`  
**Don't**: Create new effect system  
**Do**: Follow existing poison/slow/root/stun pattern in base_entity.lua

---

### 10. **Skill Upgrades**

**Files to edit**:

- `src/entity/player.lua` (modify addSkill method)
- `src/config/skills.lua` (add upgrade data)

**Implementation**:

```lua
-- In player.lua, addSkill() already checks for duplicates:
for _, skill in ipairs(self.skills) do
    if skill.id == skillData.id then
        -- ALREADY IMPLEMENTED: skill.level = (skill.level or 1) + 1
        -- Add upgrade bonuses:
        skill.damage = skill.damage * 1.2
        skill.cooldown = skill.cooldown * 0.9
        return true
    end
end

-- In config/skills.lua, add upgrade scaling:
upgradeScaling = {
    damagePerLevel = 1.2,  -- +20% per level
    cooldownPerLevel = 0.9  -- -10% per level
}
```

**Don't**: Create complex skill tree system  
**Do**: Use existing level field in player.lua, apply multipliers

## Polish (Priority: Low)

11. **Settings Menu**

    - Volume sliders
    - Resolution/fullscreen toggle
    - Keybinding customization
    - Gamepad sensitivity

13. **Achievements / Unlocks**

    - Track kills, boss defeats
    - Unlock new heroes or skills

14. **Leaderboards**

    - Local high scores
    - Track best survival time per hero

15. **Map Variants**
    - Different map layouts or themes
    - Obstacles/walls (requires collision changes)

## Technical Improvements

16. **Profiling & Optimization**

    - Add profiler to identify bottlenecks
    - Optimize hot paths if needed

17. **Unit Tests**

    - Test utility functions (math, collision)
    - Test damage calculations
    - Test XP/leveling logic

18. **Save System**

    - Save progress, unlocks, settings
    - Use `love.filesystem` with JSON serialization

19. **Networking (Ambitious)**

    - Co-op mode with 2+ players
    - Synchronized game state
    - Low priority / future consideration

20. **Map Editor**
    - Tool to create custom maps
    - Place obstacles, spawn points
    - Export/import map data

---

## Bugs to Fix

### **Projectile Collision at High Speeds**

**Files**: `src/entity/projectile.lua`  
**Fix**: In `update()`, use swept AABB or check collision at `prevX, prevY` → `x, y` line segment

```lua
-- Check collision along movement path, not just endpoint
local steps = math.ceil(self.speed * dt / self.radius)
for i = 1, steps do
    -- Check collision at interpolated positions
end
```

### **Mobs Overlapping**

**Files**: `src/game.lua` (fixedUpdate), `src/entity/mob.lua`  
**Fix**: After mob movement, check `spatialHash:queryNearby()` for other mobs, apply separation force

```lua
-- In fixedUpdate, after mob update:
for _, mob in ipairs(self.mobs) do
    local nearby = self.spatialHash:queryNearby(mob.x, mob.y, mob.radius * 2)
    for _, other in ipairs(nearby) do
        if other ~= mob and other.mobId then
            -- Push mobs apart if overlapping
        end
    end
end
```

### **Status Effect Icon Stacking**

**Files**: `src/entity/base_entity.lua` (drawStatusIcons method)  
**Fix**: Stack identical effects, show count

```lua
-- Group effects by type, show count badge
local effectCounts = {}
for _, effect in ipairs(self.statusEffects) do
    effectCounts[effect.type] = (effectCounts[effect.type] or 0) + 1
end
-- Draw once per type with count overlay
```

### **Window Resize Issues**

**Files**: `src/game.lua` (resize callback), `src/ui/*.lua`  
**Fix**: Already calls `camera:resize()`. For UI, use relative positioning:

```lua
-- In UI drawing, use percentages:
local centerX = love.graphics.getWidth() / 2
-- Instead of hardcoded positions
```

---

## 🎯 Quick Reference for Common Tasks

### Adding a New Hero

1. Open `src/config/heroes.lua`
2. Copy existing hero table
3. Change `id`, `name`, stats
4. Save, test with `love .`

### Adding a New Status Effect

1. Add constant to `src/constants.lua`: `STATUS_YOUREFFECT = "youreffect"`
2. In `src/entity/base_entity.lua`:
   - Add case in `updateStatusEffects()` for tick logic
   - Add case in `getEffectiveSpeed()` or `canAttack()` for blocking logic
   - Add color in `drawStatusIcons()`
3. Use in skills: `effect = { type = "youreffect", duration = 3, params = {...} }`

### Adding a UI Screen

1. Create `src/ui/yourscreen.lua` (copy pattern from `menu.lua`)
2. In `src/game.lua`:
   - Add mode: `self.mode = "yourscreen"`
   - Add case in `update()`: `elseif self.mode == "yourscreen" then self:updateYourScreen(dt)`
   - Add case in `draw()`: `elseif self.mode == "yourscreen" then self:drawYourScreen()`

### Debugging

1. Set `Constants.DEBUG_ENABLED = true` in `src/constants.lua`
2. Use `Utils.log("message")` - appears in console and on-screen
3. Check `self.spatialHash:getCellCount()` if performance drops
4. Use `love.graphics.setColor(1,0,0,0.3)` to visualize hitboxes

---

**Note**: This TODO list is a living document. Always read existing code first, follow patterns, never create globals. Test with `love .` after every change.

---

## 💎 Code Style Enforcement

When implementing ANY feature, follow these patterns EXACTLY:

### Module Structure Template

```lua
-- module_name.lua
-- Brief description of what this module does
-- Public API: list of main functions/methods
-- Dependencies: list of required modules

local Constants = require("src.constants")
local Utils = require("src.utils")

local ModuleName = {}
ModuleName.__index = ModuleName

-- === CONSTRUCTOR ===
function ModuleName.new()
    local self = setmetatable({}, ModuleName)
    -- Initialize properties
    return self
end

-- === PUBLIC METHODS ===
function ModuleName:update(dt)
    -- Implementation
end

return ModuleName
```

### Naming Conventions

- **Modules**: PascalCase (`Camera`, `SpatialHash`)
- **Functions**: camelCase (`updateStatusEffects`, `getEffectiveSpeed`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_PROJECTILES`, `SPAWN_INTERVAL`)
- **Local variables**: camelCase (`local playerHealth = 100`)
- **Private methods**: prefix with `_` (`function ModuleName:_privateMethod()`)

### Comment Style

```lua
-- === SECTION HEADER ===  (for major sections)

-- Single line comment explaining WHY, not WHAT
local value = calculate()  -- Inline comment if needed

--[[
Multi-line comment for complex algorithms
Explain the approach, not the syntax
]]
```

### Error Handling

```lua
-- Check parameters
if not entity or not entity.alive then return end

-- Validate before operations
if #self.skills >= self.maxSkillSlots then
    Utils.logError("Cannot add skill: all slots full")
    return false
end
```

### Performance Best Practices

```lua
-- ✅ GOOD: Reuse, local, avoid allocation
local function update(dt)
    local dx = target.x - self.x
    local dy = target.y - self.y
    -- ...
end

-- ❌ BAD: Creating table every frame
local function update(dt)
    local pos = {x = self.x, y = self.y}  -- AVOID
end
```

### When in Doubt

1. Find similar existing code
2. Copy its structure
3. Adapt to your needs
4. Keep comments and style consistent
