local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactiveGraph = require(ReplicatedStorage.Packages.ReactiveGraph)

local State = ReactiveGraph.State
local None = ReactiveGraph.None

return function()
	it("should remove table keys", function()
		local state = State({foo = 0})

		state:set({foo = None, bar = 1})
		expect(state:get().foo).to.be.equal(nil)
		expect(state:get().bar).to.be.equal(1)
	end)
end
