--!strict
--!native
--!optimize 2


local Task = require(game.ReplicatedStorage.HyperShared.Task)

-- Benchmark parameters
local TEST_COUNT = 1_000_000

-- Helpers
local function formatMemory(kb: number)
	return string.format("%.2f MB", kb / 1024)
end

local function waitForCompletion(expectedCount: number, onComplete: () -> ())
	local counter = 0
	return function()
		counter += 1
		if counter >= expectedCount then
			onComplete()
		end
	end
end

-- Run a single benchmark pass
local function run(name: string, spawnFunc: (callback: () -> ()) -> ())
	local startMem = gcinfo()
	local startTime = os.clock()

	local done = waitForCompletion(TEST_COUNT, function()
		local elapsed = os.clock() - startTime
		local endMem = gcinfo()
		print(("[%s] Elapsed: %.3f s | ΔMem: %s")
			:format(name, elapsed, formatMemory(endMem - startMem)))
	end)

	for _ = 1, TEST_COUNT do
		spawnFunc(done)
	end
end

run("Default task.spawn", function(done)
	task.delay(0.1, done)
end)

task.delay(1, function()
	run("Pooled Task.spawn", function(done)
		Task.delay(0.1, done)
	end)
end)



return 0