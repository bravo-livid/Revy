--!strict
--!native
--!optimize 2

local World = require(script.World)

local Types = require(script.Types)
type World = Types.World
type Map<K, V> = Types.Map<K, V>

local worlds: Map<string, World> = {}
local defaultWorld: World

local Lib = {}

function Lib.world(name: string, shouldBeDefault: boolean): World
    if not name then
        if defaultWorld then
            return defaultWorld
        else
            error("no default world found, pass a name to create one")
        end
    end

    local world = worlds[name]
    if world then
        return world
    end

    local newWorld = World.new()
    worlds[name] = newWorld
    if shouldBeDefault then
        defaultWorld = newWorld
    end
    return newWorld       
end

return Lib