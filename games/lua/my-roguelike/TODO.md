# TODO - Next Steps

## Immediate Improvements (Priority: High)

1. **Replace Placeholder Graphics**

   - Create or obtain sprite assets for player, mobs, projectiles
   - Load real images in `assets.lua`
   - Consider using sprite sheets with `love.graphics.newQuad()`

2. **Skill Choice UI on Level Up**

   - Implement modal overlay showing 3 random skills
   - Pause game during selection
   - Keyboard/gamepad navigation for skill choice

3. **Game Over / Victory Screen**

   - Display when player dies
   - Show stats: time survived, mobs killed, level reached
   - Restart or return to menu options

4. **Fix Camera-to-World Mouse Coordinates**

   - Currently manual aim with mouse doesn't properly convert screen→world
   - Implement proper `camera:screenToWorld()` usage in input handling

5. **SpriteBatch Implementation**
   - Add SpriteBatch for mobs (all same type drawn in one call)
   - Add SpriteBatch for XP drops
   - Significant rendering performance gain

## Features (Priority: Medium)

6. **Sound System**

   - Hit sounds
   - Level up sound
   - Boss spawn music/sound
   - Background music tracks
   - Volume controls in settings

7. **Particle Effects**

   - Impact effects on hit
   - Skill cast particles
   - XP pickup sparkle
   - Death explosions

8. **Boss Mechanics**

   - Unique attack patterns per boss
   - Phase transitions at HP thresholds
   - Special abilities or AOE attacks

9. **More Status Effects**

   - Burn (like poison but different visual)
   - Confusion (random movement)
   - Vulnerability (take more damage)

10. **Skill Upgrades**
    - When selecting same skill again, enhance it
    - Increase damage, reduce cooldown, add effects
    - Visual indicator of skill level

## Polish (Priority: Low)

11. **Settings Menu**

    - Volume sliders
    - Resolution/fullscreen toggle
    - Keybinding customization
    - Gamepad sensitivity

12. **Minimap**

    - Small map in corner showing player, mobs, bosses
    - Helpful for navigation

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

- [ ] Projectiles sometimes don't collide properly at high speeds (implement continuous collision detection)
- [ ] Mobs can overlap each other (add mob-to-mob collision if desired)
- [ ] Status effect icons overlap when many applied (implement icon stacking UI)
- [ ] Game doesn't handle window resize during gameplay perfectly (test and fix camera/UI scaling)

---

**Note**: This TODO list is a living document. Prioritize based on current needs and user feedback.
