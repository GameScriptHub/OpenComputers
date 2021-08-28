local c = require("component")
local a = { ... }

if #a >= 1 and string.lower(a[1]) == "help" then
  print("cinfoplus [component filter]")
  print()
  print("Example 1 (no filter):                cinfoplus")
  print("Example 2 (component name filter):    cinfoplus me_controller")
  print("Example 4 (component address filter): cinfoplus f07b3df0")
end

for address, type in c.list() do
  if #a == 0 or (string.lower(address):find(string.lower(a[1])) ~= nil or string.lower(type):find(string.lower(a[1])) ~= nil) then
    local proxy = c.proxy(address)
    print("== " .. string.upper(type) .. " : " .. address .. " ==")

    for a,b in pairs(proxy) do
      print("  -> " .. a .. " - " .. tostring(b))
    end

    print()
  end
end
