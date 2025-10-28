local UISkillSelect = require("src.ui.ui_skill_select")
local Input = require("src.system.input")

local SkillSelect = {}
SkillSelect.__index = SkillSelect

function SkillSelect:enter(selectedHero)
    self.selectedHero = selectedHero
    self.ui = UISkillSelect.new()
    self.input = Input.new()
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

    -- ЛКМ → выбор карточки и переход в игру
    if self.input:isLeftMousePressed() then
        local mx, my = self.input:getMousePosition()
        local skillId = self.ui:handleClick(mx, my)
        if skillId and self.manager and self.manager.switch then
            self.manager:switch("game", self.selectedHero, skillId)
        end
    end
end

function SkillSelect:draw()
    self.ui:draw()
end

function SkillSelect:exit()
    self.ui = nil
    self.input = nil
end

return SkillSelect