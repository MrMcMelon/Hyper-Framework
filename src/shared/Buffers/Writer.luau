--!strict
--!native
--!optimize 2

local create, copy = buffer.create, buffer.copy
local writeu8, writeu16, writeu32 = buffer.writeu8, buffer.writeu16, buffer.writeu32
local writei8, writei16, writei32 = buffer.writei8, buffer.writei16, buffer.writei32
local writef32, writef64 = buffer.writef32, buffer.writef64
local writeStr = buffer.writestring
local len = buffer.len

-- Closure-based Writer
local function new(defaultSize: number, scale: number)
    -- internal state
    local _buf = create(defaultSize)
    local _size = defaultSize
    local _scale = scale
    local _cursor = 0

    local function reserve(n: number)
        local start = _cursor
        local ending = _cursor + n
        if _size < ending then
            local newSize = math.max(_size * _scale, ending)
            local newBuf = create(newSize)
            copy(newBuf, 0, _buf, 0, _cursor)
            _buf = newBuf
            _size = newSize
        end
        _cursor = ending
        return start
    end

    local function pop()
        local result = _buf
        _buf = create(0)
        _size = 0
        _cursor = 0
        return result
    end

    -- primitive writers
    local function u8(value: number)
        local pos = reserve(1)
        writeu8(_buf, pos, value)
    end
    local function u16(value: number)
        local pos = reserve(2)
        writeu16(_buf, pos, value)
    end
    local function u32(value: number)
        local pos = reserve(4)
        writeu32(_buf, pos, value)
    end
    local function i8(value: number)
        local pos = reserve(1)
        writei8(_buf, pos, value)
    end
    local function i16(value: number)
        local pos = reserve(2)
        writei16(_buf, pos, value)
    end
    local function i32(value: number)
        local pos = reserve(4)
        writei32(_buf, pos, value)
    end
    local function f32(value: number)
        local pos = reserve(4)
        writef32(_buf, pos, value)
    end
    local function f64(value: number)
        local pos = reserve(8)
        writef64(_buf, pos, value)
    end
    local function boolean(value: boolean)
        local pos = reserve(1)
        writeu8(_buf, pos, value and 1 or 0)
    end

    -- complex writers
    local function bufferWriter(bufIn: buffer)
        local sizeIn = len(bufIn)
        local pos = reserve(2 + sizeIn)
        writeu16(_buf, pos, sizeIn)
        copy(_buf, pos + 2, bufIn, 0, sizeIn)
    end
    local function stringWriter(str: string)
        local sizeStr = #str
        local pos = reserve(2 + sizeStr)
        writeu16(_buf, pos, sizeStr)
        writeStr(_buf, pos + 2, str)
    end

    local function cframe(cf: CFrame)
        local pos = reserve(24)
        local p = cf.Position
        writef32(_buf, pos, p.X)
        writef32(_buf, pos+4, p.Y)
        writef32(_buf, pos+8, p.Z)
        local rx, ry, rz = cf:ToEulerAnglesXYZ()
        writef32(_buf, pos+12, rx)
        writef32(_buf, pos+16, ry)
        writef32(_buf, pos+20, rz)
    end
    local function vector3(vector: Vector3)
        local pos = reserve(12)
        writef32(_buf, pos, vector.X)
        writef32(_buf, pos+4, vector.Y)
        writef32(_buf, pos+8, vector.Z)
    end
    local function vector2(vector: Vector2)
        local pos = reserve(8)
        writef32(_buf, pos, vector.X)
        writef32(_buf, pos+4, vector.Y)
    end
    local function vector3int16(vector: Vector3int16)
        local pos = reserve(6)
        writei16(_buf, pos, vector.X)
        writei16(_buf, pos+2, vector.Y)
        writei16(_buf, pos+4, vector.Z)
    end
    local function vector2int16(vector: Vector2int16)
        local pos = reserve(4)
        writei16(_buf, pos, vector.X)
        writei16(_buf, pos+2, vector.Y)
    end
    local function color3(color: Color3)
        local pos = reserve(3)
		writeu8(_buf, pos, color.R * 255)
		writeu8(_buf, pos+1, color.G * 255)
		writeu8(_buf, pos+2, color.B * 255)
    end
    local function brickColor(brick: BrickColor)
        local pos = reserve(1)
        writeu8(_buf, pos, brick.Number)
    end
    local function numberRange(range: NumberRange)
        local pos = reserve(8)
        writef32(_buf, pos, range.Min)
        writef32(_buf, pos+4, range.Max)
    end
    local function udim(ud: UDim)
        local pos = reserve(4)
        writeu16(_buf, pos, ud.Scale * 65535)
        writei16(_buf, pos+2, ud.Offset)
    end
    local function udim2(ud2: UDim2)
        local pos = reserve(8)
        writeu16(_buf, pos, ud2.X.Scale * 65535)
        writei16(_buf, pos+2, ud2.X.Offset)
        writeu16(_buf, pos+4, ud2.Y.Scale * 65535)
        writei16(_buf, pos+6, ud2.Y.Offset)
    end
    local function tweenInfo(ti: TweenInfo)
        local pos = reserve(13)
        writef32(_buf, pos, ti.Time)
        writeu8(_buf, pos+4, ti.EasingStyle.Value)
        writeu8(_buf, pos+5, ti.EasingDirection.Value)
        writeu16(_buf, pos+6, ti.RepeatCount)
        writeu8(_buf, pos+8, ti.Reverses and 1 or 0)
        writef32(_buf, pos+9, ti.DelayTime)
    end
    local function physicalProperties(pp: PhysicalProperties)
        local pos = reserve(20)
        writef32(_buf, pos, pp.Density)
        writef32(_buf, pos+4, pp.Friction)
        writef32(_buf, pos+8, pp.Elasticity)
        writef32(_buf, pos+12, pp.FrictionWeight)
        writef32(_buf, pos+16, pp.ElasticityWeight)
    end
    local function ray(val: Ray)
        local pos = reserve(24)
        writef32(_buf, pos, val.Origin.X)
        writef32(_buf, pos+4, val.Origin.Y)
        writef32(_buf, pos+8, val.Origin.Z)
        writef32(_buf, pos+12, val.Direction.X)
        writef32(_buf, pos+16, val.Direction.Y)
        writef32(_buf, pos+20, val.Direction.Z)
    end
    local function region3(region: Region3)
        local pos = reserve(24)
        local c = region.CFrame
        local p1 = c.Position
        local p2 = p1 + region.Size
        writef32(_buf, pos, p1.X)
        writef32(_buf, pos+4, p1.Y)
        writef32(_buf, pos+8, p1.Z)
        writef32(_buf, pos+12, p2.X)
        writef32(_buf, pos+16, p2.Y)
        writef32(_buf, pos+20, p2.Z)
    end
    local function region3int16(region: Region3int16)
        local pos = reserve(12)
        local mn = region.Min
        local mx = region.Max
        writei16(_buf, pos, mn.X)
        writei16(_buf, pos+2, mn.Y)
        writei16(_buf, pos+4, mn.Z)
        writei16(_buf, pos+6, mx.X)
        writei16(_buf, pos+8, mx.Y)
        writei16(_buf, pos+10, mx.Z)
    end
    local function numberSequenceKeypoint(kp: NumberSequenceKeypoint)
        local pos = reserve(12)
        writef32(_buf, pos, kp.Time)
        writef32(_buf, pos+4, kp.Value)
        writef32(_buf, pos+8, kp.Envelope)
    end
    local function colorSequenceKeypoint(kp: ColorSequenceKeypoint)
        local pos = reserve(7)
        writef32(_buf, pos, kp.Time)
        writeu8(_buf, pos+4, kp.Value.R * 255)
        writeu8(_buf, pos+5, kp.Value.G * 255)
        writeu8(_buf, pos+6, kp.Value.B * 255)
    end
    local function rect(val: Rect)
        local pos = reserve(16)
        writef32(_buf, pos, val.Min.X)
        writef32(_buf, pos+4, val.Min.Y)
        writef32(_buf, pos+8, val.Max.X)
        writef32(_buf, pos+12, val.Max.Y)
    end
    local function numberSequence(ns: NumberSequence)
        local count = #ns.Keypoints
        local pos = reserve(1 + count * 12)
        writeu8(_buf, pos, count)
        for i, kp in ipairs(ns.Keypoints) do
            local off = pos + 1 + (i-1)*12
            writef32(_buf, off, kp.Time)
            writef32(_buf, off+4, kp.Value)
            writef32(_buf, off+8, kp.Envelope)
        end
    end
    local function colorSequence(cs: ColorSequence)
        local count = #cs.Keypoints
        local pos = reserve(1 + count * 7)
        writeu8(_buf, pos, count)
        for i, kp in ipairs(cs.Keypoints) do
            local off = pos + 1 + (i-1)*7
            writef32(_buf, off, kp.Time)
            writeu8(_buf, off+4, kp.Value.R)
            writeu8(_buf, off+5, kp.Value.G)
            writeu8(_buf, off+6, kp.Value.B)
        end
    end

    -- public API
    return {
        reserve = reserve,
        pop = pop,
        u8 = u8,
        u16 = u16,
        u32 = u32,
        i8 = i8,
        i16 = i16,
        i32 = i32,
        f32 = f32,
        f64 = f64,
        boolean = boolean,
        buffer = bufferWriter,
        string = stringWriter,
        cframe = cframe,
        vector3 = vector3,
        vector2 = vector2,
        vector3int16 = vector3int16,
        vector2int16 = vector2int16,
        color3 = color3,
        brickColor = brickColor,
        numberRange = numberRange,
        udim = udim,
        udim2 = udim2,
        tweenInfo = tweenInfo,
        physicalProperties = physicalProperties,
        ray = ray,
        region3 = region3,
        region3int16 = region3int16,
        numberSequenceKeypoint = numberSequenceKeypoint,
        colorSequenceKeypoint = colorSequenceKeypoint,
        rect = rect,
        numberSequence = numberSequence,
        colorSequence = colorSequence,
    }
end

return new
