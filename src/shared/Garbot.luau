--!strict
--!native
--!optimize 2

-- Garbot.luau
-- Garbot is helper module to clean up objects

export type Can = {
	add: (self: Can, object: {any}) -> (),
	destroy: (self: Can) -> (),
}

local Garbot = {}

local Can: Can = {}:: Can
Can["__index"] = Can

function Can:add(object)
	table.insert(self, object)
end

function Can:destroy()
	for i, object: any in self do
		if typeof(object) == "table" then 
			if typeof(object.destroy) == "function" then
				object:destroy()
			else
				Garbot.collect(object)
			end
		elseif typeof(object) == "RBXScriptConnection" then
			object:Disconnect()
		elseif typeof(object) == "Instance" then
			object:Destroy()
		end
		self[i] = nil
	end
	setmetatable(self, nil)
end

-- Simple method that calls any immediatly childs destroy
function Garbot.collect(val: any)
	if val.disconnect then
		val:disconnect()
	end
	if typeof(val) == "table" then 
		for k, v in val do
			if v == val then continue end
			if typeof(v) == "table" then 
				Garbot.collect(v)
			elseif typeof(v) == "Instance" then
				v:Destroy()
			elseif typeof(v) == "RBXScriptConnection" then
				v:Disconnect()
			end
			val[k] = nil
		end
		setmetatable(val, nil)
	elseif typeof(val) == "RBXScriptConnection" then
		val:Disconnect()
	elseif typeof(val) == "Instance" then
		val:Destroy()
	end
end

function Garbot.new(): Can
	return setmetatable({}, Can):: any
end

return Garbot