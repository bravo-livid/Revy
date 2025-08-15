--!strict
--!native
--!optimize 2

local Config = require(script.Parent.Config)
local Types = require(script.Parent.Types)
local Logger = require(script.Parent.Logger)
local Utils = require(script.Parent.Utils)

type World = Types.World
type Archetype = Types.Archetype

local MASKS_PER_ARRAY_ZEROED = Config.MASKS_PER_ARRAY - 1
local MASK_LENGTH = Config.MASK_LENGTH
local MASK_LENGTH_ZEROED = MASK_LENGTH - 1
local MASK_LENGTH_BYTES = Config.MASK_LENGTH_BYTES

local Archetype = {}

--[[
    Creates a new Archetype and its to the world.
    @param world The world to which the archetype will be added.
    @param maskArray The bitmask array representing the components of this archetype.
    @param hash A unique identifier for this archetype, derived from the maskArray.
    @return A new Archetype instance with initialized properties.
]]--
function Archetype.new(world: World, maskArray: buffer, hash: string): Archetype
    local archetypes = world.archetypes

    local existingArchetype = archetypes[hash]
    if existingArchetype then
        return existingArchetype
    end

    local cache = {}
    local indexFromComponent = {}
    local componentFromIndex = {}
    
    local index = 1
    for maskIndex = 0, MASKS_PER_ARRAY_ZEROED do
        local mask = buffer.readu32(maskArray, maskIndex * MASK_LENGTH_BYTES)
        if mask == 0 then
            continue -- Skip empty masks
        end
        for bitIndex = 0, MASK_LENGTH_ZEROED do
            if bit32.extract(mask, bitIndex) == 0 then 
                continue
            end
            local component = maskIndex * MASK_LENGTH + bitIndex
            cache[index] = {}
            indexFromComponent[component] = index
            componentFromIndex[index] = component
            index += 1
        end
    end

    local archetype: Archetype = {
        cache = cache,
        indexFromComponent = indexFromComponent,
        componentFromIndex = componentFromIndex,
        entityFromPosition = {},
        positionFromEntity = {},
        entityCount = 0,
    }

    archetypes[hash] = archetype
    world.archetypeMasks[hash] = maskArray
    world.archetypeCount += 1
    
    return archetype
end

--[[
    Adds an entity to the archetype.
    @param archetype The archetype to which the entity will be added.
    @param entityId The unique identifier of the entity to be added.
]]--
function Archetype.addEntity(archetype: Archetype, entityId: number, components: { any }, values: { any })
    local positionFromEntity = archetype.positionFromEntity

    if positionFromEntity[entityId] then
        Logger.debug(Logger.warn, "AddEntity", `Entity {entityId} already exists in archetype, cannot add again.`)
        return
    end

    local cache = archetype.cache
    local componentCount = #cache

    if componentCount ~= #components then
        Logger.error("AddEntity", `Component count mismatch, expected: {componentCount}, got: {#components}, entityId: {entityId}`)
    end

    if componentCount ~= #values then
        Logger.error("AddEntity", `Value count mismatch, expected: {componentCount}, got: {#values}, entityId: {entityId}`)
    end

    local entityFromPosition = archetype.entityFromPosition
    
    local indexFromComponent = archetype.indexFromComponent

    local position = archetype.entityCount + 1

    for i = 1, componentCount do
        local component = components[i]
        local value = values[i]
        local index = indexFromComponent[component]
        if not index then
            Logger.error("AddEntity", `Component {component} not found in archetype, entityId: {entityId}`)
        end
        cache[index][position] = value
    end

    entityFromPosition[position] = entityId
    positionFromEntity[entityId] = position

    archetype.entityCount = position
end

--[[
    Removes an entity from the archetype.
    @param archetype The archetype from which the entity will be removed.
    @param entityId The unique identifier of the entity to be removed.
]]--
function Archetype.removeEntity(archetype: Archetype, entityId: number)
    local positionFromEntity = archetype.positionFromEntity

    local position = positionFromEntity[entityId]
    if not position then
        Logger.debug(Logger.warn, "RemoveEntity", "RemoveEntity", `Entity {entityId} not found in archetype, cannot remove.`)
        return
    end

    local cache = archetype.cache
    local lastPosition = archetype.entityCount
    local entityFromPosition = archetype.entityFromPosition
    local lastEntityId = entityFromPosition[lastPosition]

    if position ~= lastPosition then
        for i = 1, #cache do
            local cacheEntry = cache[i]
            
            local lastValue = cacheEntry[lastPosition]
            cacheEntry[position] = lastValue
            cacheEntry[lastPosition] = nil
        end
        entityFromPosition[position] = lastEntityId
        positionFromEntity[lastEntityId] = position
    else
        for i = 1, #cache do
            local cacheEntry = cache[i]
            cacheEntry[lastPosition] = nil
        end
    end

    positionFromEntity[entityId] = nil
    entityFromPosition[lastPosition] = nil

    archetype.entityCount = lastPosition - 1
end

return Archetype