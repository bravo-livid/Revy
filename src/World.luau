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
    return {
        entity = EntityBuilder.new,
        query = Query.new,
        component = Component.new,
        attach = Entity.attach,
        detach = Entity.detach,
        despawn = Entity.despawn,

        archetypes = {},
        archetypeMasks = {},
        entities = {},
        entityMasks = {},

        isComponentTable = {},
        isComponentInstance = {},
        componentDefaults = {},

        archetypeCount = 0,
    }
end

return World