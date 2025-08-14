--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Types)
type World = Types.World
type Query<A...> = Types.Query<A...>

local Query = {}

function Query.new<A...>(world: World, ...: A...): Query<A...>
    
end

function Query:forEach<A...>(func: (A...) -> ())
    
end

return Query