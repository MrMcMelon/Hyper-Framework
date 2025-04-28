--!native
--!optimize 2

local Scheduler = require(script.Parent.Scheduler)
local LinkedList = require(script.Parent.DataStructures.LinkedList)

export type Callback<A...> = (A...) -> ()

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<A...> = {
	__index: Signal<A...>,

	_list: LinkedList.List<Scheduler.Job<A...>>,
	_onceList: LinkedList.List<Scheduler.Job<A...>>,
	_threads : { thread },

	new: () -> Signal<A...>,

	-- Pascal case to retain simliarity with Roblox Api
	Connect: (self: Signal<A...>, f: Callback<A...>) -> Connection,
	Once: (self: Signal<A...>, f: Callback<A...>) -> Connection,
	Wait: (self: Signal<A...>) -> (),
	Destroy: (self: Signal<A...>) -> (),
	Fire: (self: Signal<A...>, A...) -> (),

}

local schedule = Scheduler.new

local Signal: Signal<...any> = {} :: Signal<...any>
Signal.__index = Signal

-- Signal Constructor
function Signal.new()
	return setmetatable({
		_list = LinkedList.new(),
		_onceList = LinkedList.new(),
		_threads = {},
	}, Signal)
end

-- adds the given callback to the signal and is run everytime fire is called
function Signal:Connect(f)
	local job = schedule(f)
	local node = self._list:push(job)
	return {
		Disconnect = function()
			warn("Disconnecting")
			job:destroy()
			node:destroy()
		end
	}
end

-- adds the given callback to the signal but its only run the first time fire is called
function Signal:Once(f)
	local job = schedule(f)
	local node = self._onceList:push(job)
	return {
		Disconnect = function()
			job:destroy()
			node:destroy()
		end
	}
end

-- yields the current thread until
function Signal:Wait()
	local thread = coroutine.running()
	table.insert(self._threads, thread)
	coroutine.yield()
end

-- method to invoke all the callback and resume the threads in the given signal
function Signal:Fire(...)
	for job in self._list:values() do
		job:after(0, ...)
	end
	for job in self._onceList:values() do
		job:after(0, ...)
		job:destroy()
	end
	self._onceList:clear()
	for _, thread in self._threads do
		task.spawn(thread)
	end
	table.clear(self._threads)
end

-- cleanup the signal and disconnects all the connections
function Signal:Destroy()
	for node, job in self._list:iter() do
		job:destroy()
		node:destroy()
	end
	for node, job in self._onceList:iter() do
		job:destroy()
		node:destroy()
	end
	table.clear(self._threads)
	table.clear(self)
end

return table.freeze(Signal)