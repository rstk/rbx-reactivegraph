local Dependencies = require(script.Parent.Parent.Dependencies)
local TrackDependencies = Dependencies.TrackDependencies
local UpdateWithoutTracking = Dependencies.UpdateWithoutTracking
local UseDependency = Dependencies.UseDependency

local WEAK_KEYS = {__mode = "k"}

local StaticEffect = {ClassName = "StaticEffect"}
StaticEffect.__index = StaticEffect

function StaticEffect:__tostring()
	return string.format("StaticEffect<%s>(%s)", type(self._value), tostring(self._value))
end

function StaticEffect.new<T>(callback: () -> T)
	if Dependencies.CurrentlyTracked then
		error("Creating new reactive objects inside effect callbacks is not allowed.")
	end

	local self = setmetatable({
		_value = nil;
		_callback = callback;
		_needsUpdate = true;
		_onUpdateNeeded = {};
		_dependents = setmetatable({}, WEAK_KEYS);
		_dependencies = setmetatable({}, WEAK_KEYS);
		_dependenciesSwap = setmetatable({}, WEAK_KEYS);
	}, StaticEffect)

	TrackDependencies(self)
	self._dependenciesSwap = nil
	return self
end

function StaticEffect:get(): any
	if self._needsUpdate then
		UpdateWithoutTracking(self)
	end

	UseDependency(self)
	return self._value
end

export type StaticEffect<T> = typeof(StaticEffect.new(function()
	return nil :: T
end))
return StaticEffect
