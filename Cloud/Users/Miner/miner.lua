local pretty = require "cc.pretty"
local r = require "cc.require"
local env = setmetatable({}, { __index = _ENV })
env.require, env.package = r.make(env, "/")
env.require("/Cloud/bin/api_extensions/turtle_extensions")
env.require("/Cloud/bin/api_extensions/utils")

local t_args = { ... }

local Bot = {}
Bot.__index = Bot
function Bot:new(o)
    o = o or {
        home = vector.new(0, 0, 0),     -- TODO use gps location
        position = vector.new(0, 0, 0), -- TODO use gps location
        facing = vector.new(0, 0, 1),
        blocksAvoided = {},             -- { block_name = position }
        startTime = nil,                -- in real life seconds
        timeLeft = nil
    }
    setmetatable(o, self)

    return o
end

function Bot:toString()
    return "Bot: " .. self.position:tostring()
end

function Bot:toFile()
    local fileName = "/Cloud/Miner/bot.bot"
    local file = io.open(fileName, "w")
    if not file then
        return false
    end
    file:write(textutils.serialize(self, { allow_repetitions = true }))
    file:close()
    print("Bot saved to " .. fileName)
    return true
end

function Bot:updateTimeLeft(distanceRemaining)
    local now = os.epoch() / (1000 * 50) -- real life seconds
    local elapsed = now - self.startTime
    local speed = elapsed / self.position:length2D()
    self.timeLeft = distanceRemaining * speed
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

    local direction = env.valueToKey(env.moveDirections, moveDirection)
    for _ = 1, distance do
        if not moveDirection() then
            return false
        end
        if direction == env.directions.forward or direction == env.directions.back then
            self.position = self.position + self.facing
        elseif direction == env.directions.up or direction == env.directions.down then
            self.position = self.position + env.unitVectors[direction]
        end
    end

    return true
end

function Bot:turn(turnDirection, count)
    local direction = env.valueToKey(env.turnDirections, turnDirection)
    for _ = 1, count do
        turnDirection()
        self.facing = self.facing:rotate(env.turnAngles[direction])
    end
    return true
end

function Bot:avoid(direction)
    local function doSequence(doMoveBack, sequence)
        if doMoveBack then
            self:tryMove(env.moveDirections.back(), 1)
        end
        for _, _direction in ipairs(sequence) do
            self:tryDig(env.digDirections[_direction], 1)
        end
    end

    if direction == env.directions.up then
        doSequence(
            true, -- move back
            {
                env.directions.up,
                env.directions.up,
                env.directions.forward,
                env.directions.forward,
                env.directions.down,
                env.directions.down
            })
    elseif direction == env.directions.down then
        doSequence(
            true, -- move back
            {
                env.directions.down,
                env.directions.down,
                env.directions.forward,
                env.directions.forward,
                env.directions.up,
                env.directions.up
            })
    elseif direction == env.directions.forward then
        doSequence(
            false,
            {
                env.directions.up,
                env.directions.forward,
                env.directions.forward,
                env.directions.down,
            })
    end
end

function Bot:tryDig(digDirection, distance)
    local direction = env.valueToKey(env.digDirections, digDirection)
    for _ = 1, distance do
        local blockType = self:inspectDirection(env.inspectDirections[direction])
        if blockType == env.blockTypeKeys.avoid then
            self:avoid(direction)
        end
        digDirection()
        self:tryMove(env.moveDirections[direction], 1)
    end
end

function Bot:mineVein(direction)
    env.digDirections[direction]()
    self:tryMove(env.moveDirections[direction], 1)
    self:inspectPosition()
    self:tryMove(env.oppositeMoveDirections[direction], 1)
    return true
end

-- returns block type
function Bot:inspectDirection(inspectDirection)
    local direction = env.valueToKey(env.inspectDirections, inspectDirection)
    local isBlock, block = inspectDirection()

    if not isBlock then
        return nil
    end

    if env.isBlockType(block, env.blockTypeKeys.ground) then
        return env.blockTypeKeys.ground
    elseif env.isBlockType(block, env.blockTypeKeys.avoid) then
        self.blocksAvoided[block.name] = self.position -- where bot was when block was inspected
        return env.blockTypeKeys.avoid
    elseif env.isVein(block) then
        -- turtle will exit this function in the same position it entered
        self:mineVein(direction)
        return env.blockTypeKeys.vein
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

function Bot:tunnel(distance, height)
    self.startTime = os.epoch() / (1000 * 50)

    local i = 1
    while i <= distance do
        for _, direction in ipairs({ env.directions.up, env.directions.down }) do
            self:inspectPosition()
            self:tryDig(env.digDirections.forward, 1)
            i = i + 1

            for j = 1, height - 1 do
                self:inspectPosition()
                self:tryDig(env.digDirections[direction], 1)
            end

            if env.isInventoryFull() then
                return i
            end

            if i > distance then
                break
            end

            self:updateTimeLeft(distance - (i - 1))
        end
    end

    return distance
end

-- @tparm radius: circle radius
-- @tparam height: cylinder height
-- @tparam layer: layer to start at with 1 being the first block away from the middle
function Bot:cylinder(radius, height, startingLayer)
    -- self.position = vector.new(0, 0, startingLayer)
    local layer = startingLayer
    local count = 0
    while layer <= radius do
        if (self.position + self.facing):length2D() <= layer then
            if (self.position + self.facing):length2D() <= layer - 1 then
                self:tryMove(env.moveDirections.forward, 1)
            else
                self:tunnel(1, height)
            end
            self:tryMove(env.moveDirections.down, height)
            self:turn(env.turnDirections.right, 1)
        end

        if self.position:length2D() == layer and (self.position.x == 0 or self.position.z == 0) then
            count = count + 1
            if count == 4 then
                count = -1
                layer = layer + 1
                self:turn(env.turnDirections.left, 1)
            end
        end

        while true do
            if (self.position + self.facing):length2D() <= layer then
                break
            end
            self:turn(env.turnDirections.left, 1)
        end
    end
end

function Bot:resume()
    -- TODO resume from last position
end

local function main()
    local bot = Bot:new()
    -- bot:cylinder(5, 3, 4)
    -- _ = io.read()


    print("Checklist:")
    print("  facing forward?")
    print("  noteblock to the left or right?")
    print("  fuel in slot 1?")
    print("Press enter to continue...")
    _ = io.read()

    if #t_args < 1 then
        print("Usage: miner <distance> <height>")
        return
    end

    local distance = tonumber(t_args[1])
    local height = tonumber(t_args[2])
    local distance_tunneled = bot:tunnel(distance, height)

    print("Tunneled " .. distance_tunneled .. " blocks.")
    bot:turn(env.turnDirections.left, 2)
    bot:tryDig(env.digDirections.forward, distance_tunneled)

    bot:toFile()

    -- sound noteblock
    local power = true
    while true do
        for _, side in pairs(env.sides) do
            redstone.setOutput(side, power)
        end
        power = not power
        sleep(0.25)
    end

    -- bot:resume()
end

main()
