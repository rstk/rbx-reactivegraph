return function(events: {() -> ()})
	for _index, callback in ipairs(events) do
		callback()
	end
end
