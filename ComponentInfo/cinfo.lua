local shell = require("shell")
local comp = require("component")
local args, options = shell.parse(...)

if #args == 0 then error("Please provide an address") end

local addr = args[1]
local addrFull = comp.get(addr)

if addrFull == nil then error("Address not found") end

local proxy = comp.proxy(addrFull)

if proxy == nil then error("Failed to proxy component at address " .. addrFull) end

print("Full Address: " .. addrFull)
print("Component Type: " .. proxy.type)
print("Functions:")

for k,v in pairs(proxy) do
  if tostring(v) == "function" then
    print("-> " .. k)
  end
end
