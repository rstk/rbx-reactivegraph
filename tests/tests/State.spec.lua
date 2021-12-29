local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactiveGraph = require(ReplicatedStorage.Packages.ReactiveGraph)

local State = ReactiveGraph.State

return function()
	it("should :get() the correct native value", function()
		expect(State(1):get()).to.be.equal(1)
		expect(State(ReactiveGraph):get()).to.be.equal(ReactiveGraph)
	end)

	it("should :set() non-table values", function()
		local state1 = State(0)
		state1:set(1)
		expect(state1:get()).to.be.equal(1)

		local state2 = State("Hello")
		state2:set("hi!")
		expect(state2:get()).to.be.equal("hi!")
	end)

	it("should always use the same table", function()
		local ref = {}
		local state = State(ref)

		expect(state:get()).to.be.equal(ref)
		state:set({})
		expect(state:get()).to.be.equal(ref)
	end)

	it("should merge table values", function()
		local state = State({})

		state:set({foo = 1})
		expect(state:get().foo).to.be.equal(1)

		state:set({bar = 2})
		expect(state:get().bar).to.be.equal(2)

		state:set({foo = 3})
		expect(state:get().foo).to.be.equal(3)
		expect(state:get().bar).to.be.equal(2)
	end)

	it("should shallowly merge table values", function()
		local ref = {bar = 1}
		local state = State({ref = ref})

		state:set({foo = ""})
		expect(state:get().foo).to.be.equal("")
		expect(state:get().ref).to.be.equal(ref)

		state:set({ref = {}})
		expect(state:get().ref).never.to.be.equal(ref)
		expect(state:get().ref.bar).to.be.equal(nil)
	end)

	it("should synchronously call event callbacks when state updates", function()
		local hasUpdated = false
		local state = State(0)

		table.insert(state._onChange, function()
			hasUpdated = true
		end)

		state:set(1)
		expect(hasUpdated).to.be.equal(true)
	end)

	it("should not call event callbacks when state stays the same", function()
		local hasUpdated = false
		local state = State(0)

		table.insert(state._onChange, function()
			hasUpdated = true
		end)

		state:set(0)
		expect(hasUpdated).to.be.equal(false)
	end)
end
