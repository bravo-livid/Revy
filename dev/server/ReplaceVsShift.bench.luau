--!strict
--!native
--!optimize 2

--[[
    BenchmarkResult
    Running benchmark with 5000000 iterations...
    bit32.replace time: 0.07559350000519771 s
    bit32.bor + bit32.lshift time: 0.0757063999917591 s
]]--

local ITERATIONS = 5_000_000
local mask = 0

local function benchmark(name: string, func: () -> ())
    local start = os.clock()
    for i = 1, ITERATIONS do
        func()
    end
    local elapsed = os.clock() - start
    print(name, "time:", elapsed, "s")
end

local function useReplace()
    return bit32.replace(mask, 1, 0)
end

local function useBorLshift(): number
    return bit32.bor(mask, bit32.lshift(1, 0))
end

print("Running benchmark with", ITERATIONS, "iterations...")

benchmark("bit32.replace", useReplace)
benchmark("bit32.bor + bit32.lshift", useBorLshift)

return nil