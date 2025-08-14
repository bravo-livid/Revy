--!strict
--!native
--!optimize 2

--[[    
    ---------------RESULTS---------------
    Running benchmark with 50000000 iterations...
    bit32.replace time: 1.0398125000065193 s final mask: 4294967295
    bit32.bor + bit32.lshift time: 1.2886853999953019 s final mask: 4294967295
]]

local ITERATIONS = 50_000_000

-- we use different mask everytime to disable jit optimization for this benchmark
local function benchmark(name: string, func: (number, number) -> number)
    local mask = 0
    local start = os.clock()
    for i = 1, ITERATIONS do
        mask = func(mask, i % 32)
    end
    local elapsed = os.clock() - start
    print(name, "time:", elapsed, "s", "final mask:", mask)
end

local function useReplace(mask: number, bitIndex: number): number
    return bit32.replace(mask, 1, bitIndex)
end

local function useBorLshift(mask: number, bitIndex: number): number
    return bit32.bor(mask, bit32.lshift(1, bitIndex))
end

print("Running benchmark with", ITERATIONS, "iterations...")

benchmark("bit32.replace", useReplace)
benchmark("bit32.bor + bit32.lshift", useBorLshift)

return nil