local UIGameOver = require("src.ui.ui_game_over")
local Input = require("src.system.input")

local GameOver = {}
GameOver.__index = GameOver

function GameOver:enter(gameStats, selectedHeroId, selectedSkillId)
    self.input = Input.new()
    self.input:snapshotNow()
    
    self.uiGameOver = UIGameOver.new()
    self.uiGameOver:setGameStats(gameStats)
    
    -- Сохраняем выбранные параметры для рестарта
    self.selectedHeroId = selectedHeroId
    self.selectedSkillId = selectedSkillId
    
    -- Статистика игры
    self.gameStats = gameStats or {
        level = 1,
        time = 0,
        enemiesKilled = 0,
        damageDealt = 0
    }
end

function GameOver:update(dt)
    -- Обновляем ввод
    self.input:update(dt)
    
    -- Обрабатываем нажатия кнопок
    local action = self.uiGameOver:update(dt, self.input)
    
    if action == "restart" then
        -- Возвращаемся к игре с теми же параметрами
        return {
            state = "game",
            selectedHeroId = self.selectedHeroId,
            selectedSkillId = self.selectedSkillId
        }
    elseif action == "menu" then
        -- Возвращаемся в главное меню
        return {
            state = "main_menu"
        }
    end
    
    return nil
end

function GameOver:draw()
    self.uiGameOver:draw()
end

function GameOver:resize(w, h)
    if self.uiGameOver and self.uiGameOver.resize then
        self.uiGameOver:resize(w, h)
    end
end

return GameOver
