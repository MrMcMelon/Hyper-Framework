--!optimize 2
--!native

local DataStructures = script.DataStructures

local LinkedList = require(DataStructures.LinkedList)

local myLinkedList: LinkedList.List<number> = LinkedList.new()

myLinkedList:push(1)
myLinkedList:push(2)
myLinkedList:push(3)
myLinkedList:push(4)
myLinkedList:unshift(0)

for node, val in myLinkedList:iter() do
	print(node:destroy())
end

print(myLinkedList)

return table.freeze{

}