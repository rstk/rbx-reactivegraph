--#selene: allow(unused_variable)
--[[
	Stress testing but with normal Effect, not StaticEffect
	with branching
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local ReactiveGraph = require(ReplicatedStorage.DevPackages.ReactiveGraph)

local FusionState = Fusion.State
local ReactiveGraphState = ReactiveGraph.State

local Computed = Fusion.Computed
local Effect = ReactiveGraph.Effect

return {
	ParameterGenerator = function()
		return math.random(), math.random()
	end;

	Functions = {
		Fusion = function(Profiler: BenchmarkerProfiler, value1: number, value2: number)
			local state0 = FusionState(1)
			local state1 = FusionState(value1)
			local state2 = FusionState(value2)
			local condition = FusionState(true)

			local effect0 = Computed(function()
				return state0:get() * 2
			end)

			local effect1 = Computed(function()
				return state1:get() + effect0:get()
			end)
			local effect2 = Computed(function()
				return state2:get() + effect0:get()
			end)
			local effect3 = Computed(function()
				return if condition:get() then effect1:get() else effect2:get()
			end)

			for _ = 1, 128 do
				value1 += 1
				value2 += 1
				state0:set(state0:get() + 1)
				state1:set(value1)
				state2:set(value2)
				condition:set(not condition:get())
				effect3:get()
			end
		end;

		ReactiveGraph = function(Profiler: BenchmarkerProfiler, value1: number, value2: number)
			local state0 = ReactiveGraphState(1)
			local state1 = ReactiveGraphState(value1)
			local state2 = ReactiveGraphState(value2)
			local condition = ReactiveGraphState(true)

			local effect0 = Effect(function()
				return state0:get() * 2
			end)

			local effect1 = Effect(function()
				return state1:get() + effect0:get()
			end)
			local effect2 = Effect(function()
				return state2:get() + effect0:get()
			end)
			local effect3 = Effect(function()
				return if condition:get() then effect1:get() else effect2:get()
			end)

			for _ = 1, 128 do
				value1 += 1
				value2 += 1
				state0:set(state0:get() + 1)
				state1:set(value1)
				state2:set(value2)
				condition:set(not condition:get())
				effect3:get()
			end
		end;
	};
}
