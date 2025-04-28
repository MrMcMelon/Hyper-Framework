--!native
--!optimize 2

-- Heap.luau
-- Implementaion of min/max heap in luau

-- A Method that returns true if val1 > val2, used for sorting the heap
export type Comparator<T> = (val1: T, val2: T) -> boolean

export type Heap<T> = {
	__index: Heap<T>,
	__tostring: (self: Heap<T>) -> string,
	__len: (self: Heap<T>) -> number,
	new: (f: Comparator<T>) -> Heap<T>,
	min: () -> Heap<T>,
	max: () -> Heap<T>,
	heapify: (tbl : {T}, f: Comparator<T>) -> Heap<T>,
	_compare : Comparator<T>,
	_collection : {T},
	size : number,
	push: (self: Heap<T>, val: T) -> (),
	pop: (self: Heap<T>) -> T?,
	peek: (self: Heap<T>) -> T?,
	toArray: (self: Heap<T>) -> (),
	clone: (self: Heap<T>) -> Heap<T>,
	clear: (self: Heap<T>) -> (),
	iter: (self: Heap<T>) -> {T},
}


local floor = math.floor
local insert = table.insert
local remove = table.remove
local clone = table.clone
local clear = table.clear

-- Default comparator for min heap
local function minCompare(num1: number, num2: number): boolean
	return num1 < num2
end

-- Default comparator for max heap
local function maxCompare(num1: number, num2: number): boolean
	return num1 > num2
end

-- Internal method to move the given index up
local function siftUp(heap: Heap<any>, index): ()
	local parentIndex
	local collection = heap._collection
	local compare = heap._compare
	local givenVal = collection[index]

	while index > 1 do
		parentIndex = floor(index / 2)
		local parentVal = collection[parentIndex]
		if compare(givenVal, parentVal) then
			collection[index] = parentVal
			index = parentIndex
		else
			break
		end
	end

	collection[index] = givenVal
end

-- Internal method to move the given index down
local function siftDown(heap: Heap<any>, index): ()
	local compare = heap._compare
	local collection = heap._collection
	local size = heap.size
	local givenVal = collection[index]

	while true do
		local leftIndex = 2 * index
		if leftIndex > size then break end

		local rightIndex = leftIndex + 1
		local childIndex = leftIndex

		local leftVal = collection[leftIndex]
		local rightVal = collection[rightIndex]
		local childVal = leftVal

		if rightIndex <= size and compare(rightVal, leftVal) then
			childIndex = rightIndex
			childVal = rightVal
		end

		if not compare(childVal, givenVal) then break end

		collection[index] = childVal
		index = childIndex
	end

	collection[index] = givenVal
end

local Heap: Heap<any> = {} :: Heap<any>
Heap.__index = Heap
Heap.__tostring = function(self)
	local out = "Heap: \n"
	for i = 1, self.size do
		out = out .. ("[%d]: %s\n"):format(i, tostring(self._collection[i]))
	end
	return out
end
Heap.__len = function(self)
	return self.size
end

-- Adds a value to the heap
function Heap:push(val)
	insert(self._collection, val)
	local size = self.size + 1
	self.size = size
	if size <= 1 then
		return
	end
	siftUp(self, size)
end

-- Removes the root value from the heap or nil if heap is empty
function Heap:pop()
	local collection = self._collection
	local size = self.size
	if size > 0 then
		local val = collection[1]
		collection[1] = collection[size]
		remove(collection, size)
		size -= 1
		self.size = size
		if size > 0 then
			siftDown(self, 1)
		end
		return val
	end
	return
end

-- Returns the root value without removing
function Heap:peek()
	return self._collection[1]
end

-- Converts the heap into a lua table
function Heap:toArray()
	return clone(self._collection)
end

-- Returns a copy of the heap
function Heap:clone()
	local newHeap = Heap.new(self._compare)
	newHeap._collection = clone(self._collection)
	newHeap.size = self.size
	return newHeap
end

function Heap:clear()
	self.size = 0
	clear(self._collection)
end

function Heap:iter()
	return self._collection
end

-- Heap constructor using custom comparator
function Heap.new(comparator)
	return setmetatable({
		_collection = {},
		_compare = comparator,
		size = 0
	}
	, Heap)
end

-- Returns a numerical min heap
function Heap.min()
	return Heap.new(minCompare)
end

-- Returns a numerical max heap
function Heap.max()
	return Heap.new(maxCompare)
end

-- Converts a table to heap with the given comparator
function Heap.heapify(tbl, comparator)
	local heap = Heap.new(comparator)
	heap._collection = clone(tbl)
	heap.size = #tbl
	for i = floor(heap.size/2), 1, -1 do
	  siftDown(heap, i)
	end
	return heap
end

return table.freeze(Heap)