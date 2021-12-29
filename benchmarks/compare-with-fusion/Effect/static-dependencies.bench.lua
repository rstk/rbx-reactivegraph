--#selene: allow(unused_variable)
--[[
	kinda complex reactive graph, stress test.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local ReactiveGraph = require(ReplicatedStorage.Packages.ReactiveGraph)

local FusionState = Fusion.State
local ReactiveGraphState = ReactiveGraph.State

local Computed = Fusion.Computed
local StaticEffect = ReactiveGraph.StaticEffect

return {
	ParameterGenerator = function()
		return math.random(), math.random(), math.random()
	end;

	Functions = {
		Fusion = function(Profiler: BenchmarkerProfiler, value1: number, value2: number, value3: number)
			local state1 = FusionState(value1)
			local state2 = FusionState(value2)
			local state3 = FusionState(value3)

			local effect1 = Computed(function()
				return state1:get() + 1
			end)
			local effect2 = Computed(function()
				return effect1:get() + state2:get()
			end)
			local effect3 = Computed(function()
				return effect2:get() + effect1:get() + state3:get()
			end)

			for _ = 1, 128 do
				value1 += 1
				value2 += 1
				value3 += 1
				state1:set(value1)
				state2:set(value2)
				state3:set(value3)
				effect3:get()
			end
		end;

		ReactiveGraph = function(Profiler: BenchmarkerProfiler, value1: number, value2: number, value3: number)
			local state1 = ReactiveGraphState(value1)
			local state2 = ReactiveGraphState(value2)
			local state3 = ReactiveGraphState(value3)

			local effect1 = StaticEffect(function()
				return state1:get() + 1
			end)
			local effect2 = StaticEffect(function()
				return effect1:get() + state2:get() + 1
			end)
			local effect3 = StaticEffect(function()
				return effect2:get() + effect1:get() + state3:get() + 1
			end)

			for _ = 1, 128 do
				value1 += 1
				value2 += 1
				value3 += 1
				state1:set(value1)
				state2:set(value2)
				state3:set(value3)
				effect3:get()
			end
		end;
	};
}
