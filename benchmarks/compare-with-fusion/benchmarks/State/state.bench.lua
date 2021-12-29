--[[
	Simple State operations. Shouldn't show major or relevant differences.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local ReactiveGraph = require(ReplicatedStorage.DevPackages.ReactiveGraph)

local FusionState = Fusion.State
local ReactiveGraphState = ReactiveGraph.State

return {
	ParameterGenerator = function()
		return math.random()
	end;

	Functions = {
		Fusion = function(Profiler: BenchmarkerProfiler, value: number)
			Profiler.Begin("Create")
			local state = FusionState(value)
			Profiler.End()

			Profiler.Begin("Set")
			state:set(value + 1)
			Profiler.End()

			Profiler.Begin("Get")
			state:get()
			Profiler.End()
		end;

		ReactiveGraph = function(Profiler: BenchmarkerProfiler, value: number)
			Profiler.Begin("Create")
			local state = ReactiveGraphState(value)
			Profiler.End()

			Profiler.Begin("Set")
			state:set(value + 1)
			Profiler.End()

			Profiler.Begin("Get")
			state:get()
			Profiler.End()
		end;
	};
}
