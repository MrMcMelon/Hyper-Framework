--!strict
--!native
--!optimize 2

local packets = require(game.ReplicatedStorage.Tests.Packets)


packets.testPacket.onClientEvent:connect(function()
	-- print("Packet successfully processed")
end)

return 0