--!strict
--!native
--!optimize 2

-- Garbot.luau
-- Garbot is helper module to clean up objects

local Garbot = {}

-- Simple method that calls any immediatly childs destroy (for recursive clean the child must call collect() too)
function Garbot.collect(val: any)
	if typeof(val) ~= "table" then return end
	for k, v in val do
		if typeof(v) == "table" then 
			if v.destroy then
				v:destroy()
			end
		elseif typeof(v) == "Instance" then
			v:Destroy()
		elseif typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
		val[k] = nil
	end
	setmetatable(val, nil)
end

return Garbot