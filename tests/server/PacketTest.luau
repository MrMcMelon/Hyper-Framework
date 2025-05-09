--!strict
--!native
--!optimize 2

local packets = require(game.ReplicatedStorage.Tests.Packets)

local players: { Player } = {}

game:GetService("Players").PlayerAdded:Connect(function(plr)
	table.insert(players, plr)
end)

task.defer(function()
	while true do
		task.wait()
		packets.testPacket:fireGivenClients(players)
	end
end)

return 0