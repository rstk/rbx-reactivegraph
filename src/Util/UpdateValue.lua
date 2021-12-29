local None = require(script.Parent.None)

type HasValue<T> = {
	_value: T,
}

return function<T>(reactiveObject: HasValue<T>, newValue: T)
	local oldValue = reactiveObject._value

	if type(oldValue) == "table" then
		-- shallow merge into value
		for key, value in next, newValue do
			oldValue[key] = if value == None then nil else value
		end
	else
		-- assumes the oldValue ~= newValue check has already been done
		reactiveObject._value = newValue
	end
end
