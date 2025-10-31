local Constants = {}

Constants.DEBUG_DRAW_HITBOXES = false        -- Toggle hitbox rendering
Constants.DEBUG_DRAW_DIRECTION_ARROW = false -- Toggle direction arrow rendering
Constants.DEBUG_DRAW_DAMAGE_NUMBERS = true   -- Toggle damage numbers display above enemies
Constants.DEBUG_DRAW_FPS = true              -- Toggle FPS display
Constants.DEBUG_DRAW_LEVELS = false           -- Toggle creature level display above creatures

-- === GAME TIMING ===
Constants.FIXED_DT = 1/60                   -- Fixed timestep for logic (60Hz)
Constants.MAX_FRAME_SKIP = 5                -- Max physics steps per frame

return Constants