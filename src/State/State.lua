local Root = script.Parent.Parent
local Fire = require(Root.Util.Fire)
local UpdateValue = require(Root.Util.UpdateValue)
local Dependencies = require(Root.Dependencies)
local NotifyDependents = Dependencies.NotifyDependents
local UseDependency = Dependencies.UseDependency

local WEAK_KEYS = {__mode = "k"}

local State = {ClassName = "State"}
State.__index = State

function State:__tostring()
	return string.format("State<%s>(%s)", type(self._value), tostring(self._value))
end

function State.new<T>(initialValue: T): State<T>
	if Dependencies.CurrentlyTracked then
		error("Creating new reactive objects inside effect callbacks is not allowed.")
	end

	return setmetatable({
		_value = initialValue;
		_onChange = {};
		_dependents = setmetatable({}, WEAK_KEYS);
	}, State)
end

function State:get(): any
	UseDependency(self)
	return self._value
end

function State:set(newValue: any)
	if Dependencies.CurrentlyTracked then
		error("Effect callbacks cannot have side effects.")
	end

	if self._value ~= newValue then
		UpdateValue(self, newValue)
		Fire(self._onChange)
		NotifyDependents(self)
	end
end

function State:set_unsafe(newValue: any)
	UpdateValue(self, newValue)
	Fire(self._onChange)
	NotifyDependents(self)
end

export type State<T> = typeof(State.new(nil :: T))
return State
