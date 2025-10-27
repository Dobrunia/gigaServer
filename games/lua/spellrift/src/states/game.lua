local World = require("src.world.world")
local Input = require("src.system.input")
local Camera = require("src.system.camera")
local Minimap = require("src.ui.ui_minimap")
local Spawner = require("src.system.spawner")
local Map = require("src.world.map")

local Game = {}
Game.__index = Game

function Game:enter(selectedHero, selectedSkill)
  self.input = Input.new()
  self.world = World.new()
  self.camera = Camera.new()
  self.minimap = Minimap.new()
  self.spawner = Spawner.new()
  self.map = Map.new()

  self.world:setup(selectedHero, selectedSkill)
end

function Game:update(dt)
  self.input:update(dt)

  if self.input.isEscapePressed and self.input:isEscapePressed() then
      self.manager:switch("pause_menu")
      return
  end

  self.world:update(dt)
  self.camera:update(self.world.heroes[1].x, self.world.heroes[1].y)
  self.minimap:update(self.world.heroes[1], self.world.enemies, self.world.projectiles, self.camera)
  self.spawner:update(dt)
end

function Game:draw()
    self.camera:apply()
    
    -- Рисуем карту/фон
    self.map:draw()
    
    -- Рисуем мир
    self.world:draw()
    
    -- Рисуем мини-карту
    self.minimap:draw()
    
    self.camera:unapply()
end

return Game
