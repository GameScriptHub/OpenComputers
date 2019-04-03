local DRConf = require("drlib")
local DRLib = {}

function DRLib.getTotalRF(strength, purity)
	return 1000.0 * DRConf.maximumKiloRF * strength / 100.0 * (purity + 30.0) / 130.0
end

function DRLib.getRfPerTick(efficiency, purity)
	return math.floor(DRConf.maximumRFPerTick * efficiency / 100.1 * (purity + 2.0) / 102.0 + 1)
end

function DRLib.getNumTicks(totalRF, rfPerTick)
	return totalRF / rfPerTick
end

function DRLib.getPowerPerTick(totalRF, rfPerTick)
	return 100 / DRLib.getNumTicks(totalRF, rfPerTick)
end

function DRLib.getRemainingTicks(power, totalRF, rfPerTick)
	return DRLib.getNumTicks() * (power / 100)
end

function DRLib.getRemainingSeconds(power, totalRF, rfPerTick)
	return (DRLib.getNumTicks() * (power / 100)) / 20
end

function DRLib.findPedestals()
	local allComponents = component.list()
	local pedestals = {}

	for k,v in pairs(allComponents) do
	  if v == "deepresonance_pedastal" then
	  	local ped = component.proxy(k)

	    table.insert(pedestals, ped)
	  end
	end

	return pedestals
end

return DRLib
