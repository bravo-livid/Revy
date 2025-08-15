# Revy

## What is Revy?
- Revy is an ECS framework inspired by the Rust game Engine Bevy.
- It allows for really scalable code while not compromising performance.
- Revy allows you to treat your code like legos by allowing to plug and unplug parts of code to test and create new things.

## Why Revy?
- Its blazingly fast
    - Revy's queries are really fast (4x faster than Jecs) because the iterator forces you to use numerical for loops to achieve peak performance
    - Highly optimized for native code gen (100% performance increase in most cases)
    - Memory efficient uses buffers to store each entities components in a bit mask array, allowing you to theortically have infinite number of components
    - Entities are sorted into archetypes and archetypes are matched to queries using blazingly fast bit math.

- Its very reliable
    - Made using test driven devlopment (uses TestEz)
    - Tested thorougly via units tests, intergration tests and production simulations.
    - All tests are included in the repo

- Its Feature Rich
    - Revy contains stuff like entity builders to quickly spawn entities with certain components.
    - Revy allows you to attach & detach components on the fly while also allowing you to manually specify possible attach/detach (s) ahead of runtime via entity builders.
    - Revy plugins (not to be confused with roblox plugins) allows you to treat your game like puzzle where any part of code can be removed and added at will and the game will still work fine (WIP)
    - Future plans to add a roblox plugin, test suite, custom profiler, etc.

- It has very minimal syntax 
    - It is a bit more verbose than industry standards like jecs but the verbosity is needed for the performance
  - 
    - More about the syntax can be found in the "How to use Jecs?" section.


## How to use Revy?

### Creating a world
```luau
local Revy = require(game.ReplicatedStorage:WaitForChild("Revy"))

-- Creates a world called MyWorld sets it to the default world
local world = Revy.world("MyWorld", true)

-- Returns the default world in any script
local world = Revy.world()

-- If a world with the given name is found returns the world or creates a new one and returns it
local world = Revy.world("MyWorld")
```

### Defining a component
```luau
-- Create a component in the give world with default value = 100
local health = world:component(100)
```

### Spawning an entity
```luau
-- Spawns an entity with health component and a damage component
-- The value provided in the add will override the component default
local entity = world:entity()
    :add(health)
    :add(damage, 20)
    :spawn()
```

### Creating a Query
```luau
-- This query should get all the entities that have a health and damage component
local query = world:query(health, damage)

-- The forAll method will apply the function to each archetype under the query
query:forAll(function(toEntity, count, healthDatas, damageDatas)
    for i = 1, count do
        -- convert the cache pos to entity id
        local entityId = toEntity[i]

        -- fetch the data from the cache
        local health = healthDatas[i]
        local damage = damageDatas[i]

        health = math.max(health - damage, 0)
        print("entityId took ", damage, " damage, health= ", health)

        -- Set the health back
        healthDatas[i] = health
    end
end)
```