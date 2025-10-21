# Project Rules & Guidelines for AI Assistants

## Project Overview

**Performance-optimized roguelike** built with **LÖVE (Love2D) 11.4+** in **Lua**.

- **Architecture**: Data-driven, modular, ECS-inspired with OOP via Lua metatables
- **Performance**: Fixed timestep (60Hz), spatial hashing (O(1) queries), object pooling, Canvas rendering
- **Code Style**: Clean, commented, no magic numbers, local-first, single responsibility

---

## 🚨 CRITICAL RULES - READ BEFORE ANY CHANGES

### 1. NO GLOBAL VARIABLES

- Everything must be `local`
- Modules return tables: `local MyModule = {}; return MyModule`
- Use `require("src.module_name")` for dependencies

### 2. DATA-DRIVEN EVERYTHING

- New heroes/mobs/skills → ONLY edit `src/config/*.lua` files
- NO hardcoded stats in code
- Balance changes = config changes, not code changes

### 3. WHERE TO ADD NEW FEATURES

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

### 4. CODE STYLE REQUIREMENTS

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

### 5. ENTITY SYSTEM PATTERN

- **Base class**: `src/entity/base_entity.lua` (HP, status effects, collision)
- **Inheritance**: `setmetatable({}, {__index = BaseEntity})`
- **Required methods**: `new()`, `update(dt)`, `draw()`
- **Status effects**: Use `entity:addStatusEffect(type, duration, params)`

### 6. PERFORMANCE PATTERNS

- **Object pooling**: Use `src/pool.lua` for projectiles/particles
- **Spatial hash**: Use `src/spatial_hash.lua` for proximity queries (NEVER iterate all entities)
- **Canvas**: Static renders → draw once to Canvas, reuse
- **Culling**: Check `camera:isPointVisible()` before drawing

### 7. SPRITE SYSTEM DETAILS

- **Spritesheets**: Load via `Assets.load()`, use auto-generated quads
- **Index calculation**: Depends on image dimensions (auto-detected cols/rows)
  - `rogues.png`: 7 columns per row (49 quads total, 7×7 grid)
  - `monsters.png`: Auto-detected from image dimensions
  - `items.png`: Auto-detected from image dimensions
- **Formula**: For 7-col grid: `index = (row-1) × 7 + col`
- **Usage**: Set `spriteIndex` in config, sprites assigned at spawn

---

## PROJECT STRUCTURE

```
/my-roguelike/
├── main.lua              # Entry point - ONLY proxies LÖVE callbacks
├── conf.lua              # LÖVE configuration
└── src/                  # ALL game code
    ├── constants.lua     # ALL magic numbers
    ├── utils.lua         # Pure functions
    ├── assets.lua        # Asset loading with placeholders
    ├── input.lua         # Keyboard + gamepad abstraction
    ├── camera.lua        # 2D camera with culling
    ├── spatial_hash.lua  # Uniform grid for fast queries
    ├── pool.lua          # Generic object pooling
    ├── map.lua           # Map rendering (Canvas-based)
    ├── skills.lua        # Skill system, auto-casting
    ├── spawn_manager.lua # Mob/boss/XP spawning
    ├── game.lua          # Main game loop
    ├── entity/
    │   ├── base_entity.lua # Base class
    │   ├── player.lua      # Player with skills/XP
    │   ├── mob.lua         # Mobs with AI
    │   └── projectile.lua  # Pooled projectiles
    ├── ui/
    │   ├── menu.lua        # Menu/character select
    │   └── hud.lua         # In-game HUD
    └── config/
        ├── heroes.lua      # Hero definitions
        ├── mobs.lua        # Mob types
        ├── skills.lua      # Skill database
        └── bosses.lua      # Boss definitions
```

---

## MODULE DEPENDENCIES

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

---

## COMMON PITFALLS TO AVOID

- ❌ Don't create new global state in `game.lua`
- ❌ Don't bypass object pooling
- ❌ Don't iterate all entities - use `spatialHash:queryNearby()`
- ❌ Don't add magic numbers - add to `src/constants.lua`
- ❌ Don't modify config structure - add fields, don't change existing
- ❌ Don't create circular dependencies

---

## GAME MECHANICS

### Character System

- Heroes have base stats + growth per level
- Stats: HP, Armor, Move Speed, Cast Speed
- Innate abilities modify base mechanics
- Starting skill chosen before game start
- Skills gained on level up (3 random choices)

### Combat System

- Auto-cast skills on cooldown to nearest target
- Hold LMB to aim manually
- Hold RMB to move towards cursor
- Skills have: damage, cooldown, range, effects
- Status effects: slow, poison, root, stun

### Enemy System

- Mobs spawn in rings around player
- Melee mobs: chase → attack on contact
- Ranged mobs: maintain distance → shoot projectiles
- Mob level increases with game time (every minute)
- Bosses spawn every 10 minutes

### Progression System

- Kill mobs → drop XP orbs
- Collect XP → level up
- Level up → choose 1 of 3 skills
- Skills can stack (increase level) or add new

### Projectile System

- Pooled objects for performance
- Destroyed on: hit target, hit boundary, exceed range
- Simple physics: speed + direction vector
- Collision via spatial hash

---

## NAMING CONVENTIONS

- **Modules**: PascalCase (`Camera`, `SpatialHash`)
- **Functions**: camelCase (`updateStatusEffects`, `getEffectiveSpeed`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_PROJECTILES`, `SPAWN_INTERVAL`)
- **Local variables**: camelCase (`local playerHealth = 100`)
- **Private methods**: prefix with `_` (`function Module:_privateMethod()`)

---

## COMMENT STYLE

```lua
-- === SECTION HEADER ===  (for major sections)

-- Single line comment explaining WHY, not WHAT
local value = calculate()  -- Inline comment if needed

--[[
Multi-line comment for complex algorithms
Explain the approach, not the syntax
]]
```

---

## IMPLEMENTATION CHECKLIST

Before implementing any feature:

- [ ] Read relevant existing code first
- [ ] Identify correct file(s) to modify
- [ ] Check if similar code exists (copy pattern)
- [ ] Add constants to `src/constants.lua` first
- [ ] Use `local` everywhere
- [ ] Add comments explaining "why", not "what"
- [ ] Test in game (`love .`)
- [ ] Update documentation if adding new feature

---

## TESTING & DEBUGGING

```bash
# Run game
love .

# Check console for errors
# Enable debug: Constants.DEBUG_ENABLED = true
# Enable hitboxes: Constants.DEBUG_DRAW_HITBOXES = true
```

**Debug Tools:**

- FPS counter (top-left)
- Entity counts
- Spatial hash cell count
- Console logging via `Utils.log()` and `Utils.logError()`

---

## PERFORMANCE BEST PRACTICES

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

**Key Patterns:**

1. Canvas for map (draw once)
2. SpriteBatch for many same sprites
3. Object pooling for projectiles
4. Spatial hash for neighbor queries
5. Fixed timestep for logic
6. Culling for off-screen entities

---

## QUICK REFERENCE

### Adding a New Hero

1. Open `src/config/heroes.lua`
2. Copy existing hero table
3. Change `id`, `name`, stats, `spriteIndex`
4. Calculate sprite index: `(row-1) × 7 + col` for rogues.png
5. Save, test with `love .`

### Adding a New Status Effect

1. Add constant to `src/constants.lua`
2. In `src/entity/base_entity.lua`:
   - Add case in `updateStatusEffects()` for tick logic
   - Add case in `getEffectiveSpeed()` or `canAttack()` for effect
   - Add color in `drawStatusIcons()`
3. Use in skills: `effect = { type = "youreffect", duration = 3, params = {...} }`

### Adding a UI Screen

1. Create `src/ui/yourscreen.lua` (copy pattern from `menu.lua`)
2. In `src/game.lua`:
   - Add mode: `self.mode = "yourscreen"`
   - Add case in `update()`: `elseif self.mode == "yourscreen" then ...`
   - Add case in `draw()`: `elseif self.mode == "yourscreen" then ...`

---

## OPTIMIZATION PRIORITIES

**High Priority:**

- Canvas for static map
- Object pooling for projectiles/particles
- Spatial hash for collisions/targeting
- Fixed timestep for deterministic logic
- SpriteBatch for mass rendering
- Data-driven configs

**Medium Priority:**

- AI frequency throttling
- Camera culling
- Sound/particle pooling
- Atlas sprites + Quad

**Low Priority:**

- GC management
- Interpolation for smooth render
- Save system optimization

---

## WHEN IN DOUBT

1. Find similar existing code
2. Copy its structure
3. Adapt to your needs
4. Keep comments and style consistent
5. Test thoroughly

---

**Remember**: This is a performance-critical roguelike. Every allocation matters. Use pooling, avoid creating tables in loops, keep logic data-driven, and profile regularly.
