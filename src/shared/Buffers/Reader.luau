--!strict
--!native
--!optimize 2

local readu8, readu16, readu32 = buffer.readu8, buffer.readu16, buffer.readu32
local readi8, readi16, readi32 = buffer.readi8, buffer.readi16, buffer.readi32
local readf32, readf64 = buffer.readf32, buffer.readf64
local readstr = buffer.readstring
local create = buffer.create
local copy = buffer.copy


local CFrame_new, CFrame_Angles = CFrame.new, CFrame.Angles
local Vector3_new, Vector2_new = Vector3.new, Vector2.new
local Vector3int16_new, Vector2int16_new = Vector3int16.new, Vector2int16.new
local Color3_fromRGB = Color3.fromRGB
local BrickColor_new = BrickColor.new
local NumberRange_new = NumberRange.new
local UDim_new, UDim2_new = UDim.new, UDim2.new
local TweenInfo_new = TweenInfo.new
local EasingStyle= Enum.EasingStyle:: any
local EasingDirection= Enum.EasingDirection:: any
local Ray_new = Ray.new
local Region3_new = Region3.new
local Region3int16_new = Region3int16.new
local NumberSequenceKeypoint_new = NumberSequenceKeypoint.new
local ColorSequenceKeypoint_new = ColorSequenceKeypoint.new
local Rect_new = Rect.new
local NumberSequence_new = NumberSequence.new
local ColorSequence_new = ColorSequence.new

-- Closure-based Reader
local function new()
    local _buf
    local _cursor = 0

    local function push(buf)
        _buf = buf
        _cursor = 0
    end

    local function u8()
        local c = _cursor
        local v = readu8(_buf, c)
        _cursor = c + 1
        return v, 1
    end
    local function u16()
        local c = _cursor
        local v = readu16(_buf, c)
        _cursor = c + 2
        return v, 2
    end
    local function u32()
        local c = _cursor
        local v = readu32(_buf, c)
        _cursor = c + 4
        return v, 4
    end
    local function i8()
        local c = _cursor
        local v = readi8(_buf, c)
        _cursor = c + 1
        return v, 1
    end
    local function i16()
        local c = _cursor
        local v = readi16(_buf, c)
        _cursor = c + 2
        return v, 2
    end
    local function i32()
        local c = _cursor
        local v = readi32(_buf, c)
        _cursor = c + 4
        return v, 4
    end
    local function f32()
        local c = _cursor
        local v = readf32(_buf, c)
        _cursor = c + 4
        return v, 4
    end
    local function f64()
        local c = _cursor
        local v = readf64(_buf, c)
        _cursor = c + 8
        return v, 8
    end
    local function bufferReader()
        local c = _cursor
        local size = readu16(_buf, c)
        c = c + 2
        local newBuf = create(size)
        copy(newBuf, 0, _buf, c, size)
        _cursor = c + size
        return newBuf, size
    end
    local function stringReader()
        local c = _cursor
        local size = readu16(_buf, c)
        c = c + 2
        local s = readstr(_buf, c, size)
        _cursor = c + size
        return s, size
    end
    local function boolean()
        local c = _cursor
        local val = readu8(_buf, c) ~= 0
        _cursor = c + 1
        return val, 1
    end
    local function cframe()
        local c = _cursor
        local x = readf32(_buf, c)
        local y = readf32(_buf, c + 4)
        local z = readf32(_buf, c + 8)
        local rx = readf32(_buf, c + 12)
        local ry = readf32(_buf, c + 16)
        local rz = readf32(_buf, c + 20)
        _cursor = c + 24
        return CFrame_new(x, y, z) * CFrame_Angles(rx, ry, rz), 24
    end
    local function vector3()
        local c = _cursor
        local x = readf32(_buf, c)
        local y = readf32(_buf, c + 4)
        local z = readf32(_buf, c + 8)
        _cursor = c + 12
        return Vector3_new(x, y, z), 12
    end
    local function vector2()
        local c = _cursor
        local x = readf32(_buf, c)
        local y = readf32(_buf, c + 4)
        _cursor = c + 8
        return Vector2_new(x, y), 8
    end
    local function vector3int16()
        local c = _cursor
        local x = readi16(_buf, c)
        local y = readi16(_buf, c + 2)
        local z = readi16(_buf, c + 4)
        _cursor = c + 6
        return Vector3int16_new(x, y, z), 6
    end
    local function vector2int16()
        local c = _cursor
        local x = readi16(_buf, c)
        local y = readi16(_buf, c + 2)
        _cursor = c + 4
        return Vector2int16_new(x, y), 4
    end
    local function udim()
        local c = _cursor
        local scale = readu16(_buf, c)
        local offset = readi16(_buf, c + 2)
        _cursor = c + 4
        return UDim_new(scale / 65535, offset), 4
    end
    local function udim2()
        local c = _cursor
        local sx = readu16(_buf, c)
        local ox = readi16(_buf, c + 2)
        local sy = readu16(_buf, c + 4)
        local oy = readi16(_buf, c + 6)
        _cursor = c + 8
        return UDim2_new(sx / 65535, ox, sy / 65535, oy), 8
    end
    local function color3()
        local c = _cursor
        local r = readu8(_buf, c)
        local g = readu8(_buf, c + 1)
        local b = readu8(_buf, c + 2)
        _cursor = c + 3
        return Color3_fromRGB(r, g, b), 3
    end
    local function brickColor()
        local c = _cursor
        local v = readu8(_buf, c)
        _cursor = c + 1
        return BrickColor_new(v), 1
    end
    local function numberRange()
        local c = _cursor
        local mn = readf32(_buf, c)
        local mx = readf32(_buf, c + 4)
        _cursor = c + 8
        return NumberRange_new(mn, mx), 8
    end
    local function tweenInfo()
        local c = _cursor
        local t = readf32(_buf, c)
        local style = readu8(_buf, c + 4)
        local dir = readu8(_buf, c + 5)
        local repeats = readu16(_buf, c + 6)
        local revFlag = readu8(_buf, c + 8) ~= 0
        local delay = readf32(_buf, c + 9)
        _cursor = c + 13
        return TweenInfo_new(t, EasingStyle:FromValue(style), EasingDirection:FromValue(dir), repeats, revFlag, delay), 13
    end
    local function ray()
        local c = _cursor
        local ox = readf32(_buf, c)
        local oy = readf32(_buf, c + 4)
        local oz = readf32(_buf, c + 8)
        local dx = readf32(_buf, c + 12)
        local dy = readf32(_buf, c + 16)
        local dz = readf32(_buf, c + 20)
        _cursor = c + 24
        return Ray_new(Vector3_new(ox, oy, oz), Vector3_new(dx, dy, dz)), 24
    end
    local function region3()
        local c = _cursor
        local x1 = readf32(_buf, c)
        local y1 = readf32(_buf, c + 4)
        local z1 = readf32(_buf, c + 8)
        local x2 = readf32(_buf, c + 12)
        local y2 = readf32(_buf, c + 16)
        local z2 = readf32(_buf, c + 20)
        _cursor = c + 24
        return Region3_new(Vector3_new(x1, y1, z1), Vector3_new(x2, y2, z2)), 24
    end
    local function region3int16()
        local c = _cursor
        local x1 = readi16(_buf, c)
        local y1 = readi16(_buf, c + 2)
        local z1 = readi16(_buf, c + 4)
        local x2 = readi16(_buf, c + 6)
        local y2 = readi16(_buf, c + 8)
        local z2 = readi16(_buf, c + 10)
        _cursor = c + 12
        return Region3int16_new(Vector3int16_new(x1, y1, z1), Vector3int16_new(x2, y2, z2)), 12
    end
    local function numberSequenceKeypoint()
        local c = _cursor
        local t = readf32(_buf, c)
        local v = readf32(_buf, c + 4)
        local e = readf32(_buf, c + 8)
        _cursor = c + 12
        return NumberSequenceKeypoint_new(t, v, e), 12
    end
    local function colorSequenceKeypoint()
        local c = _cursor
        local t = readf32(_buf, c)
        local r = readu8(_buf, c + 4)
        local g = readu8(_buf, c + 5)
        local b = readu8(_buf, c + 6)
        _cursor = c + 7
        return ColorSequenceKeypoint_new(t, Color3_fromRGB(r, g, b)), 7
    end
    local function rect()
        local c = _cursor
        local minX = readf32(_buf, c)
        local minY = readf32(_buf, c + 4)
        local maxX = readf32(_buf, c + 8)
        local maxY = readf32(_buf, c + 12)
        _cursor = c + 16
        return Rect_new(minX, minY, maxX, maxY), 16
    end
    local function numberSequence()
        local c0 = _cursor
        local count = readu8(_buf, c0)
        local points = {}
        _cursor += 1
        for i = 1, count do
            local t = readf32(_buf, _cursor)
            local v = readf32(_buf, _cursor + 4)
            local e = readf32(_buf, _cursor + 8)
            _cursor += 12
            points[i] = NumberSequenceKeypoint_new(t, v, e)
        end
        return NumberSequence_new(points), (_cursor - c0)
    end
    local function colorSequence()
        local c0 = _cursor
        local count = readu8(_buf, c0)
        local points = {}
        _cursor += 1
        for i = 1, count do
            local t = readf32(_buf, _cursor)
            local r = readu8(_buf, _cursor + 4)
            local g = readu8(_buf, _cursor + 5)
            local b = readu8(_buf, _cursor + 6)
            _cursor += 7
            points[i] = ColorSequenceKeypoint_new(t, Color3_fromRGB(r, g, b))
        end
        return ColorSequence_new(points), (_cursor - c0)
    end

    local function physicalProperties()
        local density         = readf32(_buf, _cursor)
        local friction        = readf32(_buf, _cursor + 4);
        local elasticity      = readf32(_buf, _cursor + 8);
        local frictionWeight  = readf32(_buf, _cursor + 12);
        local elasticityWeight= readf32(_buf, _cursor + 16);
        _cursor += 20
        return PhysicalProperties.new(
            density,
            friction,
            elasticity,
            frictionWeight,
            elasticityWeight
        ), 20
    end

    return {
        push                = push,
        u8                  = u8,
        u16                 = u16,
        u32                 = u32,
        i8                  = i8,
        i16                 = i16,
        i32                 = i32,
        f32                 = f32,
        f64                 = f64,
        buffer              = bufferReader,
        string              = stringReader,
        boolean             = boolean,
        cframe              = cframe,
        vector3             = vector3,
        vector2             = vector2,
        vector3int16        = vector3int16,
        vector2int16        = vector2int16,
        udim                = udim,
        udim2               = udim2,
        color3              = color3,
        brickColor          = brickColor,
        numberRange         = numberRange,
        tweenInfo           = tweenInfo,
        ray                 = ray,
        region3             = region3,
        region3int16        = region3int16,
        numberSequenceKeypoint = numberSequenceKeypoint,
        colorSequenceKeypoint  = colorSequenceKeypoint,
        rect                   = rect,
        numberSequence     = numberSequence,
        colorSequence      = colorSequence,
        physicalProperties = physicalProperties,
    }
end

return new
