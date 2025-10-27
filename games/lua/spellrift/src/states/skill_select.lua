local SkillSelect = {}
SkillSelect.__index = SkillSelect

local UISkillSelect = require("src.ui.ui_skill_select")
local Input = require("src.system.input")

function SkillSelect:enter(selectedHero)
    -- Храним выбранного героя из предыдущего состояния
    self.selectedHero = selectedHero
    -- UI выбора стартового скилла
    self.ui = UISkillSelect.new()
    -- Ввод
    self.input = Input.new()
    -- Текущий выбор
    self.selectedSkill = nil
end

function SkillSelect:update(dt)
    self.input:update(dt)

    -- ESC → назад к выбору героя
    if self.input:isEscapePressed() then
        if self.manager and self.manager.switch then
            self.manager:switch("hero_select")
        end
        return
    end

    -- ЛКМ → выбор карточки
    if self.input:isLeftMousePressed() then
        local mx, my = self.input:getMousePosition()
        self:handleMouseClick(mx, my)
    end

    -- ENTER/SPACE → подтвердить выбор
    if (self.input.isEnterPressed  and self.input:isEnterPressed())
    or (self.input.isSpacePressed and self.input:isSpacePressed()) then
        self:confirmSelection()
    end
end

function SkillSelect:draw()
    self.ui:draw()
end

function SkillSelect:handleMouseClick(x, y)
    local idx = self.ui:handleClick(x, y)
    if idx then
        self.ui:selectByIndex(idx)
        self.selectedSkill = self.ui:getSelectedSkill()
        -- Если хочешь подтверждать только клавишей — убери следующую строку:
        self:confirmSelection()
    end
end

function SkillSelect:confirmSelection()
    if not self.selectedSkill then
        self.selectedSkill = self.ui:getSelectedSkill()
    end
    if self.selectedSkill and self.manager and self.manager.switch then
        -- Переход в игру, передаём выбранного героя и стартовый скилл
        -- Убедись, что game-стейт умеет принять :enter(hero, skill)
        self.manager:switch("game", self.selectedHero, self.selectedSkill)
    end
end

function SkillSelect:exit()
    self.ui = nil
    self.input = nil
    self.selectedSkill = nil
    -- self.selectedHero оставлять/обнулять — на твой выбор
end

return SkillSelect
