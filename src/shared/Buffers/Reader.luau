--!native
--!optimize 2

-- Reader.luau
-- Reader instance loads a buffer and reads from it

export type Reader = {
	push: (val: buffer) -> (),

	u8: () -> (number, number),
	u16: () -> (number, number),
	u32: () -> (number, number),
	i8: () -> (number, number),
	i16: () -> (number, number),
	i32: () -> (number, number),
	f32: () -> (number, number),
	f64: () -> (number, number),
	boolean: () -> (boolean, number),
	cframe: () -> (CFrame, number),
	vector3: () -> (Vector3, number),
	string: () -> (string, number),
	buffer: () -> (buffer, number),
}

local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32
local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local readString = buffer.readstring

local cframe = CFrame.new
local angles = CFrame.Angles
local vector3 = Vector3.new

local create = buffer.create
local copy = buffer.copy

local readHeader = readu16
local headerSize = 2

local function new(): Reader
	
	local buf: buffer
	local cursor = 0
	
	local function push(val: buffer)
		buf = val
		cursor = 0
	end

	local reader: Reader = {push = push}:: Reader

	reader.u8 = function()
		local val = readu8(buf, cursor)
		cursor += 1
		return val, 1
	end

	reader.u16 = function()
		local val = readu16(buf, cursor)
		cursor += 2
		return val, 2
	end

	reader.u32 = function()
		local val = readu32(buf, cursor)
		cursor += 4
		return val, 4
	end

	reader.i8 = function()
		local val = readi8(buf, cursor)
		cursor += 1
		return val, 1
	end

	reader.i16 = function()
		local val = readi16(buf, cursor)
		cursor += 2
		return val, 2
	end

	reader.i32 = function()
		local val = readi32(buf, cursor)
		cursor += 4
		return val, 4
	end

	reader.f32 = function()
		local val = readf32(buf, cursor)
		cursor += 4
		return val, 4
	end

	reader.f64 = function()
		local val = readf64(buf, cursor)
		cursor += 8
		return val, 8
	end

	reader.boolean = function()
		local val = readu8(buf, cursor) ~= 0
		cursor += 1
		return val, 1
	end

	reader.cframe = function()
		local x, y, z = readf32(buf, cursor), readf32(buf, cursor + 4),  readf32(buf, cursor + 8)
		local rx, ry, rz = readf32(buf, cursor + 12), readf32(buf, cursor + 16),  readf32(buf, cursor + 20)
		cursor += 24
		return cframe(x, y, z) * angles(rx, ry, rz), 24
	end

	reader.vector3 = function()
		local x, y, z = readf32(buf, cursor), readf32(buf, cursor + 4),  readf32(buf, cursor + 8)
		cursor += 12
		return vector3(x, y, z)
	end

	reader.string = function()
		local s = readHeader(buf, cursor)
		cursor += headerSize
		local val = readString(buf, cursor, s)
		cursor += s
		return val, s
	end

	reader.buffer = function()
		local s = readHeader(buf, cursor)
		cursor += headerSize
		local val = create(s)
		copy(val, 0, buf, cursor, s)
		cursor += s
		return val, s
	end

	return table.freeze(reader)
end

return new