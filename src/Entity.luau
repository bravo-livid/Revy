--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Types)
type World = Types.World
type Component<T> = Types.Component<T>

local Entity = {}

function Entity.attach<T>(world: World, entity: number, component: Component<T>, val: T?)
    
end

function Entity.detach<T>(world: World, entity: number, component: Component<T>)
    
end

function Entity.despawn(world: World, entity: number)
    
end

return Entity
