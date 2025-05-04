--!strict
--!native
--!optimize 2

-- Signal.luau
-- Signals for hyper framework

local Task = require(script.Parent.Task)
local Garbot = require(script.Parent.Garbot)

export type Callback<A...> = (A...) -> (...any)

export type Connection<A... = (...any)> = {
	_prev: Connection<A...>,
	_next: Connection<A...>,
	_callback: Callback<A...>?,
	_once: boolean,
	_thread: thread?,
	disconnect: (self: Connection<A...>) -> (),
}

export type Signal<A... = (...any)> = {
	_prev: Connection<A...>,
	_next: Connection<A...>,
	connect: (self: Signal<A...>, f: Callback<A...>) -> Connection<A...>,
	once: (self: Signal<A...>, f: Callback<A...>) -> Connection<A...>,
	wait: (self: Signal<A...>) -> (Connection<A...>, A...),
	fire: (self: Signal<A...>, A...) -> (),
	destroy: (self: Signal<A...>) -> (),
}


local Connection: Connection = {}:: Connection
Connection["__index"] = Connection

function Connection:disconnect()
	local prev = self._prev
	local next = self._next
	next._prev = prev
	prev._next = next
end

local Signal: Signal = {}:: Signal
Signal["__index"] = Signal

function Signal:connect(f)
	local prev = self._prev
	local connection = (setmetatable({
		_prev = prev,
		_next = self,
		_once = false,
		_callback = f,
	}
	, Connection):: any):: Connection
	prev._next = connection
	self._prev = connection
	return connection
end

function Signal:once(f)
	local prev = self._prev
	local connection = (setmetatable({
		_prev = prev,
		_next = self,
		_callback = f,
		_once = true
	}
	, Connection):: any):: Connection
	prev._next = connection
	self._prev = connection
	return connection
end

function Signal:wait()
	local prev = self._prev
	local connection = (setmetatable({
		_prev = prev,
		_next = self,
		_thread = coroutine.running(),
		_once = true
	}
	, Connection):: any):: Connection
	prev._next = connection
	self._prev = connection
	return connection, coroutine.yield()
end

function Signal:fire(...)
	local connection = self._next
	while connection._once ~= nil do
		local callback = connection._callback
		if callback then
			Task.defer(callback, ...)
		end
		local thread = connection._thread
		if thread then
			task.defer(thread, ...)
		end
		local prev = connection._prev
		local next = connection._next
		if connection._once then			
			prev._next = next
			next._prev = prev
		end
		connection = next
	end
end

function Signal:destroy()
	local connection = self._next
	while connection._once ~= nil do
		local thread = connection._thread
		if thread then
			coroutine.close(thread)
		end
		Garbot.collect(connection)
	end
	Garbot.collect(self)
end


return function<A...>(): Signal<A...>
	local signal = {}
	signal._prev = signal
	signal._next = signal
	return (setmetatable(signal, Signal):: any):: Signal<A...>
end
