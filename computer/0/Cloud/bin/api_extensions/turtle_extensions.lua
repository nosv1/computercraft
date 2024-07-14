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
    avoid = {
        "computercraft:turtle_normal",
        "create:shaft",
        "forbidden_arcanus:stella_arcanum"
    },
    veins = {
        "buddyblocks:luminis_ore",
        "minecraft:obsidian",
    }
}

blockTypeKeys = {
    ground = "ground",
    avoid = "avoid",
    veins = "veins",
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
    local isVein = isBlockType(block, blockTypeKeys.veins)
    return isOre or isVein
end
