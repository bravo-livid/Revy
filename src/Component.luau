--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Types)
type World = Types.World
type Component<T> = Types.Component<T>

local Component = {}

function Component.new<T>(world: World, default: T): Component<T>
    
end

return Component