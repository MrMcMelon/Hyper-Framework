--!optimize 2
--!native

-- Net.luau
-- Hyper frameworks networking solution.

local Signal = require(script.Parent.Signal)
local Buffers = require(script.Parent.Buffers)

export type Packet<A... = ...any> = {
	__index: Packet<A...>,
	new: (A...) -> Packet<A...>,
	FireServer: (A...) -> (),
	FireClient: (player: Player, A...) -> (),
	FireAllClients: (A...) -> (),
	OnClientEvent: Signal.Signal<A...>,
	OnServerEvent: Signal.Signal<(Player, A...)>,
}

local bufferSpace, writer = Buffers(256, 2)

local Packet: Packet = {}:: Packet

function Packet.new(...)
	
end
