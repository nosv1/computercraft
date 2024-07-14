local pretty = require "cc.pretty"
local r = require "cc.require"
local env = setmetatable({}, { __index = _ENV })
env.require, env.package = r.make(env, "/")
env.require("/Cloud/bin/api_extensions/turtle_extensions")
env.require("/Cloud/bin/api_extensions/utils")

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
        return self:refuel()
    end
    return false
end

function Bot:tryMove(moveDirection, distance)
    if not self:tryRefuel(distance) and turtle.getFuelLevel() < distance then
        return false
    end

    for _ = 1, distance do
        if not moveDirection() then
            return false
        end
    end

    return true
end

function Bot:turn(turnDirection, count)
    for _ = 1, count do
        turnDirection()
    end
    return true
end

function Bot:mineVein(direction)
    env.digDirections[direction]()
    env.moveDirections[direction]()
    self:inspectPosition()
    env.oppositeMoveDirections[direction]()
    return true
end

function Bot:inspectDirection(inspectDirection)
    local direction = env.valueToKey(env.inspectDirections, inspectDirection)
    local isBlock, block = inspectDirection()

    if not isBlock then
        return true -- returning true because success not because no block
    end

    -- block is a vein
    if env.isVein(block) then
        -- turtle will exit this function in the same position it entered
        self:mineVein(direction)
    end
end

function Bot:inspectPosition()
    -- inspect forward, up, down
    for _, direction in pairs(env.inspectDirections) do
        self:inspectDirection(direction)
    end

    -- inspect left
    self:turn(env.turnDirections.left, 1)
    self:inspectDirection(env.inspectDirections.forward)

    -- inspect right
    self:turn(env.turnDirections.right, 2)
    self:inspectDirection(env.inspectDirections.forward)

    -- reset direction
    self:turn(env.turnDirections.left, 1)

    return true
end

function Bot:tunnel(distance)
    -- a tunnel is a 1x1 that includes a 1x1 three blocks above the starting tunnel
    -- so it'll go some distance forward, turn around, go up three blocks, then come back

    for _ = 1, distance do
        self:inspectPosition()
        env.digDirections.forward()
        self:tryMove(env.moveDirections.forward, 1)
    end

    self:tryMove(env.moveDirections.back, distance)
end

function Bot:resume()
    self:tunnel(10)
end

local function main()
    local bot = Bot:new()
    bot:resume()
end

main()
