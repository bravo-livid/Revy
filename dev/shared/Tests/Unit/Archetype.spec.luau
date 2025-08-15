--!strict

return function()

    local Utils = require(game.ReplicatedStorage.Revy.Utils)
    local Config = require(game.ReplicatedStorage.Revy.Config)
    local Archetype = require(game.ReplicatedStorage.Revy.Archetype)
    local World = require(game.ReplicatedStorage.Revy.World)
    local Types = require(game.ReplicatedStorage.Revy.Types)

    type Archetype = Types.Archetype

    describe("new", function()
        local world
        local defaultComponents = {0, 32, 255}
        local maskArray
        local hash

        beforeEach(function()
            world = World.new()
            maskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
            Utils.addToMaskArray(maskArray, defaultComponents)
            hash = buffer.tostring(maskArray)
        end)

        local function verify(archetype: Archetype, expectedComponents: {number})
            local cache = archetype.cache
            local indexFromComponent = archetype.indexFromComponent
            local componentFromIndex = archetype.componentFromIndex

            -- Components will be added in ascending order because we scan maskArray from
            -- lowest to highest index, and bits from LSB to MSB.
            table.sort(expectedComponents)

            expect(#cache).to.equal(#expectedComponents)
            expect(archetype.entityCount).to.equal(0)
            expect(archetype.entityFromPosition).to.be.a("table")
            expect(archetype.positionFromEntity).to.be.a("table")

            for index = 1, #cache do
                expect(cache[index]).to.be.a("table")
                local component = expectedComponents[index]
                expect(indexFromComponent[component]).to.equal(index)
                expect(componentFromIndex[index]).to.equal(component)
            end
        end

        describe("Happy Path", function()
            it("should create an archetype with correct cache & mappings", function()
                local archetype = Archetype.new(world, maskArray, hash)
                verify(archetype, defaultComponents)
            end)

            it("should add archetype to world", function()
                local archetype = Archetype.new(world, maskArray, hash)
                expect(world.archetypes[hash]).to.equal(archetype)
            end)

            it("should create an archetype with every component", function()
                local fullMaskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
                local components = {}
                for i = 0, Config.MAX_COMPONENTS - 1 do
                    table.insert(components, i)
                end
                Utils.addToMaskArray(fullMaskArray, components)
                local archetype = Archetype.new(world, fullMaskArray, buffer.tostring(fullMaskArray))
                verify(archetype, components)
            end)
        end)

        -- We do not adress duplicate components here, because the maskArray should not allow duplicates (handled by Utils.addToMaskArray).
        -- Component out of range is also not handled here, as it should be handled by Utils.addToMaskArray.
        -- hash & array mismatches should be handled upstream, hash is only used to set the archetype in the world.
        describe("Edge Cases", function()
            -- expect an archetype with a empty cache to be created
            it("should create an archetype with no components", function()
                local emptyMaskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
                local archetype = Archetype.new(world, emptyMaskArray, buffer.tostring(emptyMaskArray))
                verify(archetype, {})
            end)
            
            -- expect the old archetype to be returned from the cache (should not create a new one)
           it("creating the same archetype twice", function()
                local archetype1 = Archetype.new(world, maskArray, hash)
                local archetype2 = Archetype.new(world, maskArray, hash)
                expect(archetype1).to.equal(archetype2)
                verify(archetype1, defaultComponents)
                verify(archetype2, defaultComponents)
           end)
        end)
    end)

    describe("addEntity", function()
        local world
        local defaultComponents = {0, 32, 255}
        local defaultValues: { any } = {"bye", "hello", "world"}
        local defaultTestValues: { [number]: any } = { [0] = "bye", [32] = "hello", [255] = "world" }
        local maskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
        Utils.addToMaskArray(maskArray, defaultComponents)
        local hash = buffer.tostring(maskArray)
        local archetype

        beforeEach(function()
            world = World.new()
            archetype = Archetype.new(world, maskArray, hash)
        end)

        -- Assigns a unique value to each entity's components based on the entity ID.
        local function modDefault(components: { number }, values: { string },  valueModifier: any)
            local mod = tostring(valueModifier)
            local modified = {}
            for i, v in values do
                modified[i] = v .. mod
            end
            local modifiedTestValues = {}
            for i, v in components do
                modifiedTestValues[v] = modified[i]
            end
            return modified, modifiedTestValues
        end

        local function verify(archetype: Archetype, entities: {number}, values: { [number]: { [number]: any } })
            expect(archetype.entityCount).to.equal(#entities)
            local cache = archetype.cache
            local componentFromIndex = archetype.componentFromIndex

            for position, entityId in archetype.entityFromPosition do
                expect(table.find(entities, entityId)).to.be.a("number")
                expect(archetype.positionFromEntity[entityId]).to.equal(position)
                local entityValues = values[entityId]
                for i = 1, #cache do
                    local component = componentFromIndex[i]
                    expect(cache[i][position]).to.equal(entityValues[component])
                end
            end

            -- Ensure the cache is tightly packed
            for i = 1, #cache do
                local cacheEntry = cache[i]
                local prev = 0
                for k, v in cacheEntry do
                    expect(k - 1).to.equal(prev)
                    prev = k
                end
                expect(#cacheEntry).to.equal(#entities)
            end
        end

        describe("Happy Path", function()
            it("add single entity", function()
                local e = 1
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)

            it("add multiple entities", function()
                local entities = {}
                local values = {}

                for i = 1, 200 do
                    local e = i
                    local vals, testValues = modDefault(defaultComponents, defaultValues, i)
                    Archetype.addEntity(archetype, e, defaultComponents, vals)
                    values[e] = testValues
                    table.insert(entities, e)
                end

                verify(archetype, entities, values)
            end)

            it("should correctly map entities inserted in random order", function()
                local entities = {5, 2, 9, 1}
                local values = {}
                for _, e in entities do
                    local vals, testValues = modDefault(defaultComponents, defaultValues, e)
                    Archetype.addEntity(archetype, e, defaultComponents, vals)
                    values[e] = testValues
                end
                verify(archetype, entities, values)
            end)
        end)

        describe("Edge Cases", function()
            -- expect the second call to abort early, as the entity is already in the archetype
            it("adding the same entity twice", function()
                local e = 1
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                expect(archetype.positionFromEntity[e]).to.equal(1)
                expect(archetype.entityFromPosition[1]).to.equal(e)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)

            -- should add nothing to the cache if the entity has no components
            -- we can keep the cache empty as the query system will iter with the entity count
            it("adding an entity with no components", function()
                local e = 1
                local archetype = Archetype.new(world, buffer.create(Config.MASK_ARRAY_LENGTH), "")
                Archetype.addEntity(archetype, e, {}, {})
                verify(archetype, { e }, { [e] = {} })
            end)

            -- expect an error if the give components don't match the archetype's components
            it("adding an entity with missing components", function()
                local e = 1
                expect(function()
                    Archetype.addEntity(archetype, e, {0, 32}, defaultValues)
                end).to.throw()
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)

            -- expect an error if the value for a component is missing
            it("adding an entity with missing values", function()
                local e = 1
                expect(function()
                    Archetype.addEntity(archetype, e, defaultComponents, {0, "hello"})
                end).to.throw()
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)

            -- expect an error if the give components array is longer than the archetype's components
            it("adding an entity with too many components", function()
                local e = 1
                expect(function()
                    Archetype.addEntity(archetype, e, {0, 32, 255, 256}, defaultValues)
                end).to.throw()
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)

            -- expect an error if the values array is longer than the components array
            it("adding an entity with too many values", function()
                local e = 1
                expect(function()
                    Archetype.addEntity(archetype, e, defaultComponents, {0, "hello", "world", "extra"})
                end).to.throw()
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
                verify(archetype, { e }, { [e] = defaultTestValues })
            end)          
        end)
    end)

    describe("removeEntity", function()
        local world
        local defaultComponents = {0, 32, 255}
        local defaultValues = {"bye", "hello", "world"}
        local maskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
        Utils.addToMaskArray(maskArray, defaultComponents)
        local hash = buffer.tostring(maskArray)
        local archetype
        local addedEntities = {1, 2, 3, 4, 5}
        local removedEntities = {1, 3, 5}

        beforeEach(function()
            world = World.new()
            archetype = Archetype.new(world, maskArray, hash)
            for _, e in addedEntities do
                Archetype.addEntity(archetype, e, defaultComponents, defaultValues)
            end
        end)

        local function verify(archetype: Archetype, addedEntities: {number}, removedEntities: {number})
            local excpetedEntities = {} 
            for _, v in addedEntities do
                if not table.find(removedEntities, v) then
                    table.insert(excpetedEntities, v)
                end
            end

            -- check that the entity count is correct
            expect(archetype.entityCount).to.equal(#excpetedEntities)

            local cache = archetype.cache
            local entityFromPosition = archetype.entityFromPosition
            local positionFromEntity = archetype.positionFromEntity

            -- check that the entityFromPosition and positionFromEntity are correct
            for position, entityId in entityFromPosition do
                expect(table.find(excpetedEntities, entityId)).to.be.a("number")
                expect(positionFromEntity[entityId]).to.equal(position)
            end

            -- check that the cache is tightly packed and size is correct
            for i = 1, #cache do
                local cacheEntry = cache[i]
                local prev = 0
                for k, v in cacheEntry do
                    expect(k - 1).to.equal(prev)
                    prev = k
                end
                expect(#cacheEntry).to.be.equal(#excpetedEntities)
            end

        end

        describe("Happy Path", function()  
            it("removes said entities", function()
                for _, e in removedEntities do
                    Archetype.removeEntity(archetype, e)
                end
                verify(archetype, addedEntities, removedEntities)
            end)

            it("removing the entity that was added last", function()
                local e1 = 5
                local e2 = 4
                Archetype.removeEntity(archetype, e1)
                Archetype.removeEntity(archetype, e2)
                verify(archetype, addedEntities, { e1, e2 })
            end)

            it("check swapping logic", function()
                local e1 = 1
                local e2 = 2
                local components = {11, 12}
                local values1 = {"E1Value1", "E1Value2"}
                local values2 = {"E2Value1", "E2Value2"}
                local maskArray = buffer.create(Config.MASK_ARRAY_LENGTH)
                Utils.addToMaskArray(maskArray, components)
                local hash = buffer.tostring(maskArray)

                local archetype = Archetype.new(world, maskArray, hash)
                Archetype.addEntity(archetype, e1, components, values1)
                Archetype.addEntity(archetype, e2, components, values2)

                Archetype.removeEntity(archetype, e1)

                local cache = archetype.cache

                expect(cache[1][1]).to.equal(values2[1])
                expect(cache[2][1]).to.equal(values2[2])
            end)

        end)

        describe("Edge Cases", function()
            -- expect the call to abort early, as the entity is not in the archetype
            it("removing an entity that does not exist", function()
                local e = 6
                expect(function()
                    Archetype.removeEntity(archetype, e)
                end).to.be.ok()
                verify(archetype, addedEntities, {})
            end)
         
            -- should be handled like removing the last added entity
            it("removing the last entity in the archetype", function()
                local archetype = Archetype.new(world, maskArray, "fakeHash") -- create a new archetype to avoid conflicts we use fake hash to bypass the caching mechanism
                Archetype.addEntity(archetype, 1, defaultComponents, defaultValues)
                Archetype.removeEntity(archetype, 1)

                -- verify that the archetype is empty
                for i, cacheEntry in archetype.cache do
                    expect(#cacheEntry).to.equal(0)
                end
                local c = 0
                for _, _ in archetype.entityFromPosition do
                    c += 1
                end
                expect(c).to.equal(0)
                c = 0
                for _, _ in archetype.positionFromEntity do
                    c += 1
                end
                expect(c).to.equal(0)
            end)
        end)
    end)

end
