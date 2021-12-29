local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactiveGraph = require(ReplicatedStorage.Packages.ReactiveGraph)

local State = ReactiveGraph.State
local StaticEffect = ReactiveGraph.StaticEffect

return function()
	it("should :get() the correct values", function()
		local state1 = State(1)
		local state2 = State(0)

		local S1Plus1 = StaticEffect(function()
			return state1:get() + 1
		end)

		local double_S1Plus1 = StaticEffect(function()
			return S1Plus1:get() * 2
		end)

		local doubleS2PlusS1PlusS1Plus1 = StaticEffect(function()
			return state2:get() * 2 + state1:get() + S1Plus1:get()
		end)

		local bothStaticEffectsAddedPlusS2 = StaticEffect(function() -- s2*3 + s1*4 + 3
			return double_S1Plus1:get() + doubleS2PlusS1PlusS1Plus1:get() + state2:get()
		end)

		expect(bothStaticEffectsAddedPlusS2:get()).to.be.equal(7)
		state1:set(2)
		expect(bothStaticEffectsAddedPlusS2:get()).to.be.equal(11)
		state2:set(-3)
		expect(bothStaticEffectsAddedPlusS2:get()).to.be.equal(2)
		expect(double_S1Plus1:get()).to.be.equal(6)
		expect(doubleS2PlusS1PlusS1Plus1:get()).to.be.equal(-1)
	end)

	it("should *not* dynamically change dependencies", function()
		local first = State("first")
		local second = State("second")
		local condition = State(true)
		local updates = 0

		local effect = StaticEffect(function()
			updates += 1
			if condition:get() then
				return first:get()
			else
				return second:get()
			end
		end)

		first:set("first!")
		effect:get()
		expect(updates).to.be.equal(2)

		condition:set(false)
		effect:get()
		expect(updates).to.be.equal(3)

		first:set("first!!")
		effect:get()
		expect(updates).to.be.equal(4)

		second:set("second!!")
		effect:get()
		expect(updates).to.be.equal(4)
	end)
end
