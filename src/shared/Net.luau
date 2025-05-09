--!strict
--!native
--!optimize 2

-- Net.luau
-- Hyper framework's buffer based networking library

local Buffers = require(script.Parent.Buffers)
local Signal = require(script.Parent.Signal)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

export type Packet<A... = ...any> = {
	fireClient: (self: Packet<A...>, player: Player, A...) -> (),
	fireServer: (self: Packet<A...>, A...) -> (),
	fireAllClients: (self: Packet<A...>, A...) -> (),
	fireGivenClients: (self: Packet<A...>, players: { Player }, A...) -> (),
	onServerEvent: Signal.Signal<(Player, A...)>,
	onClientEvent: Signal.Signal<A...>,
	_id: number,
}

local env: "CLIENT" | "SERVER" = (RunService:IsClient() and "CLIENT") or "SERVER"
local bufferspace, fetch, writer, reader, register = Buffers(128, 2)
local counter = 0
local curr = 0
local packetEncoders, packetDecoders, packetSignals, packetArgCount = {}, {}, {}, {}
local writeu8, readu8 = writer.u8, reader.u8
local remote = script.Parent:WaitForChild("Remote"):: RemoteEvent


local customCounter = 256

-- Networking module doesn't really need to restrict type id to 256 so any other module using networking module can define its own types using custom.
local function custom<T>(encode: (T) -> (), decode: () -> (T, number)): T
	local type = register(customCounter, encode, decode)
	customCounter += 1
	return type
end


local Packet: Packet = {} :: Packet
Packet["__index"] = Packet

local constructor: <A...>(A...) -> Packet<A...>

local function invalid(): ...any
	error("Packet method called in the wrong enviorment")
end

local invalidSignal: Signal.Signal = {
	connect = invalid,
	wait = invalid,
	once = invalid,
	fire = invalid,
	destroy = invalid,
	_prev = {} :: Signal.Connection,
	_next = {} :: Signal.Connection,
}

if env == "CLIENT" then
	local packetQueues = {}
	local uniquePackets = 0
	local decodeQueue: { buffer } = {}
	
	constructor = function(...)
		if counter > 255 then
			error("Packet id counter overflow")
		end
		local id = counter
		local signal = Signal()
		local packet = {
			_id = id,
			onServerEvent = invalidSignal,
			onClientEvent = signal,
		}
		counter += 1
		curr = id
		local encoders = {}
		local decoders = {}
		local args = {...}
		local argCount = 0
		for _, typeId in args do
			local bufferType: Buffers.BufferType<any>? = fetch(typeId)
			if not bufferType then
				error("Invalid type passed into packet constructor")
			end
			table.insert(encoders, bufferType.encode)
			table.insert(decoders, bufferType.decode)
			argCount += 1
		end
		packetArgCount[id] = argCount
		packetDecoders[id] = decoders
		packetEncoders[id] = encoders

		packetSignals[id] = signal
		packetQueues[id] = {}
		return setmetatable(packet, Packet) :: any
	end

	function Packet:fireServer(...)
		local packetQueue = packetQueues[self._id]
		table.insert(packetQueue, {...})
		if #packetQueue == 1 then
			uniquePackets += 1
		end
	end

	function Packet:fireClient()
		error("fire client cannot be used in the client")
	end

	function Packet:fireAllClients()
		error("fire all clients cannot be used in the client")
	end

	function Packet:fireGivenClients()
		error("fire given clients cannot be used in the client")
	end

	local args = {}

	task.defer(function()
		while true do
			task.wait()

			-- Packet encoding
			if uniquePackets > 0 then
				writeu8(uniquePackets)
				for id = 0, curr do
					local packetQueue = packetQueues[id]
					local count = #packetQueue
					if count < 1 then
						continue
					end
					if count > 255 then
						warn("Packet count overflow, extra packets were dropped")
						count = 255
					end
					writeu8(id)
					writeu8(count)
					local encoders = packetEncoders[id]
					local argCount = packetArgCount[id]
					for i = 1, count do
						local packetArgs = packetQueue[i]
						for index = 1, argCount do
							local encode = encoders[argCount]
							encode(packetArgs[index])
						end
						packetQueue[i] = nil
					end
				end
				local buf = writer.pop()
				remote:FireServer(buf)
				uniquePackets = 0				
			end

			-- Packet decoding
			local decodeQueueSize = #decodeQueue
			if decodeQueueSize > 0 then
				for i = 1, decodeQueueSize do
					local buf = decodeQueue[i]
					reader.push(buf)
					local uniqueRecievedPackets = readu8()
					for _ = 1, uniqueRecievedPackets do
						local id = readu8()
						local count = readu8()
						local decoders = packetDecoders[id]
						local signal = packetSignals[id]
						local argCount = packetArgCount[id]
						for _ = 1, count do
							for index = 1, argCount do
								args[index] = decoders[index]()
							end
							signal:fire(unpack(args))
							table.clear(args)
						end
					end
					decodeQueue[i] = nil
				end
			end

		end
	end)

	remote.OnClientEvent:Connect(function(buf: buffer)
		table.insert(decodeQueue, buf)
	end)
else
	local playerQueues = {}
	local packetQueuesTemplate = {}
	local playerUniquePackets = {}
	local playerDecodeQueue: { [Player]: { buffer } } = {}
	local globalQueues = {}
	local globalUniquePackets = 0
	local givenQueues: { [ { Player } ]: { { any } } } = {}
	local givenUniquePackets: { [ { Player } ]: number} = {}

	Players.PlayerAdded:Connect(function(player)
		playerQueues[player] = table.clone(packetQueuesTemplate)
		playerUniquePackets[player] = 0
		playerDecodeQueue[player] = {}
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerQueues[player] = nil
		playerUniquePackets[player] = nil
		playerDecodeQueue[player] = nil
		for players, _ in givenQueues do
			if table.find(players, player) then
				givenQueues[players] = nil
				givenUniquePackets[players] = nil
			end
		end
	end)

	constructor = function(...)
		if counter > 255 then
			error("Packet id counter overflow")
		end
		local id = counter
		local signal = Signal()
		local packet = {
			_id = id,
			onServerEvent = signal,
			onClientEvent = invalidSignal,
		}
		counter += 1
		curr = id
		local encoders = {}
		local decoders = {}
		local args = {...}
		local argCount = 0
		for _, typeId in args do
			local bufferType: Buffers.BufferType<any>? = fetch(typeId)
			if not bufferType then
				error("Invalid type passed into packet constructor")
			end
			table.insert(encoders, bufferType.encode)
			table.insert(decoders, bufferType.decode)
			argCount += 1
		end
		packetArgCount[id] = argCount
		packetDecoders[id] = decoders
		packetEncoders[id] = encoders
		packetQueuesTemplate[id] = {}
		globalQueues[id] = {}
		packetSignals[id] = signal
		return setmetatable(packet, Packet) :: any
	end

	function Packet:fireServer()
		error("cannot use fire server on the server")
	end

	function Packet:fireClient(player, ...)
		local packetQueue = playerQueues[player][self._id]
		table.insert(packetQueue, {...})
		if #packetQueue == 1 then
			playerUniquePackets[player] += 1
		end
	end

	function Packet:fireAllClients(...)
		local packetQueue = globalQueues[self._id]
		table.insert(packetQueue, {...})
		if #packetQueue == 1 then
			globalUniquePackets += 1
		end
	end

	function Packet:fireGivenClients(players, ...)
		local listQueue = givenQueues[players]
		if not listQueue then
			listQueue = table.clone(packetQueuesTemplate)
			givenUniquePackets[players] = 0
			givenQueues[players] = listQueue
		end
		local packetQueue = listQueue[self._id]
		table.insert(packetQueue, { ... })
		if #packetQueue == 1 then
			givenUniquePackets[players] += 1			
		end
	end

	local args = {}

	task.defer(function()
		while true do
			task.wait()

			-- All packet encoding
			if globalUniquePackets > 0 then
				writeu8(globalUniquePackets)
				for id = 0, curr do
					local packetQueue = globalQueues[id]
					local count = #packetQueue
					if count < 1 then
						continue
					end
					if count > 255 then
						warn("Packet count overflow, extra packets were dropped")
						count = 255
					end
					writeu8(id)
					writeu8(count)
					local encoders = packetEncoders[id]
					local argCount = packetArgCount[id]
					for i = 1, count do
						local packetArgs = packetQueue[i]
						for index = 1, argCount do
							local encode = encoders[index]
							encode(packetArgs[index])
						end
						packetQueue[i] = nil
					end
				end
				local buf = writer.pop()
				remote:FireAllClients(buf)
				globalUniquePackets = 0
			end

			-- Packet encoding
			for player, packetQueues: { any } in playerQueues do
				local uniquePackets = playerUniquePackets[player]
				if uniquePackets < 1 then
					continue
				end
				writeu8(uniquePackets)
				for id = 0, curr do
					local packetQueue = packetQueues[id]
					local count = #packetQueue
					if count < 1 then
						continue
					end
					if count > 255 then
						warn("Packet count overflow, extra packets were dropped")
						count = 255
					end
					writeu8(id)
					writeu8(count)
					local encoders = packetEncoders[id]
					local argCount = packetArgCount[id]
					for i = 1, count do
						local packetArgs = packetQueue[i]
						for index = 1, argCount do
							local encode = encoders[argCount]
							encode(packetArgs[index])
						end
						packetQueue[i] = nil
					end
				end
				local buf = writer.pop()
				remote:FireClient(player, buf)
				playerUniquePackets[player] = 0				
			end

			-- Packet encoding
			for players, packetQueues: { any } in givenQueues do
				local uniquePackets = givenUniquePackets[players]
				if uniquePackets < 1 then
					continue
				end
				writeu8(uniquePackets)
				for id = 0, curr do
					local packetQueue = packetQueues[id]
					local count = #packetQueue
					if count < 1 then
						continue
					end
					if count > 255 then
						warn("Packet count overflow, extra packets were dropped")
						count = 255
					end
					writeu8(id)
					writeu8(count)
					local encoders = packetEncoders[id]
					local argCount = packetArgCount[id]
					for i = 1, count do
						local packetArgs = packetQueue[i]
						for index = 1, argCount do
							local encode = encoders[argCount]
							encode(packetArgs[index])
						end
						packetQueue[i] = nil
					end
				end
				local buf = writer.pop()
				for _, player in players do
					remote:FireClient(player, buf)
				end				
				givenUniquePackets[players] = 0
			end		

			-- Packet decoding
			for player, decodeQueue in playerDecodeQueue do
				local decodeQueueSize = #decodeQueue
				if decodeQueueSize < 1 then
					continue
				end
				for i = 1, decodeQueueSize do
					reader.push(decodeQueue[i])
					local uniquePackets = readu8()
					if uniquePackets > 255 then
						warn(player, " sent a packet with uniquePackets >255")
						player:Kick("Security Kick, Do not attempt to send corrupt packets.")
						return
					end
					for _ = 1, uniquePackets do
						local id = readu8()
						local count = readu8()
						if count > 255 then
							warn(player, " sent a packet with count >255")
							player:Kick("Security Kick, Do not attempt to send corrupt packets.")
							return
						end
						local decoders = packetDecoders[id]
						if not decoders then
							warn(player, " sent a packet with invalid packetId, ", id)
							player:Kick("Security Kick, Do not attempt to send corrupt packets.")
							return
						end
						local argCount = packetArgCount[id]
						local signal = packetSignals[id]
						for _ = 1, count do
							for index = 1, argCount do
								args[index] = decoders[index]()
							end
							signal:fire(player, unpack(args))
							table.clear(args)
						end
					end
					decodeQueue[i] = nil
				end
			end

		end
	end)

	remote.OnServerEvent:Connect(function(player, buf: buffer)
		if typeof(buf) ~= "buffer" then
			warn(player, " sent a packet without buffer type")
			player:Kick("Security Kick, Do not attempt to send corrupt packets.")
		end
		table.insert(playerDecodeQueue[player], buf)
	end)
end

return table.freeze{new = constructor, types = bufferspace, custom = custom, writer = writer, reader = reader}
