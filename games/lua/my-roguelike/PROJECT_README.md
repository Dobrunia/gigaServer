# Doblike Roguelike

A performance-optimized roguelike game built with LÖVE (Love2D) framework in Lua.

## Features

- **Data-driven design**: All game content (heroes, mobs, skills, bosses) defined in config files
- **Fixed timestep**: Deterministic game logic at 60Hz
- **Spatial hashing**: Efficient collision detection and neighbor queries
- **Object pooling**: Minimal garbage collection for projectiles and particles
- **Canvas rendering**: Map rendered once for optimal performance
- **Multiple heroes**: Choose from 4 unique characters with different playstyles
- **Auto-casting skills**: Automatically target nearest enemies or manual aim mode
- **Status effects**: Slow, poison, root, stun with tick-based system
- **Progressive difficulty**: Mobs level up over time
- **Boss fights**: Epic boss encounters every 10 minutes

## Requirements

- **LÖVE 11.4** or higher (Love2D framework)
- Compatible with macOS, Windows, Linux

## Installation

1. Install LÖVE from https://love2d.org/
2. Navigate to the project directory
3. Run the game:
   ```bash
   love .
   ```

## Controls

### Keyboard & Mouse

- **WASD** or **Arrow Keys**: Move
- **Left Mouse Button (hold)**: Manual aim mode - attack in mouse direction
- **Right Mouse Button (hold)**: Alternative movement control
- **ESC**: Pause/Resume game (or quit from menu)
- **Space/Enter**: Select in menus

### Gamepad (PS5/Xbox)

- **Left Stick**: Movement
- **Right Stick**: Manual aim direction
- **A/X Button**: Select in menus
- **Start**: Pause

## Game Modes

1. **Menu**: Start screen
2. **Character Select**: Choose your hero (4 options)
3. **Playing**: Main game loop

## Project Structure

```
/my-roguelike/
├── conf.lua                    # LÖVE configuration
├── main.lua                    # Entry point
│
└── src/
    ├── constants.lua           # All game constants
    ├── utils.lua               # Utility functions (math, geometry, etc.)
    ├── assets.lua              # Asset loading and caching
    ├── input.lua               # Input abstraction (keyboard + gamepad)
    ├── camera.lua              # 2D camera with smooth follow
    ├── spatial_hash.lua        # Spatial partitioning for fast queries
    ├── pool.lua                # Generic object pooling
    ├── map.lua                 # Map rendering and bounds
    ├── skills.lua              # Skill system and auto-casting
    ├── spawn_manager.lua       # Mob/boss/XP spawning
    ├── game.lua                # Main game state and loop
    │
    ├── entity/
    │   ├── base_entity.lua     # Base class for all entities
    │   ├── player.lua          # Player character
    │   ├── mob.lua             # Enemy mobs with AI
    │   └── projectile.lua      # Projectiles (pooled)
    │
    ├── ui/
    │   ├── menu.lua            # Menu UI
    │   └── hud.lua             # In-game HUD
    │
    └── config/
        ├── heroes.lua          # Hero definitions
        ├── mobs.lua            # Mob definitions
        ├── skills.lua          # Skill definitions
        └── bosses.lua          # Boss definitions
```

## Architecture Highlights

### Fixed Timestep

- Game logic runs at fixed 60Hz (1/60 second steps)
- Ensures deterministic behavior regardless of frame rate
- Rendering runs separately for smooth visuals

### Spatial Hashing

- Map divided into uniform grid cells
- O(1) neighbor queries for collision detection and targeting
- Dramatically improves performance with many entities

### Object Pooling

- Projectiles pre-allocated and reused
- Eliminates garbage collection spikes
- Maintains 500+ simultaneous projectiles without lag

### Data-Driven Content

- All stats, skills, mobs in separate config files
- Easy balancing without code changes
- Extensible for modding

### Component-Based Entities

- Base entity class with common functionality
- Inheritance for Player, Mob, Projectile
- Status effect system supports complex debuffs

## Adding Content

### New Hero

Edit `src/config/heroes.lua`:

```lua
{
    id = "your_hero",
    name = "Hero Name",
    baseHp = 100,
    hpGrowth = 15,
    -- ... other stats
    startingSkill = { --[[ skill data ]] }
}
```

### New Mob

Edit `src/config/mobs.lua`:

```lua
{
    id = "your_mob",
    name = "Mob Name",
    type = "melee" or "ranged",
    baseHp = 50,
    -- ... other stats
}
```

### New Skill

Edit `src/config/skills.lua`:

```lua
{
    id = "your_skill",
    name = "Skill Name",
    type = "projectile" | "aoe" | "buff",
    cooldown = 2.0,
    damage = 30,
    -- ... other properties
}
```

## Performance Tips

- **Canvas rendering**: Map drawn once, not per-frame
- **Culling**: Off-screen entities not rendered
- **Batched rendering**: Use SpriteBatch for many same sprites
- **Spatial hash**: Fast neighbor queries (O(1) instead of O(N))
- **Fixed update rates**: AI runs at 10Hz, spawn at 1Hz
- **Object pooling**: No allocation in hot paths

## Debug Mode

Set `Constants.DEBUG_ENABLED = true` in `src/constants.lua` to see:

- FPS counter
- Entity counts
- Spatial hash cell count
- Memory usage

Press **F3** (TODO: implement) to toggle hitbox visualization.

## Known Limitations / TODO

1. **Placeholder Graphics**: Currently using colored rectangles
   - Replace with actual sprite assets in `assets/` directory
   - Update `src/assets.lua` to load real images
2. **Skill Choice UI**: Level-up skill selection auto-picks first skill
   - Implement modal UI for 3-skill choice
3. **Sound**: No audio implemented yet
   - Add sound effects for attacks, level up, boss spawn
   - Background music
4. **Save System**: No persistence yet
   - Implement save/load using `love.filesystem`
5. **Game Over Screen**: Just stops when player dies
   - Add restart/menu options

## Credits

- **Framework**: LÖVE (Love2D)
- **Design Pattern**: Entity-Component inspired
- **Optimization Techniques**: Object pooling, spatial hashing, fixed timestep

## License

Personal project - see repository for license details.

---

## Quick Start Commands

```bash
# Run game
love .

# Run with console (Windows debug)
love . --console

# Package for distribution (create .love file)
zip -9 -r game.love .
```

Enjoy the game!
