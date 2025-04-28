local Signal = require(game.ReplicatedStorage.HyperShared.Signal)
local Scheduler = require(game.ReplicatedStorage.HyperShared.Scheduler)
local Signal: Signal.Signal<number, string, string> = Signal.new()
local before = gcinfo()

for i = 1, 1000000 do
	-- Scheduler.new(function()
	-- 	Signal:Connect(function(id, name, desc)
			
	-- 	end)
	-- end):after()
	Signal:Connect(function(id, name, desc)
			
	end)
end

local after = gcinfo()

print("Memory: ", after - before)

task.delay(15, function()
	print("A")
	Signal:Fire(1, "test_1", "should run")	
	Signal:Fire(2, "test_2", "should also run")
	task.wait(15)
	Signal:Destroy()
end)

Signal:Wait()
print(Signal._list.size)

return 0