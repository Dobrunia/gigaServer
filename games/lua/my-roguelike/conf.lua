-- conf.lua
-- LÖVE configuration file
-- Sets window, rendering, and module settings before main.lua runs

function love.conf(t)
    t.identity = "doblike_roguelike"       -- Save directory name
    t.version = "11.4"                      -- LÖVE version
    t.console = true                        -- Console on Windows (debug)
    
    t.window.title = "Doblike Roguelike"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 720
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1                      -- V-sync on
    t.window.msaa = 0                       -- No anti-aliasing (pixel art style)
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    t.window.highdpi = false
    t.window.usedpiscale = true
    
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false               -- Not using Box2D
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end

