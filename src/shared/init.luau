--!optimize 2
--!native

local DataStructures = script.DataStructures

local LinkedList =  require(DataStructures.LinkedList)
local Signal = require(script.Signal)
local Scheduler = require(script.Scheduler)
local Heap = require(DataStructures.Heap)

export type LinkedList<T> = LinkedList.List<T>
export type LinkedListNode<T> = LinkedList.Node<T>
export type ScriptSignal<A...> = Signal.Signal<A...>
export type ScriptConnection = Signal.Connection
export type ScriptCallback<A...> = Signal.Callback<A...>
export type HeapComparator<T> = Heap.Comparator<T>
export type Heap<T> = Heap.Heap<T>
export type Job<A...> = Scheduler.Job<A...>

return table.freeze{
	LinkedList = LinkedList.new,
	Signal = Signal.new,
	Scheduler = Scheduler.new,
	Heap = Heap.new,
}