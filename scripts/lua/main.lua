function main()
    local x, y = 0, 0
    
    print("Controls: w/a/s/d for movement, 'q' to quit")
    print("Current coordinates: (" .. x .. ", " .. y .. ")")
    
    while true do
        io.write("Enter command: ")
        local input = io.read("*line")
        
        if input == "q" then
            print("Exiting program")
            break
        elseif input == "w" then
            y = y + 1
            print("Move up. Coordinates: (" .. x .. ", " .. y .. ")")
        elseif input == "s" then
            y = y - 1
            print("Move down. Coordinates: (" .. x .. ", " .. y .. ")")
        elseif input == "a" then
            x = x - 1
            print("Move left. Coordinates: (" .. x .. ", " .. y .. ")")
        elseif input == "d" then
            x = x + 1
            print("Move right. Coordinates: (" .. x .. ", " .. y .. ")")
        else
            print("Unknown command. Use w/a/s/d or 'q'")
        end
    end
end

main()