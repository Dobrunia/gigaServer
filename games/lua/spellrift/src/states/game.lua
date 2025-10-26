local Game = {}
function Game:enter()
end

function Game:update(dt)
    -- Обновляем ввод
    self.input:update(dt)
    
    -- 1. ПКМ - движение к курсору
    if self.input:isRightMouseDown() then
        local mouseX, mouseY = self.input:getMouseWorldPosition(self.world:getCamera())
        local dx, dy = self.input:getDirectionToMouse(self.player.x, self.player.y)
        
        -- Двигаем героя к курсору
        local speed = self.player.moveSpeed * dt
        self.player.x = self.player.x + dx * speed
        self.player.y = self.player.y + dy * speed
    end
    
    -- 2. ЛКМ - заглушка
    if self.input:isLeftMousePressed() then
        print("Left mouse clicked!")
    end
    
    -- 3. ESC - заглушка
    if self.input:isEscapePressed() then
        print("Escape pressed!")
    end
    
    -- Обновляем мир
    self.world:update(dt)
end

function Game:draw()
end

return Game
