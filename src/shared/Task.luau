--!strict
--!native
--!optimize 2

-- Task.luau
-- Simple coroutine pooling module

local MAX_POOL_SIZE = 100
local SWEEPER_INTERVAL = 5

local threads = {}

-- resume function runs the given function and adds the thread back to the pool
local function resume(f: (...any) -> (), ...: any)
	f(...)
	table.insert(threads, coroutine.running())
end

-- halts the current thread when its resumed it calls the resume function
local function halt()
	while true do 
		resume(coroutine.yield()) 
	end
end

local Task = {}

function Task.spawn<A...>(f: (A...) -> (), ...: A...)
	return task.spawn(table.remove(threads) or task.spawn(halt), f, ...)
end

function Task.defer<A...>(f: (A...) -> (), ...: A...)
	return task.defer(table.remove(threads) or task.spawn(halt), f, ...)
end

function Task.delay<A...>(duration: number, f: (A...) -> (), ...: A...)
	return task.delay(duration, table.remove(threads) or task.spawn(halt), f, ...)
end

task.defer(function()
	while true do
		task.wait(SWEEPER_INTERVAL)
		local size = #threads
		while #threads > MAX_POOL_SIZE do
			coroutine.close(threads[size])
			threads[size] = nil
			size -= 1
		end
	end
end)

return table.freeze(Task)
