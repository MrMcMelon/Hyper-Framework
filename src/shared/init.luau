--!strict
--!native
--!optimize 2

local Task = require(script.Task)
local Signal = require(script.Signal)
local Buffers = require(script.Buffers)


return table.freeze{
	spawn = Task.spawn,
	defer = Task.defer,
	delay = Task.delay,
	signal = Signal,
	bufferSpace = Buffers
}