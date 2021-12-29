local Dependencies = require(script.Parent.Parent.Dependencies)
local TrackDependencies = Dependencies.TrackDependencies
local UseDependency = Dependencies.UseDependency

local WEAK_KEYS = {__mode = "k"}

local Effect = {ClassName = "Effect"}
Effect.__index = Effect

function Effect:__tostring()
	return string.format("Effect<%s>(%s)", type(self._value), tostring(self._value))
end

function Effect.new<T>(callback: () -> T)
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
	}, Effect)

	TrackDependencies(self)
	return self
end

function Effect:get(): any
	if self._needsUpdate then
		TrackDependencies(self)
	end

	UseDependency(self)
	return self._value
end

export type Effect<T> = typeof(Effect.new(function()
	return nil :: T
end))
return Effect
