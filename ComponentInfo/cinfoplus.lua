local c = require("component")

for address, type in c.list() do
  local proxy = c.proxy(address)
  print("== " .. string.upper(type) .. " : " .. address .. " ==")

  for a,b in pairs(proxy) do
    print("  -> " .. a)
  end

  print()
end
