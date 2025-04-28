-- LinkedListBenchmark.lua
-- Run with Luau (e.g. `luau LinkedListBenchmark.lua`)

local List = require(game.ReplicatedStorage.HyperShared.DataStructures.LinkedList)  -- adjust require path as needed

-- Simple timer helper
local function timeit(name, fn)
    local t0 = os.clock()
    fn()
    local t1 = os.clock()
    print(string.format("%-30s: %.16f s", name, t1 - t0))
end

-- Benchmark sizes and repetitions
local sizes   = {1e2, 1e3, 1e4}
local repeats = 1

for _, n in ipairs(sizes) do
    print(("\n=== Size: %d ==="):format(n))

    ----------------------------------------------------------------
    -- Table operations: REMOVE ONLY
    ----------------------------------------------------------------

    for rep = 1, repeats do
        -- Prepare once per repeat
        local t = {}
        for i = 1, n do t[#t+1] = i end

        timeit(("Table: t[#t] = nil  (rep %d)"):format(rep), function()
            for i = 1, n do
                t[#t] = nil
            end
        end)
    end

    for rep = 1, repeats do
        local t = {}
        for i = 1, n do t[#t+1] = i end

        timeit(("Table: table.remove(t,1)  (rep %d)"):format(rep), function()
            for i = 1, n do
                table.remove(t, 1)
            end
        end)
    end

    ----------------------------------------------------------------
    -- LinkedList operations: REMOVE / SHIFT / UNSHIFT ONLY
    ----------------------------------------------------------------

    -- pop() only
    for rep = 1, repeats do
        local lst = List.new()
        for i = 1, n do lst:push(i) end

        timeit(("List: pop()  (rep %d)"):format(rep), function()
            for i = 1, n do
                lst:pop()
            end
        end)
    end

    -- shift() only
    for rep = 1, repeats do
        local lst = List.new()
        for i = 1, n do lst:unshift(i) end

        timeit(("List: shift()  (rep %d)"):format(rep), function()
            for i = 1, n do
                lst:shift()
            end
        end)
    end

    ----------------------------------------------------------------
    -- LinkedList operations: INSERT ONLY (push/unshift)
    ----------------------------------------------------------------

    for rep = 1, repeats do
        local lst = List.new()
        timeit(("List: push(val)  (rep %d)"):format(rep), function()
            for i = 1, n do
                lst:push(i)
            end
        end)
    end

    for rep = 1, repeats do
        local lst = List.new()
        timeit(("List: unshift(val)  (rep %d)"):format(rep), function()
            for i = 1, n do
                lst:unshift(i)
            end
        end)
    end

    ----------------------------------------------------------------
    -- Node destruction only
    ----------------------------------------------------------------

    for rep = 1, repeats do
        local lst = List.new()
        local cache = {}

        -- Build & cache nodes _before_ timing
        for i = 1, n do
            cache[i] = lst:push(i)
        end

        timeit(("List: node:destroy()  (rep %d)"):format(rep), function()
            for i = 1, n do
                cache[i]:destroy()
            end
        end)
    end
end

return 0