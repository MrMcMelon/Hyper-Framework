--!strict

local Net = require(game.ReplicatedStorage.HyperShared.Net)
local types = Net.types

local t = {}

for i = 1, 244 do
	t[i] = Net.new()
end

return table.freeze{
	testPacket = Net.new(),
}