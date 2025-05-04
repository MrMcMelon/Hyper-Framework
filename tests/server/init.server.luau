-- require(game.ReplicatedStorage.HyperShared)
-- require(script.TaskBenchmark)

local Packets = require(game.ReplicatedStorage.Tests.Packets)

local counter = 0

Packets.testPacket1.onServerEvent:connect(function()
	counter += 1
end)

Packets.testPacket2.onServerEvent:connect(function()
	counter += 1
end)

task.defer(function()
	while true do
		task.wait(1)
		print("Packet recieved last second: ", counter)
		counter = 0
	end
end)
