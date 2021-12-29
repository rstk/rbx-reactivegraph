local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactiveGraph = require(ReplicatedStorage.Packages.ReactiveGraph)

local State = ReactiveGraph.State
local Effect = ReactiveGraph.Effect

local function WaitForGarbageCollection()
	for _ = 1, 128 do
		table.create(128)
	end

	local t = setmetatable({newproxy(false)}, {__mode = "kv"})

	repeat
		task.wait()
	until t[1] == nil
end

return function()
	it("should :get() the right value with no dependency", function()
		expect(Effect(function()
			return 1
		end):get()).to.be.equal(1)

		expect(Effect(function()
			return ReactiveGraph
		end):get()).to.be.equal(ReactiveGraph)
	end)

	it("should :get() the right value with one dependency", function()
		local message = State("Hello")
		local bang = Effect(function()
			return string.format("%s!", message:get())
		end)

		expect(bang:get()).to.be.equal("Hello!")

		message:set("Hi")
		expect(bang:get()).to.be.equal("Hi!")
	end)

	it("should :get() the right value with two dependencies", function()
		local number = State(2)
		local otherNumber = State(4)

		local tripledSum = Effect(function()
			return 3 * (number:get() + otherNumber:get())
		end)

		expect(tripledSum:get()).to.be.equal(18)

		number:set(5)
		otherNumber:set(5)
		expect(tripledSum:get()).to.be.equal(30)
	end)

	it("should :get() the right value with Effect dependencies", function()
		local number = State(5)

		local doubledNumber = Effect(function()
			return number:get() * 2
		end)

		local tripledNumber = Effect(function()
			return number:get() + doubledNumber:get()
		end)

		expect(tripledNumber:get()).to.be.equal(15)

		number:set(6)
		expect(tripledNumber:get()).to.be.equal(18)
	end)

	it("should handle errors properly", function()
		local shouldError = false
		local count = State(1)

		local doubledNumber = Effect(function()
			if shouldError then
				error("hi")
			end

			return 2 * count:get()
		end)

		expect(doubledNumber:get()).to.be.equal(2)

		shouldError = true
		count:set(2)
		expect(function()
			doubledNumber:get()
		end).to.throw()

		shouldError = false
		expect(doubledNumber:get()).to.be.equal(4)
	end)

	it("should lazily update", function()
		local state = State(0)
		local updates = 0

		local effect = Effect(function()
			updates += 1
			return state:get()
		end)

		-- The callback is called when creating the Effect.
		expect(updates).to.be.equal(1)

		effect:get()
		expect(updates).to.be.equal(1)

		state:set(1)
		effect:get()
		expect(updates).to.be.equal(2)
	end)

	it("should GC unused dependencies", function()
		local state = State(0)
		local updates = 0

		do
			Effect(function()
				updates += 1
				return state:get()
			end)
		end

		WaitForGarbageCollection()
		-- should have no dependent
		expect(next(state._dependents)).to.be.equal(nil)
		expect(updates).to.be.equal(1)
	end)

	it("should not GC used dependencies", function()
		local state = State(1)
		local effect
		local reference = setmetatable({}, {__mode = "kv"})

		do
			local doubleNumber = Effect(function()
				return 2 * state:get()
			end)

			effect = Effect(function()
				return doubleNumber:get() + 1
			end)

			reference[1] = doubleNumber
		end

		expect(effect:get()).to.be.equal(3)

		WaitForGarbageCollection()
		state:set(2)
		expect(effect:get()).to.be.equal(5)

		effect = nil
		WaitForGarbageCollection()
		expect(reference[1]).to.be.equal(nil)
	end)

	it("should behave normally when :get()'ing the same objects multiple times", function()
		local state = State(2)
		local effect = Effect(function()
			return state:get() + state:get() + state:get()
		end)

		expect(effect:get()).to.be.equal(6)

		state:set(3)
		expect(Effect(function()
			return effect:get() + effect:get()
		end):get()).to.be.equal(18)
	end)

	it("should error when effect callbacks have side effects", function()
		local state = State(0)
		expect(function()
			Effect(function()
				state:set(1)
				return 1
			end)
		end).to.throw()
	end)

	it("should handle complicated reactive graphs", function()
		local state1 = State(1)
		local state2 = State(0)

		local S1Plus1 = Effect(function()
			return state1:get() + 1
		end)

		local double_S1Plus1 = Effect(function()
			return S1Plus1:get() * 2
		end)

		local doubleS2PlusS1PlusS1Plus1 = Effect(function()
			return state2:get() * 2 + state1:get() + S1Plus1:get()
		end)

		local bothEffectsAddedPlusS2 = Effect(function() -- s2*3 + s1*4 + 3
			return double_S1Plus1:get() + doubleS2PlusS1PlusS1Plus1:get() + state2:get()
		end)

		expect(bothEffectsAddedPlusS2:get()).to.be.equal(7)
		state1:set(2)
		expect(bothEffectsAddedPlusS2:get()).to.be.equal(11)
		state2:set(-3)
		expect(bothEffectsAddedPlusS2:get()).to.be.equal(2)
		expect(double_S1Plus1:get()).to.be.equal(6)
		expect(doubleS2PlusS1PlusS1Plus1:get()).to.be.equal(-1)
	end)

	it("should dynamically change dependencies", function()
		local first = State("first")
		local second = State("second")
		local condition = State(true)
		local updates = 0

		local effect = Effect(function()
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
		expect(updates).to.be.equal(3)

		second:set("second!!")
		effect:get()
		expect(updates).to.be.equal(4)
	end)

	it("should error when creating new reactive objects inside Effect callbacks", function()
		expect(function()
			Effect(function()
				State()
			end)
		end).to.throw()

		expect(function()
			Effect(function()
				Effect(function()
					return 0
				end)
			end)
		end).to.throw()
	end)

	it("should merge table values", function()
		local state1 = State(1)
		local state2 = State(2)

		local effect = Effect(function()
			return {state1:get(), state2:get()}
		end)

		expect(effect:get()[1]).to.be.equal(1)
		expect(effect:get()[2]).to.be.equal(2)

		state1:set(nil)
		state2:set(3)
		expect(effect:get()[1]).to.be.equal(1)
		expect(effect:get()[2]).to.be.equal(3)
	end)

	it("should synchronously call event callbacks when dependencies are updated", function()
		local state1 = State(1)
		local state2 = State(2)

		local effect1 = Effect(function()
			return state1:get()
		end)

		local effect2 = Effect(function()
			return effect1:get() + state2:get()
		end)

		-- bad variable name because you never need to 'update Effects more than once'
		local updatesNeeded = 0
		table.insert(effect2._onUpdateNeeded, function()
			updatesNeeded += 1
		end)

		state1:set(0)
		state2:set(0)

		-- should only be notified once
		expect(updatesNeeded).to.be.equal(1)
	end)
end
