--!strict
--!native
--!optimize 2

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Packets = require(game.ReplicatedStorage.Tests.Packets)

local testPacket1 = Packets.testPacket1
local testPacket2 = Packets.testPacket2

local cf = CFrame.new(41.5, 232.2, 13.2)
local cfArray = {}
for _ = 1, 1000 do
	table.insert(cfArray, cf)
end

local struct = {
	bye = "yoo hoo",
	hello = "hee haw",
	pos = Vector3.new(1, 2, 3),
	cool = true,
}

local color = Color3.new()

task.defer(function()
	while true do
		task.wait()
		for _ = 1, 255 do
			testPacket1:fireServer(cfArray)
			testPacket2:fireServer(struct, color)
		end
	end
end)
