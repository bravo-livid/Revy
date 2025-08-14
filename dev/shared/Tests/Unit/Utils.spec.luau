--!strict

return function()
    local Config = require(game.ReplicatedStorage.Revy.Config)
    local Utils = require(game.ReplicatedStorage.Revy.Utils)

    describe("addToMaskArray", function()
        local buf
        local mockValues = { 0, 32 }
        local defaultNonZeroMask = { [0] = 1, [1] = 1 }
        local allZeroMask = {}

        beforeEach(function()
            buf = buffer.create(Config.MASK_ARRAY_LENGTH * 4)
        end)

        -- Checks if any affected masks are equal to the expected value and rest of the masks are zero
        local function verifyDefaultMask(nonZeroMask: { [number]: number })
            for i = 0, Config.MASKS_PER_ARRAY - 1 do
                if nonZeroMask[i] then
                    expect(buffer.readu32(buf, i * 4)).to.equal(nonZeroMask[i])
                else
                    expect(buffer.readu32(buf, i * 4)).to.equal(0)
                end
            end
        end

        describe("Happy Path", function()
            -- The bits corresponding to the components should be flipped in the mask array
            it("correctly updates the mask array", function()
                Utils.addToMaskArray(buf, mockValues)
                verifyDefaultMask(defaultNonZeroMask)            
            end)

            -- Check if 2 bitwise operations are performed on the same mask for the mask array
            it("check 2 components in the same mask", function()
                local components = { 0, 1 }
                local expectedMask = { [0] = 3 } -- 0b11
                Utils.addToMaskArray(buf, components)
                verifyDefaultMask(expectedMask)
            end)

            -- Check if the mask array is updated correctly when a single component is added
            it("check single component in the mask array", function()
                local singleComponent = { 0 }
                local expectedMask = { [0] = 1 } -- 0b01
                Utils.addToMaskArray(buf, singleComponent)
                verifyDefaultMask(expectedMask)
            end)
        end)    

        describe("Edge Cases", function()
            -- Expect no change to the mask array
            it("check component out of bounds (upper bound)", function()
                local upperComponent = Config.MAX_COMPONENTS
                Utils.addToMaskArray(buf, { upperComponent })
                verifyDefaultMask(allZeroMask)            
            end)
            
            -- Expect no change to the mask array
            it("check component out of bounds (lower bound)", function()
                Utils.addToMaskArray(buf, { -1 })
                verifyDefaultMask(allZeroMask)            
            end)

            -- Expect no change to the mask array
            it("check empty values", function()
                Utils.addToMaskArray(buf, {})
                verifyDefaultMask(allZeroMask)
            end)

            -- Expect the second call to not change the mask array
            it("check adding the same component twice", function()
                Utils.addToMaskArray(buf, mockValues)
                Utils.addToMaskArray(buf, mockValues)
                verifyDefaultMask(defaultNonZeroMask)
            end)
            
            -- Expect the said component bit to be set to 1 ( doesn't matter if it is already set )
            it("check values containing duplicates", function()
                local duplicateValues = { 0, 0, 32, 32 }
                Utils.addToMaskArray(buf, duplicateValues)
                verifyDefaultMask(defaultNonZeroMask)
            end)
        end)
    end)

end
