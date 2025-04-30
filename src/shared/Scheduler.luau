--!optimize 2
--!native

-- Scheduler.luau
-- schedules a function to run after certain delay or in repeat.

-- The time the scheduler should assign automatically if no loop time is given (really low value means it runs every frame)
local MIN_LOOP_TIME = 1/1000

-- The time allocated to the scheduler each frame
local MAX_FRAME_TIME = 1/1

-- Main interface to interact with the scheduler
export type Job<A... = ...any> = {
	new: (f: (A...) -> ()) -> Job<A...>,
	after: (self: Job<A...>, val: number?, A...) -> Job<A...>,
	every: (self: Job<A...>, val: number?) -> Job<A...>,
	pause: (self: Job<A...>) -> Job<A...>,
	resume: (self: Job<A...>) -> Job<A...>,
	destroy: (self: Job<A...>) -> Job<A...>,

	_next: number,
	_loopTime: number?,
	_paused: boolean,
	_destroyed: boolean,
	_args: {any},
	_function: (A...) -> (),

	__index : Job<A...>,
}

local Heap = require(script.Parent.DataStructures.Heap)
local clock = os.clock
local max = math.max
local wait = task.wait
-- Comparator for the heap
local function compare(a: Job<...any>, b: Job<...any>): boolean
	return a._next < b._next
end

local heap: Heap.Heap<Job<...any>> = Heap.new(compare)

local Job: Job = {}:: Job
Job.__index = Job

function Job.new(f)
	return setmetatable({
		_next = 0,
		_paused = false,
		_destroyed = false,
		_args = {},
		_function = f
	}, Job)
end

-- schedules the job
function Job:after(val, ...)
	self._args = {...}
	self._next = clock() + (val or 0)
	heap:push(self)
end

-- sets the job's loop time
function Job:every(val)
	val = max(val, MIN_LOOP_TIME)
	self._loopTime = val
end

-- Marks the job as paused, the scheduler skips paused jobs
function Job:pause()
	self._paused = true
end

-- Removes the paused flag from a job
function Job:resume()
	self._paused = false
end

-- Marks the job as destroyed and is cleaned up by the scheduler when it appears at the front of the heap.
function Job:destroy()
	self._destroyed = true
end

-- We don't use heartbeat because using a single thread is more efficient than creating one every frame
coroutine.wrap(function()
	while true do
		wait()
		local frameStart = clock()
		local job = heap:pop()
		while job do			
			local scheduledTime = job._next
			if job._destroyed then
				job = nil
				-- We just continue as manually clearing the job will just introduce unesscarry overhead so we just wait for the gc to collect it
				continue
			end
			if scheduledTime <= clock() then
				if not job._paused then
					local success, err = pcall(job._function, unpack(job._args))
					if not success then
						warn(err)
					end
				end
				local loopTime = job._loopTime
				if loopTime then
					job._next = scheduledTime + loopTime
					heap:push(job)
				end
				if clock() - frameStart > MAX_FRAME_TIME then
					-- We exit loop and the rest of jobs are processed next frame, this ensures that frametimes aren't too long causing the script to yield and game to freeze
					break
				end
				job = heap:pop()
			else
				-- We exit loop early because the jobs are sorted in acsending order of thier _next in the heap
				break
			end
		end
	end
end)()

return table.freeze(Job)
