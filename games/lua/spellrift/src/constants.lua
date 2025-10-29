local Constants = {}

Constants.DEBUG_DRAW_HITBOXES = true        -- Toggle hitbox rendering
Constants.DEBUG_DRAW_DIRECTION_ARROW = true -- Toggle direction arrow rendering
Constants.DEBUG_DRAW_DAMAGE_NUMBERS = true   -- Toggle damage numbers display above enemies
Constants.DEBUG_DRAW_FPS = true              -- Toggle FPS display

-- === GAME TIMING ===
Constants.FIXED_DT = 1/60                   -- Fixed timestep for logic (60Hz)
Constants.MAX_FRAME_SKIP = 5                -- Max physics steps per frame

return Constants