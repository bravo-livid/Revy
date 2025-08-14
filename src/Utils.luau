--!strict
--!native
--!optimize 2

local Config = require(script.Parent.Config)
local MASK_LENGTH = Config.MASK_LENGTH
local MAX_COMPONENTS = Config.MAX_COMPONENTS

local Utils = {}

--[[
    @param maskArray: buffer
    @param values: { number }
    Sets the bits in the values to 1 in the mask array.
]]
function Utils.addToMaskArray(maskArray: buffer, values: { number })
    for index = 1, #values do
        local value = values[index]

        if value < 0 or value >= MAX_COMPONENTS then
            continue -- Skip out of bounds values
        end
        
        local maskIndex = (value // MASK_LENGTH) * 4
        local bitIndex = value % MASK_LENGTH

        local mask = buffer.readu32(maskArray, maskIndex)
        local newMask = bit32.replace(mask, 1, bitIndex)

        if mask == newMask then
            continue -- No change to the mask
        end

        buffer.writeu32(maskArray, maskIndex, newMask)
    end
end


return Utils