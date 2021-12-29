local None: None = newproxy(true)
getmetatable(None).__tostring = function()
	return "None"
end

export type None = typeof(None)
return None
