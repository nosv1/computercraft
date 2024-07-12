local DEBUG = true

-------------------------------------------------------------------------------

local moveDirections = {
    forward = turtle.forward,
    back = turtle.back,
    up = turtle.up,
    down = turtle.down,
}

local turnDirections = {
    left = turtle.turnLeft,
    right = turtle.turnRight,
}

local digDirections = {
    forward = turtle.dig,
    up = turtle.digUp,
    down = turtle.digDown,
}

local inspectDirections = {
    forward = turtle.inspect,
    up = turtle.inspectUp,
    down = turtle.inspectDown,
}

local function valueToKey(table, value)
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
    return "unknown"
end

-------------------------------------------------------------------------------

local Bot = {}
Bot.__index = Bot
function Bot:new(o)
    o = o or {
        home = vector.new(0, 0, 0),     -- TODO use gps location
        position = vector.new(0, 0, 0), -- TODO use gps location
    }
    setmetatable(o, self)

    return o
end

function Bot:tostring()
    return "Bot: " .. self.position:tostring()
end

function Bot:refuel(distance)
    -- select first inventory slot, assumes fuel is in slot 1
    turtle.select(1)

    -- ensure there are items in slot 1
    -- if not return false
    local itemCount = turtle.getItemCount()
    if itemCount == 0 then
        return false
    end

    if not turtle.refuel(itemCount - 1) then
        return false
    end

    return true
end

function Bot:tryRefuel(distance)
    -- if fuel level is less than distance, try to refuel
    local fuel = turtle.getFuelLevel()
    if fuel < distance then
        if DEBUG then
            -- FUEL::Need to refuel -- Fuel = 0 Distance = 3
            print("FUEL::Need to refuel -- Fuel = " .. fuel .. " Distance = " .. distance)
        end
        return self:refuel()
    end
    return false
end

function Bot:tryMove(direction, distance)
    if DEBUG then
        -- MOVE::Trying to move forward 3
        print("MOVE::Trying to move " .. valueToKey(moveDirections, direction) .. " " .. distance)
    end

    if not self:tryRefuel(distance) and turtle.getFuelLevel() < distance then
        return false
    end

    for _ = 1, distance do
        if not direction() then
            return false
        end
    end

    return true
end

function Bot:turn(direction, count)
    for _ = 1, count do
        direction()
    end
    return true
end

function Bot:tunnel(distance)
    -- a tunnel is a 1x1 that includes a 1x1 three blocks above the starting tunnel
    -- so it'll go some distance forward, turn around, go up three blocks, then come back

    --[[
    1x1
    x dig forward
    x move forward
    o inspect
    o inspect up
    o inspect down,
    x turn left
    o inspect
    x turn right
    o inspect
    x turn left
    5 inspections for 5 movements

    2x1
    x dig forward
    x move forward
    o inspect
    o inspect up
    o inspect down,
    x turn left
    o inspect
    x turn right
    o inspect
    x turn left -- now looking forward
    5 inspections for 5 movements

    x dig up
    x move up
    o inspect
    o inspect up
    x turn left
    o inspect
    x turn right
    o inspect
    x turn left -- now looking forward
    4 inspections for 5 movements

    ]]
end

function Bot:resume()
    while true
    do
        if not self:tryMove(moveDirections.forward, 3) then
            print("MOVE::Failed to move forward 3")
        end
        self:turn(turnDirections.right, 2)
    end
end

local function main()
    local bot = Bot:new()
    bot:resume()
end

main()
