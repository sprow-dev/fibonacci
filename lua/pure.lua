-- This is written in pure Lua.
-- As such, it sucks at speed.
-- Run it and you'll see why we use C so much in the actual code.
local a, b = 0, 1
local f = io.open("fib.txt", "wb")
local start = os.time()

while os.difftime(os.time(), start) < 5 do
    a, b = b, a + b
    f:write(tostring(b) .. ",")
end
f:close()
