# Sprite Integration Complete ✅

## Overview

Successfully integrated the real sprite assets (`tiles.png`, `rogues.png`, `monsters.png`) into the roguelike game, replacing the placeholder graphics system.

---

## Changes Made

### 1. **assets.lua** - Spritesheet System

**Added:**

- Spritesheet loading for `tiles.png`, `rogues.png`, and `monsters.png`
- Automatic quad generation for accessing individual sprites (32x32 tiles)
- New API functions:
  - `Assets.getSpritesheet(name)` - Get a spritesheet image
  - `Assets.getQuad(sheetName, index)` - Get a specific quad from a sheet
  - `Assets.getSprite(sheetName, index)` - Get both sheet and quad together

**Sprite Indices Mapped:**

- **Heroes** (from rogues.png):

  - Dwarf (1), Elf (2), Ranger (3), Rogue (4)
  - Knight (17), Fighter (18), Female Knight (19)
  - Monk (33), Priest (34)
  - Barbarian (49)
  - Wizard (66), Druid (67)

- **Monsters** (from monsters.png):
  - Orcs/Goblins: Orc (1), Orc Wizard (2), Goblin (3), Goblin Archer (6)
  - Giants: Ettin (17), Troll (19)
  - Slimes: Small Slime (33), Big Slime (34)
  - Undead: Skeleton (65), Skeleton Archer (66), Lich (67), Zombie (69), Ghoul (70)
  - Creatures: Centipede (97), Spider (105), Rat (108)
  - Dragons: Drake (130), Dragon (131)

---

### 2. **base_entity.lua** - Spritesheet Rendering Support

**Added:**

- New fields: `spritesheet`, `quad`, `spriteIndex`
- Updated `draw()` method to support both:
  - Spritesheet + quad rendering (new system)
  - Direct sprite rendering (backward compatible)
  - Circle fallback (for entities without sprites)

**Rendering Priority:**

1. Spritesheet + quad (if both exist)
2. Direct sprite image (legacy)
3. Circle (fallback)

---

### 3. **spawn_manager.lua** - Auto-Sprite Assignment

**Updated:**

- Now requires `Assets` module
- `trySpawnMob()`: Automatically assigns spritesheet, quad, and index to new mobs
- `spawnBoss()`: Automatically assigns boss sprites
- Sprites are set once at spawn, not every frame (performance win!)

---

### 4. **game.lua** - Player Sprite Setup

**Updated:**

- `startGame()`: Assigns player sprite from rogues.png based on `heroData.spriteIndex`
- Removed per-frame sprite assignment in draw loop (was lines 409-412)
- Mobs now draw directly without sprite reassignment

**Performance Impact:**

- Before: Sprites assigned every frame in draw loop
- After: Sprites assigned once at entity creation
- Result: Reduced draw loop overhead

---

### 5. **Config Files** - Sprite Indices

**heroes.lua:**

```lua
{
    id = "warrior",
    name = "Warrior",
    spriteIndex = 17,  -- Knight sprite
    -- ... other stats
}
```

**mobs.lua:**

```lua
{
    id = "zombie",
    name = "Zombie",
    type = "melee",
    spriteIndex = 69,  -- Zombie sprite
    -- ... other stats
}
```

**bosses.lua:**

```lua
{
    id = "zombie_lord",
    name = "Zombie Lord",
    type = "melee",
    spriteIndex = 67,  -- Lich sprite
    -- ... other stats
}
```

**All configs updated with:**

- Warrior → Knight (17)
- Mage → Wizard (66)
- Rogue → Rogue (4)
- Tank → Barbarian (49)
- Zombie → Zombie (69)
- Ghoul → Ghoul (70)
- Archer → Skeleton Archer (66)
- Dark Mage → Orc Wizard (2)
- Ogre → Orc (1)
- Boss sprites: Lich (67), Cultist (84), Ettin (17)

---

## How It Works

### Spritesheet Loading

```lua
-- In Assets.load()
local success, image = pcall(love.graphics.newImage, "assets/rogues.png")
Assets.spritesheets.rogues = image
Assets.quads.rogues = generateQuads(image)  -- Creates quads for all 32x32 tiles
```

### Entity Sprite Assignment

```lua
-- In spawn_manager.lua or game.lua
local spriteIndex = heroData.spriteIndex or Assets.images.player
entity.spritesheet = Assets.getSpritesheet("rogues")
entity.quad = Assets.getQuad("rogues", spriteIndex)
entity.spriteIndex = spriteIndex
```

### Rendering

```lua
-- In base_entity.lua draw()
if self.spritesheet and self.quad then
    love.graphics.draw(
        self.spritesheet,
        self.quad,
        self.x, self.y,
        self.rotation,
        self.scale, self.scale,
        16, 16  -- Origin at center of 32x32 sprite
    )
end
```

---

## Sprite Index Reference

### Calculating Sprite Index

For a 16-tiles-per-row spritesheet:

```
index = (row - 1) * 16 + col
```

Example: Row 5, Column 3 → `(5-1) * 16 + 3 = 67` (Lich)

### Adding New Sprites

1. Find sprite in `.txt` file (e.g., `monsters.txt`)
2. Calculate index using formula above
3. Add `spriteIndex = X` to config file
4. Sprite automatically renders!

---

## Testing

Run the game:

```bash
cd games/lua/my-roguelike
love .
```

**Expected behavior:**

- Heroes show actual character sprites from `rogues.png`
- Mobs show monster sprites from `monsters.png`
- Bosses show boss sprites
- No colored placeholder boxes (unless sprite loading fails)

**Fallback:**
If sprites fail to load, placeholders still work (backward compatible).

---

## Future Enhancements

1. **Map Tiles**: Use `tiles.png` for map rendering (currently uses solid color)
2. **Projectile Sprites**: Use small sprites from tile sheets instead of placeholders
3. **XP Drop Sprites**: Use chest/gem sprites from `tiles.png`
4. **Status Effect Icons**: Extract icon sprites from sheets
5. **Skill Icons**: Create skill icon spritesheet
6. **Animations**: Add frame-based animation support (e.g., walking cycles)

---

## Performance Notes

✅ **Improvements:**

- Sprites loaded once at startup (cached)
- Quads generated once (reused)
- Sprite assignment once per entity (not per frame)
- SpriteBatch-ready (can batch draw calls in future)

📊 **Memory:**

- 3 spritesheets loaded (~30KB total)
- Quads are lightweight (just coordinate data)
- No per-frame allocations

---

## Troubleshooting

**Sprites not showing?**

1. Check console for "Failed to load" errors
2. Verify `.png` files are in `assets/` directory
3. Check file names: `tiles.png`, `rogues.png`, `monsters.png` (lowercase)
4. Fallback placeholders should still work

**Wrong sprites?**

1. Check `spriteIndex` in config files
2. Use sprite reference tables above
3. Verify calculation: `(row-1) * 16 + col`

**Performance issues?**

1. Enable debug: `Constants.DEBUG_ENABLED = true`
2. Check FPS and entity count
3. Consider SpriteBatch for >100 entities

---

## Files Modified

- `src/assets.lua` - Spritesheet loading & quad generation
- `src/entity/base_entity.lua` - Spritesheet rendering support
- `src/spawn_manager.lua` - Auto-sprite assignment for mobs/bosses
- `src/game.lua` - Player sprite setup, draw loop optimization
- `src/config/heroes.lua` - Added spriteIndex to all heroes
- `src/config/mobs.lua` - Added spriteIndex to all mobs
- `src/config/bosses.lua` - Added spriteIndex to all bosses

---

## Credits

Sprites from the **32rogues** tileset.
Integration completed following project architecture guidelines from `TODO.md`.
