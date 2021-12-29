local Root = script.Parent
local Fire = require(Root.Util.Fire)
local UpdateValue = require(Root.Util.UpdateValue)

type HasDependents = {
	_dependents: {},
}

type HasDependencies = {
	_dependencies: {},
	_dependenciesSwap: {},
}

type HasState<T> = {
	_callback: () -> T,
	_value: T,
	_needsUpdate: boolean,
	_onUpdateNeeded: {() -> ()},
}

local MockTracked = {_dependenciesSwap = {}}

local Dependencies = {CurrentlyTracked = nil}

function Dependencies.UseDependency(dependency: HasDependents)
	local currentlyTracked = Dependencies.CurrentlyTracked
	if currentlyTracked then
		currentlyTracked._dependenciesSwap[dependency] = true
	end
end

function Dependencies.NotifyDependents(dependency: HasDependents)
	for dependent in next, dependency._dependents do
		-- don't notify if already notified
		-- if this dependent needs an update, downstream dependents necessarily need to update
		-- so no need to notify them again
		if dependent._needsUpdate == false then
			dependent._needsUpdate = true
			Fire(dependent._onUpdateNeeded)
			Dependencies.NotifyDependents(dependent)
		end
	end
end

function Dependencies.TrackDependencies(effect: HasDependents & HasDependencies & HasState<any>)
	-- start tracking dependencies
	-- :set()'ing dependencies inside Effect callbacks is not allowed, so don't account for that.
	local lastTracked = Dependencies.CurrentlyTracked
	Dependencies.CurrentlyTracked = effect
	local ok, newValue = pcall(effect._callback)
	Dependencies.CurrentlyTracked = lastTracked

	if ok == false then
		-- throwing here is probably a bad idea, that will be changed when integrated into
		-- a proper UI library.
		error(string.format("Error in Effect callback: %s", tostring(newValue)), 3)
		return
	end

	local newDependencies = effect._dependenciesSwap
	local oldDependencies = effect._dependencies
	effect._dependenciesSwap = oldDependencies
	effect._dependencies = newDependencies

	-- make sure all dependencies have this effect set as dependent
	for dependency in next, newDependencies do
		oldDependencies[dependency] = nil
		dependency._dependents[effect] = true
	end

	-- this effect doesn't depend on old dependencies
	for dependency in next, oldDependencies do
		oldDependencies[dependency] = nil -- maybe use table.clear instead?
		dependency._dependents[effect] = nil
	end

	-- set the new value
	if effect._value ~= newValue then
		UpdateValue(effect, newValue)
	end

	effect._needsUpdate = false
end

function Dependencies.UpdateWithoutTracking(effect: HasState<any>)
	local lastTracked = Dependencies.CurrentlyTracked
	Dependencies.CurrentlyTracked = MockTracked
	local ok, newValue = pcall(effect._callback)
	Dependencies.CurrentlyTracked = lastTracked
	table.clear(MockTracked._dependenciesSwap)

	if ok == false then
		error(string.format("Error in StaticEffect callback: %s", newValue))
		return
	end

	if effect._value ~= newValue then
		UpdateValue(effect, newValue)
	end

	effect._needsUpdate = false
end

return Dependencies
