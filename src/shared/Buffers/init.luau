--!strict
--!native
--!optimize 2

-- Buffers.luau
-- Creates a bufferspace that contains a writer, reader and bunch of types

local Writer = require(script.Writer)
local Reader = require(script.Reader)

export type BufferType<T> = {
    id: number,
    encode: (T) -> (),
    decode: () -> (T, number)
}

export type BufferSpace = {
    uint8: number,
    uint16: number,
    uint32: number,
    int8: number,
    int16: number,
    int32: number,
    float32: number,
    float64: number,
    
    string: string,
    buffer: any,

	boolean: boolean,
    cframe: CFrame,
    vector2: Vector2,
    vector3: Vector3,
    vector2int16: Vector2int16,
    vector3int16: Vector3int16,
    udim: UDim,
    udim2: UDim2,
    color3: Color3,
    brickColor: BrickColor,
    numberRange: NumberRange,
    tweenInfo: TweenInfo,
    ray: Ray,
    region3: Region3,
    region3int16: Region3int16,
    numberSequenceKeypoint: NumberSequenceKeypoint,
    colorSequenceKeypoint: ColorSequenceKeypoint,
    rect: Rect,
    numberSequence: NumberSequence,
    colorSequence: ColorSequence,
    physicalProperties: PhysicalProperties,

	array: <T>(bufferTypeId: T) -> {T},
	struct: <T>(template: T) -> T,
}

-- We try to keep type id between 0 and 255 so we can encode them as uint8
local arrayRange = NumberRange.new(51, 100) -- Enough for 1 array a type
local structRange = NumberRange.new(101, 255) -- Rests of the ids are allocated to structs

local function nullEncode()
		
end

local function nullDecode()
	
	return nil, 0
end

return function(defaultSize: number, scale: number)
    local writer, reader = Writer(defaultSize, scale), Reader()
    local cache: { [number]: BufferType<any> } = {}

	local writeu16 = writer.u16
	local readu16 = reader.u16

    local function registerType<T>(id: number, encode: (T) -> (), decode: () -> (T, number)): T
        if cache[id] then
            error("Attempted to create 2 types with same id in the same bufferspace.")
        end
        cache[id] = { id = id, encode = encode, decode = decode }
        return (id :: any) :: T
    end

	local arrayCache: {[number]: BufferType<{any}>} = {}
	local arrayCount = arrayRange.Min
	local function array<T>(typeId: T): {T}
		local id: number = typeId:: any
		if arrayCache[id] then
			return (arrayCache[id].id:: any):: {T}
		end

		if arrayCount > arrayRange.Max then
			error("Array id counter overflow")
		end
		local arrayId = arrayCount
		arrayCount += 1

		local bufferType = cache[id]
		if not bufferType then
			error("Invalid buffer type passed for array creation")
		end
		local encode, decode = bufferType.encode, bufferType.decode

		local function arrayEncode(vals: {T})
			local count = #vals
			writeu16(count)
			for i = 1, count do
				encode(vals[i])
			end
		end

		local function arrayDecode(): ({T}, number)
			local count = readu16()
			local vals = {}
			local arraySize = 0
			for i = 1, count do
				local val, size = decode()
				vals[i] = val
				arraySize += size
			end
			return vals, arraySize
		end

		local arrayType = registerType(arrayId, arrayEncode, arrayDecode)
		arrayCache[arrayId] = (arrayType:: any):: BufferType<{T}>
		return arrayType
	end

	local structCache: {[string]: BufferType<any>} = {}
	local structCount = structRange.Min
	local function struct<T>(template: T): T
		if typeof(template) ~= "table" then
			error("Struct template must be a table")
		end

		local keys = {}
		for key, _ in template do
			if typeof(key) ~= "string" then
				error("Struct keys must be a string")
			end
			table.insert(keys, key)
		end
		table.sort(keys)

		local hash = ""

		local encoders, decoders = {}, {}
		local count = #keys
		for i = 1, count do
			local key = keys[i]
			local typeId: number = template[key]:: number
			local bufferType = cache[typeId:: number]
			if not bufferType then
				error("Struct template contains invalid type")
			end
			hash = hash..key.."="..typeId.."/"
			encoders[i], decoders[i] = bufferType.encode, bufferType.decode
		end

		if structCache[hash] then return (structCache[hash].id:: any):: T end

		local structId = structCount
		structCount += 1
		if structCount > structRange.Max then
			error("Struct id counter overflow")
		end

		local function structEncode(val: T)
			for i = 1, count do
				local key = keys[i]
				encoders[i]((val:: any)[key])
			end
		end

		local function structDecode()
			local structSize = 0
			local structVal: any = {}
			for i = 1, count do
				local key = keys[i]
				local val, size = decoders[i]()
				structVal[key] = val
				structSize += size
			end
			return structVal:: T, structSize
		end

		local structType = registerType(structId, structEncode, structDecode)
		structCache[hash] = (structType:: any):: BufferType<T>
		return structType
	end

	local function fetch<T>(typeId: T): BufferType<T>?
		local id: number = typeId:: any
		return cache[id]
	end

	

	local bufferSpace: BufferSpace = {
		null					= registerType(0, nullEncode, nullDecode),
        uint8                   = registerType(1, writer.u8,      reader.u8),
        uint16                  = registerType(2, writer.u16,     reader.u16),
        uint32                  = registerType(3, writer.u32,     reader.u32),
        int8                    = registerType(4, writer.i8,      reader.i8),
        int16                   = registerType(5, writer.i16,     reader.i16),
        int32                   = registerType(6, writer.i32,     reader.i32),
        float32                 = registerType(7, writer.f32,     reader.f32),
        float64                 = registerType(8, writer.f64,     reader.f64),
    
        string                  = registerType(10, writer.string, reader.string),
        buffer                  = registerType(11, writer.buffer, reader.buffer),

		boolean                 = registerType(9, writer.boolean, reader.boolean),
        cframe                  = registerType(12, writer.cframe, reader.cframe),
        vector2                 = registerType(13, writer.vector2, reader.vector2),
        vector3                 = registerType(14, writer.vector3, reader.vector3),
        vector2int16            = registerType(15, writer.vector2int16, reader.vector2int16),
        vector3int16            = registerType(16, writer.vector3int16, reader.vector3int16),
        udim                    = registerType(17, writer.udim,    reader.udim),
        udim2                   = registerType(18, writer.udim2,   reader.udim2),
        color3                  = registerType(19, writer.color3,  reader.color3),
        brickColor              = registerType(20, writer.brickColor, reader.brickColor),
        numberRange             = registerType(21, writer.numberRange, reader.numberRange),
        tweenInfo               = registerType(22, writer.tweenInfo, reader.tweenInfo),
        ray                     = registerType(23, writer.ray, reader.ray),
        region3                 = registerType(24, writer.region3, reader.region3),
        region3int16            = registerType(25, writer.region3int16, reader.region3int16),
        numberSequenceKeypoint  = registerType(26, writer.numberSequenceKeypoint, reader.numberSequenceKeypoint),
        colorSequenceKeypoint   = registerType(27, writer.colorSequenceKeypoint, reader.colorSequenceKeypoint),
        rect                    = registerType(28, writer.rect, reader.rect),
        numberSequence          = registerType(29, writer.numberSequence, reader.numberSequence),
        colorSequence           = registerType(30, writer.colorSequence, reader.colorSequence),
        physicalProperties      = registerType(31, writer.physicalProperties, reader.physicalProperties),

		array = array,
		struct = struct,
    }

    return table.freeze(bufferSpace), fetch, writer, reader
end
