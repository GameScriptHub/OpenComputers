local cs = component.list()
local pedestals = {}

for k,v in pairs(cs) do
  if v == "deepresonance_pedastal" then
    table.insert(pedestals, k)
  end
end

print("Found " .. #pedestals .. " connected pedestals")
print("") -- nl

for _, address in pairs(pedestals) do
  sAddress = string.sub(address, 1, 8)

  local ped = component.proxy(address)
  local present = ped.crystalPresent()

  if not present then
    print(address .. " = No Crystal present")
  else
    local purity = math.floor(ped.getPurity())
    local strength = math.floor(ped.getStrength())
    local efficiency = math.floor(ped.getEfficiency())
    local power = math.floor(ped.getPower())
    local output = math.floor(ped.getOutput())
    local inUse = ped.isInUse()

    print(sAddress .. " = " .. string.format("Pur @ %d%%, Str @ %d%%, Eff @ %d%%, Pow @ %d%%, Out @ %d RF", purity, strength, efficiency, purity, output))
  end
end