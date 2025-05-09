--!strict
--!optimize 2
--!native

-- Replica.luau
-- State replication manager for luau

local Players = game:GetService("Players")
local Signal = require(script.Parent.Signal)
local Buffers = require(script.Parent.Buffers)
local Net = require(script.Parent.Net)
local RunService = game:GetService("RunService")
local Task = require(script.Parent.Task)

local writer, reader = Net.writer, Net.reader

local writeu8, writeu16 = writer.u8, writer.u16
local readu8, readu16 = reader.u8, reader.u16

export type Change = {
	changeType: number,
	objectId: number,
	templateId: number,
	index: number,
	val: any
}

export type ReplicaObject<T = {[string]: any}> = {
	data: T,
	_listeners: { Player }
}