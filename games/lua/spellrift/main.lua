local StateManager = require("src.states.state_manager")
local MainMenu    = require("src.states.main_menu")
local HeroSelect  = require("src.states.hero_select")
local SkillSelect = require("src.states.skill_select")
local Game = require("src.states.game")
local GameOver = require("src.states.game_over")

local stateManager -- локальная ссылка на инстанс

function love.load()
    stateManager = StateManager.new()

    stateManager:register("main_menu", MainMenu)
    stateManager:register("hero_select", HeroSelect)
    stateManager:register("skill_select", SkillSelect)
    stateManager:register("game", Game)
    stateManager:register("game_over", GameOver)

    stateManager:switch("main_menu")
end

function love.update(dt)
    stateManager:update(dt)
end

function love.draw()
    stateManager:draw()
end

function love.resize(w, h)
    if stateManager.currentState and stateManager.currentState.resize then
        stateManager.currentState:resize(w, h)
    end
end
