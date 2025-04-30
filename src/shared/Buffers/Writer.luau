--!native
--!optimize 2

-- Writer.luau
-- A writer instances allows writing to a buffer and then get copy of the writen part

-- Closure based class (less overhead but more memory but there won't be many instances of writer)
export type Writer = {
	reserve: (bytes: number) -> number,
	pop: () -> buffer,

	u8: (val: number) -> (),
	u16: (val: number) -> (),
	u32: (val: number) -> (),
	i8: (val: number) -> (),
	i16: (val: number) -> (),
	i32: (val: number) -> (),
	f32: (val: number) -> (),
	f64: (val: number) -> (),
	boolean: (val: boolean) -> (),
	cframe: (val: CFrame) -> (),
	vector3: (val: Vector3) -> (),
	color3: (val: Color3) -> (),
	string: (val: string) -> (),
	buffer: (val: buffer) -> (),
}

local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32
local writei32 = buffer.writei32
local writei16 = buffer.writei16
local writei8 = buffer.writei8
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local writeString = buffer.writestring

local create = buffer.create
local copy = buffer.copy
local len = buffer.len

local writeHeader = writeu16
local headerSize = 2

local function new(defaultSize: number, scaleFactor: number): Writer
	local size = defaultSize
	local buf = create(size)
	local cursor = 0

	-- reserve n bytes and returns the position in the buffer to start writing from
	local function reserve(bytes: number): number
		local base = cursor
		cursor = cursor + bytes
		if cursor > size then
			size = math.max(size * scaleFactor, bytes)
			local newBuf = create(size)
			copy(newBuf, 0, buf, 0, base)
			buf = newBuf
		end
		return base
	end

	-- creates a buffer 
	local function pop(): buffer
		local r = copy(create(cursor), 0, buf, 0, cursor)
		cursor = 0
		return r
	end

	local writer: Writer = {
		reserve = reserve,
		pop = pop,
	}:: Writer

	writer.u8 = function(val) 
		writeu8(buf, reserve(1), val)
	end

	writer.u16 = function(val) 
		writeu16(buf, reserve(2), val)
	end

	writer.u32 = function(val) 
		writeu32(buf, reserve(4), val)
	end

	writer.i8 = function(val) 
		writei8(buf, reserve(1), val)
	end

	writer.i16 = function(val) 
		writei16(buf, reserve(2), val)
	end

	writer.i32 = function(val) 
		writei32(buf, reserve(4), val)
	end

	writer.f32 = function(val) 
		writef32(buf, reserve(4), val)
	end

	writer.f64 = function(val) 
		writef64(buf, reserve(8), val)
	end

	writer.boolean = function(val)
		writeu8(buf, reserve(1), val and 1 or 0)
	end

	writer.cframe = function(val)
		local base = reserve(24)
		local x, y, z = val.X, val.Y, val.Z
		local rx, ry, rz = val:ToEulerAngles()
		writef32(buf, base, x)
		writef32(buf, base + 4, y)
		writef32(buf, base + 8, z)
		writef32(buf, base + 12, rx)
		writef32(buf, base + 16, ry)
		writef32(buf, base + 20, rz)
	end

	writer.vector3 = function(val)
		local base = reserve(12)
		writef32(buf, base, val.X)
		writef32(buf, base + 4, val.y)
		writef32(buf, base + 8, val.z)
	end

	-- Size should be restricted upstream
	writer.string = function(val)
		local s = #val
		local base = reserve(s + headerSize)
		writeHeader(buf, base, s)
		writeString(buf, base + headerSize, val, s)
	end

	writer.buffer = function(val)
		local s = len(val)
		local base = reserve(s + headerSize)
		writeHeader(buf, base, s)
		copy(buf, base + headerSize, val, 0, s)
	end

	return table.freeze(writer)
end

return new