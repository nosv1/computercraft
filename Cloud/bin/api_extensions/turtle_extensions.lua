local pretty = require("cc.pretty")
local r = require "cc.require"
local env = setmetatable({}, { __index = _ENV })
env.require, env.package = r.make(env, "/")
local utils = env.require("Cloud/bin/api_extensions/utils")

moveDirections = {
    forward = turtle.forward,
    back = turtle.back,
    up = turtle.up,
    down = turtle.down,
}

oppositeMoveDirections = {
    forward = moveDirections[env.valueToKey(moveDirections, moveDirections.back)],
    back = moveDirections[env.valueToKey(moveDirections, moveDirections.forward)],
    up = moveDirections[env.valueToKey(moveDirections, moveDirections.down)],
    down = moveDirections[env.valueToKey(moveDirections, moveDirections.up)],
}

turnDirections = {
    left = turtle.turnLeft,
    right = turtle.turnRight,
}
turnAngles = {
    left = -90,
    right = 90,
}

digDirections = {
    forward = turtle.dig,
    up = turtle.digUp,
    down = turtle.digDown,
}

inspectDirections = {
    forward = turtle.inspect,
    up = turtle.inspectUp,
    down = turtle.inspectDown,
}

directions = {
    forward = "forward",
    back = "back",
    up = "up",
    down = "down",
    left = "left",
    right = "right",
}

unitVectors = {
    forward = vector.new(0, 0, 1),
    back = vector.new(0, 0, -1),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
    left = vector.new(-1, 0, 0),
    right = vector.new(1, 0, 0),
}

sides = {
    front = "front",
    back = "back",
    top = "top",
    bottom = "bottom",
    left = "left",
    right = "right",
}

blockTypes = {
    ground = {
        "minecraft:andesite",
        "chisel:basalt/raw",
        "extcaves:brokenstone",
        "create:andesite_cobblestone",
        "minecraft:brown_mushroom",
        "minecraft:cobblestone",
        "minecraft:cobweb",
        "forbidden_arcanus:darkstone",
        "minecraft:diorite",
        "create:diorite_cobblestone",
        "create:dolomite_cobblestone",
        "minecraft:dirt",
        "create:dolomite",
        "create:gabbro",
        "create:gabbro_cobblestone",
        "darkerdepths:glowspire",
        "darkerdepths:glowspurs",
        "darkerdepths:glowshroom",
        "darkerdepths:glowshroom_block",
        "darkerdepths:glowshroom_stem",
        "minecraft:granite",
        "create:granite_cobblestone",
        "minecraft:grass",
        "minecraft:gravel",
        "darkerdepths:grimestone",
        "chisel:laboratory/checkertile",
        "chisel:laboratory/floortile",
        "chisel:laboratory/smalltile",
        "chisel:laboratory/wallpanel",
        "extcaves:lavastone",
        "darkerdepths:mossy_grimestone",
        "minecraft:oak_fence",
        "minecraft:oak_plank",
        "minecraft:polished_diorite",
        "extcaves:polished_lavastone",
        "minecraft:sand",
        "minecraft:sandstone",
        "minecraft:stone",
        "minecraft:stone_bricks",
        "biomesoplenty:toadstool",
        "chisel:tyrian/rust",
    },
    gravity = {
        "minecraft:gravel",
        "minecraft:sand",
    },
    avoid = {
        "computercraft:turtle_normal",
        "create:shaft",
        "forbidden_arcanus:stella_arcanum"
    },
    vein = {
        "buddycards:luminis_ore",
        "minecraft:obsidian",
    }
}

blockTypeKeys = {
    ground = "ground",
    gravity = "gravity",
    avoid = "avoid",
    vein = "vein",
}

function isBlockType(block, blockType)
    for _, blockType in pairs(blockTypes[blockType]) do
        if block.name == blockType then
            return true
        end
    end

    return false
end

function isVein(block)
    local isOre = block.tags["forge:ores"]
    local isVein = isBlockType(block, blockTypeKeys.vein)
    return isOre or isVein
end

function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

function dumpGround()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            if isBlockType(item, blockTypeKeys.ground) then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end
