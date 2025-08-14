--!strict
--!native
--!optimize 2

local EntityBuilder = require(script.Parent.EntityBuilder)
local Component = require(script.Parent.Component)
local Query = require(script.Parent.Query)
local Entity = require(script.Parent.Entity)

local Types = require(script.Parent.Types)
type World = Types.World

local World = {}

function World.new(): World
    return table.freeze{
        entity = EntityBuilder.new,
        query = Query.new,
        component = Component.new,
        attach = Entity.attach,
        detach = Entity.detach,
        despawn = Entity.despawn,

        archetypes = {},
        entities = {},
        entityMasks = {},

        isComponentTable = {},
        isComponentInstance = {},
        componentDefaults = {},
    }
end

return World