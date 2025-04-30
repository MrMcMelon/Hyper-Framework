--!native
--!optimize 2

-- Buffers.luau
-- Creates a bufferspace allowing modules to use buffer types to write and read from buffers

export type Encode<T> = (T) -> ()
export type Decode<T> = () -> (T, number)

export type Type<T> = {
	id: number,
	encode: Encode<T>,
	decode: Decode<T>,
	size: number?
}

local Writer = require(script.Writer)
local Reader = require(script.Reader)

-- We use a range because we are trying to keep typeId within 255 so we can pack them in a single byte in other modules
-- (0 - 50 fixed sized types, 51 - 100 arrays, 101 - 200 structs, 201 - 235 maps, 236 - 255 non-fixed-size types)
local arrayIdRange = NumberRange.new(51, 100)
local structIdRange = NumberRange.new(101, 200)

-- Helper method to create array structure for a bufferspace
local function newArray(register: (id: number, e: Encode<any>, d: Decode<any>, s: number?) -> any, get: (id: number) -> Type<any>?, writer: Writer.Writer, reader: Reader.Reader)
	local counter = arrayIdRange.Min
	local cache = {}
	local writeu16 = writer.u16
	local readu16 = reader.u16
	local max = arrayIdRange.Max

	return function<T>(givenId: T): {T}
		-- We convert the type casted number id back to a number
		local id: number = givenId:: any

		if cache[id] then
			return cache[id]
		end

		local arrayId = counter
		counter += 1
		if counter > max then
			error("Array id counter overflow.")
		end

		local baseType = get(id)
		if not baseType then
			error("Unknown type passed, failed to create array-type")
		end
		local typeEncode = baseType.encode
		local typeDecode = baseType.decode

		local encode: Encode<{T}>
		local decode: Decode<{T}>

		encode = function(val)
			writeu16(#val)
			for _, v in val do
				typeEncode(v)
			end
		end

		decode = function()
			local count = readu16()
			local t = {}
			local size = 0
			for i = 1, count do
				local val, fieldSize = typeDecode()
				t[i] = val
				size += fieldSize
			end
			return t, size
		end

		local arrayType = register(arrayId, encode, decode)
		cache[id] = arrayType
		return arrayType
	end
end

local function newStruct(register: (id: number, e: Encode<any>, d: Decode<any>, s: number?) -> any, get: (id: number) -> Type<any>?)
	local counter = structIdRange.Min
	local max = structIdRange.Max
	local cache = {}

	return function<T>(struct: T): T
		local structId = counter
		counter += 1
		if counter > max then
			error("Struct id counter overflow.")
		end

		if typeof(struct) ~= "table" then
			error("Struct must be of table type.")
		end

		-- To avoid an runtime mutations
		table.freeze(struct)

		local keys = {}
		for key, _ in struct do
			if typeof(key) ~= "string" then
				error("Structs cannot contain non string keys")
			end
			table.insert(keys, key)
		end
		
		table.sort(keys)
		local hash = table.concat(keys)
		if cache[hash] then
			return cache[hash]
		end		

		local encoders = {}
		local decoders = {}
		for i, key in keys do
			local id: number = struct[key]:: any
			local baseType = get(id)
			if not baseType then
				error("Struct contains unknown type, failed to create struct-type")
			end
			encoders[i] = baseType.encode
			decoders[i] = baseType.decode
		end

		local encode: Encode<T>
		local decode: Decode<T>
		local count = #keys

		encode = function(val)
			-- numerical for loop is faster than doing for i, key in key do encode = encoders[key] end
			for i = 1, count do
				local key = keys[i]
				local baseEncode = encoders[i]
				baseEncode(val[key])
			end
		end

		decode = function()
			local t = {}
			local size = 0
			for i = 1, count do
				local baseDecode = decoders[i]
				local val, fieldSize = baseDecode()
				size += fieldSize
				t[keys[i]] = val
			end
			return t, size
		end

		local structType = register(structId, encode, decode)
		cache[hash] = struct
		return structType
	end
end

-- Creates a buffer-space (Buffer types with unique writer & reader so each module can manage its own read/write queue)
local function new()
	local writer = Writer(128, 2)
	local reader = Reader()

	local collection: { [number]: Type<any> } = {}

	local function register<T>(id: number, e: Encode<T>, d: Decode<T>, s: number?): T
		local t: Type<T> = {
			id = id,
			encode = e,
			decode = d,
			size = s,
		}
		collection[id] = t
		-- We trick the type system into thinking id = type so we can pass these ids as arguments to functions and get type inference
		return (id :: any) :: T
	end

	local function get(id: any)
		return collection[id]
	end

	local array = newArray(register, get, writer, reader)
	local struct = newStruct(register, get)

	-- Native Types
	local types = {
		u8       = register(1, writer.u8,       reader.u8,       1),
		u16      = register(2, writer.u16,      reader.u16,      2),
		u32      = register(3, writer.u32,      reader.u32,      4),
		i8       = register(4, writer.i8,       reader.i8,       1),
		i16      = register(5, writer.i16,      reader.i16,      2),
		i32      = register(6, writer.i32,      reader.i32,      4),
		f32      = register(7, writer.f32,      reader.f32,      4),
		f64      = register(8, writer.f64,      reader.f64,      8),
		boolean  = register(9, writer.boolean,  reader.boolean,  1),
		cframe   = register(10, writer.cframe,  reader.cframe,  24),
		vector3  = register(11, writer.vector3, reader.vector3, 12),

		-- Dynamic sized types
		string   = register(254, writer.string,  reader.string),
		buffer   = register(255, writer.buffer,  reader.buffer),

		-- Abstract type factories
		array = array,
		struct = struct,
	}

	-- Abstract types
	types.test = struct{
		hello = types.string,
		cool = types.boolean,
	}

	return table.freeze(types), get, writer, reader
end


return new


