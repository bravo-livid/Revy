--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.DevPackages.TestEz)

local results = TestEZ.TestBootstrap:run({ ReplicatedStorage.Shared.Tests })
TestEZ.TestResults.visualize(results)