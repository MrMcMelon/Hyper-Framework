--!optimize 2
--!native

-- LinkedList.luau
-- Doubly LinkedList implementation in Luau

-- Each value is represented by a Node
export type Node<T> = {
	next : Node<T>?,
	prev : Node<T>?,
	val: T,
	list: List<T>,
	destroy: (self: Node<T>) -> T,
}

-- The Main structure
export type List<T> = {
	head: Node<T>?,
	tail: Node<T>?,
	size: number,

	iter: (self: List<T>) -> () -> (Node<T>?, T?),
	reverseIter: (self: List<T>) -> () -> (Node<T>?, T?),
	values: (self: List<T>) -> () -> (T?),
	reverseValues: (self: List<T>) -> () -> (T?),
	push: (self: List<T>, val: T) -> Node<T>,
	pop: (self: List<T>) -> T?,
	unshift: (self: List<T>, val: T) -> Node<T>,
	shift: (self: List<T>) -> T?,

	new: () -> List<T>,
	__index: List<T>,
	__tostring: (self: List<T>) -> string,
	__len: (self: List<T>) -> number,
}

-- Removes a node from its list, destroys it and returns its value
local function destroy<T>(self: Node<T>): T
	local next, prev = self.next, self.prev
	local list = self.list
	if prev then
		prev.next = next
	else
		list.head = next
	end
	if next then
		next.prev = prev
	else
		list.tail = prev
	end
	local val = self.val
	table.clear(self)
	return val
end

-- Internal method to create a node
local function createNode<T>(list: List<T>, val: T): Node<T>
	return {
		next = nil,
		prev = nil,
		val = val,
		list = list,
		destroy = destroy,
	}
end

local List: List<any> = {} :: List<any>
List.__index = List
List.__tostring = function(self)
	local node = self.head
	local vals = {}
	while node do
		table.insert(vals, tostring(node.val))
		node = node.next
	end
	return "Linked List: {"..table.concat(vals, ", ").."}"
end
List.__len = function(self)
	return self.size
end

-- List constructor
function List.new()
	return setmetatable({
		head = nil,
		tail = nil,
		size = 0,
	}, List)
end

-- Adds the given val to the back of the list and returns a node object
function List:push(val)
	local node = createNode(self, val)
	local tail = self.tail
	if tail then
		tail.next = node
		node.prev = tail
	else
		self.head = node
	end
	self.tail = node
	self.size += 1
	return node
end

-- Adds the given val to the front of the list and returns a node object
function List:unshift(val)
	local node = createNode(self, val)
	local head = self.head
	if head then
		head.prev = node
		node.next = head
	else
		self.tail = node
	end
	self.head = node
	self.size += 1
	return node
end

-- Removes the last node (Tail Node) in the list and returns its value
function List:pop()
	local node = self.tail
	if node then
		return node:destroy()
	end
	return
end

-- Removes the first node (Head Node) in the list and returns its value
function List:shift()
	local node = self.head
	if node then
		return node:destroy()
	end
	return
end

-- Returns a iterator that returns the nodes and its respective value in the list (HEAD -> TAIL)
function List:iter()
	local node = self.head
	return function()
		if not node then
			return
		end
		local current = node
		node = current.next
		return current, current.val
	end
end

-- Returns a iterator that returns the nodes and its respective value in the list in reverse order (TAIL -> HEAD)
function List:reverseIter()
	local node = self.tail
	return function()
		if not node then
			return
		end
		local current = node
		node = current.prev
		return current, current.val
	end
end

-- Returns a iterator that returns values in the list (HEAD -> TAIL)
function List:values()
	local node = self.head
	return function()
		if not node then
			return
		end
		local current = node
		node = current.next
		return current.val
	end
end

-- Returns a iterator that returns values in the list in reverse order (TAIL -> HEAD)
function List:reverseValues()
	local node = self.tail
	return function()
		if not node then
			return
		end
		local current = node
		node = current.prev
		return current.val
	end
end

return table.freeze(List)