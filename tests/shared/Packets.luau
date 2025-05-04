--!strict

local Net = require(game.ReplicatedStorage.HyperShared.Net)
local types = Net.types

return table.freeze{
	testPacket1 = Net.new(types.array(types.cframe)),
	testPacket2 = Net.new(types.struct{
		hello = types.string,
		bye = types.string,
		cool = types.boolean,
		pos = types.vector3,
	}, types.color3)
}