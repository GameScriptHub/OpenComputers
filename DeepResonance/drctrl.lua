--[[
    Deep Resonance Controller

    Author:  Enrico Ludwig
    Created: 01.04.2019
    Updated: 01.04.2019
]]

local component = require("component")
local keyboard = require("keyboard")
local term = require("term")

local DRLib = require("drlib")
local DRConf = loadfile("/etc/drconf.lua")

--------------------------
-- CONFIGURATION VALUES --
--------------------------

-- Minimum amount of energy in percent until the generator will be activated
local activateAt = 0.25
-- Minimum amount of energy in percent until the generator will be deactivated
local deactivateAt = 0.99

---------------------
-- INTERNAL FIELDS --
---------------------

-- Name of the script
local sName = "Deep Resonance Controller"
-- Version of the script
local sVersion = "0.01a"
-- Full headline
local sHeadline = sName .. " - " .. sVersion


-- The address of the connected Deep Resonance generator (it doesn't matter on which block the adapter is attached)
local generatorAddress = nil
-- The address of the connected Redstone I/O block that has to attached to the Generator Controller block
local redstoneIOAddress = nil
-- The proxied generator object
local generatorProxy = nil
-- The proxied Redstone I/O object
local redstoneProxy = nil
-- Connected pedestals
local pedestals = {}
-- Determines if the script is running
local running = true
-- Maximum energy that can be stored in the generator
local maxEnergy = 0
-- Current energy that is stored in the generator
local curEnergy = 0
-- Amount of energy on last tick
local lastEnergy = 0
-- The difference between the energy we had at the last tick and now
local energyDiff = 0
-- Current stored energy percentage
local percEnergy = 0.0
-- The status will be true, if the generator is enabled and false otherwise
local status = false
-- If set to true the generator will be force enabled
local forceOverride = false
-- If set to true the generator won't go in recharge mode (Discharge Only Mode)
local forceDischarge = false
-- The viewport of the terminal
local vWidth, vHeight = term.getViewport()

------------------------
-- INTERNAL FUNCTIONS --
------------------------

function init()
  pedestals = DRLib.findPedestals()
end

function writeCentered(str)
  if (str == nil or string.len(str) == 0) then
    return
  end

  term.clearLine()

  -- Headline
  local sw = vWidth - string.len(str)
  local shw = math.floor(sw / 2)

  -- Left spacing, headline, right spacing
  term.write(string.rep(" ", shw))
  term.write(str)
  term.write(string.rep(" ", shw))
end

function writeProgressBar(label, progress, displayPercentage, spacingBeforeBar)
    term.clearLine()

    local percStr = string.format("%02d", math.floor(percEnergy * 100)) .. "%"

    if type(displayPercentage) ~= "boolean" then
        displayPercentage = false
    end

    if type(spacingBeforeBar) ~= "number" then
        spacingBeforeBar = 0
    end

    local fullLabel = label .. ": " .. string.rep(" ", spacingBeforeBar)
    local pbTotalSpace = vWidth - string.len(fullLabel)
    if displayPercentage then
        pbTotalSpace = pbTotalSpace - 6
    end

    local pbBarSpace = pbTotalSpace - 2
    local pbUsedSpace = math.floor(pbBarSpace * progress)
    local pbUnusedSpace = math.floor(pbBarSpace - pbUsedSpace)

    term.write(fullLabel)   -- Label
    term.write("[")         -- ProgressBar start
    term.write(string.rep("|", math.floor(pbUsedSpace)))  -- Filled ProgressBar line
    term.write(string.rep(" ", math.floor(pbUnusedSpace)))  -- Unfilled ProgressBar line
    term.write("]")         -- ProgressBar end

    local cx, cy = term.getCursor()
    term.setCursor(cx + 1, cy)

    if displayPercentage then
        term.write(percStr)
    end
end

function printStats()
    term.clear()

    -- Headline
    writeCentered(sHeadline)

    -- Move down a bit
    term.setCursor(1, 3)

    if forceDischarge then
        term.write("Mode:         " .. "Force Discharging")
    elseif forceOverride then
        term.write("Mode:         " .. "Force Recharging")
    elseif status then
        term.write("Mode:         " .. "Normal Recharging")
    else
        term.write("Mode:         " .. "Normal Discharging")
    end

    -- Move down a bit
    term.setCursor(1, 4)

    -- Energy ProgressBar
    writeProgressBar("Energy", percEnergy, true, 6)

    -- Move down a bit
    term.setCursor(1, 5)

    -- Display recharge at marker
    term.write("Recharge at:  " .. math.floor(activateAt * 100) .. "%")

    -- Move down a bit
    term.setCursor(1, 6)

    -- Display discharge at marker
    term.write("Discharge at: " .. math.floor(deactivateAt * 100) .. "%")

    -- Energy I/O
    -- term.write("Energy I/O: " .. math.floor(energyDiff) .. " RF/t")

    -- Footer information
    term.setCursor(1, vHeight - 1)
    writeCentered("[Q] Quit | [F] Toggle Force Recharge Mode | [D] Toggle Discharge Mode")
    term.setCursor(1, vHeight)
    writeCentered("Max Energy Storage: " .. math.floor(maxEnergy) .. " RF | Current Energy Storage: " .. math.floor(curEnergy) .. " RF")
end

----------
-- CORE --
----------

if term ~= nil then
    term.setCursorBlink(false)
end

-- Get full generator address
generatorAddress = component.get(DRConf.generatorAddress)

-- Get full Redstone I/O address
redstoneIOAddress = component.get(DRConf.redstoneIOAddress)

-- Validate the generator address
if generatorAddress == nil then
    error("Address of the generator seems to be invalid")
else
    generatorProxy = component.proxy(generatorAddress)
end

-- Validate the Redstone I/O address
if redstoneIOAddress == nil then
    error("Address of the Redstone I/O block seems to be invalid")
else
    redstoneProxy = component.proxy(redstoneIOAddress)
end

if generatorProxy == nil then
    error("No generator found with address " .. generatorAddress)
end

if redstoneProxy == nil then
    error("No Redstone I/O block found with address " .. redstoneIOAddress)
end

-- Validate that we got all required methods for the Generator
if (generatorProxy["getEnergyStored"] == nil or generatorProxy["getMaxEnergyStored"] == nil) then
    error("Linked block doesn't seems to be a Deep Resonance generator")
end

-- Validate that we got all required methods for the Redstone I/O block
if redstoneProxy["setOutput"] == nil then
    error("Linked block doesn't seems to be a Redstone I/O block")
end

-- Core loop
while running do
  lastEnergy = curEnergy

  maxEnergy = generatorProxy.getMaxEnergyStored()
  curEnergy = generatorProxy.getEnergyStored()

  energyDiff = curEnergy - lastEnergy

  -- Calculate energy percentage
  if (curEnergy == 0 or maxEnergy == 0) then
    percEnergy = 0.0
  else 
    percEnergy = curEnergy / maxEnergy
  end

  -- Set recharge / discharge status
  if percEnergy < activateAt then
    status = true
  elseif percEnergy > deactivateAt then
    status = false
  end

  -- Fetch force recharge toggle hotkey
  if (keyboard ~= nil and keyboard.isKeyDown(keyboard.keys.f)) then
    forceOverride = not forceOverride
  end

  -- Fetch force lock toggle hotkey
  if (keyboard ~= nil and keyboard.isKeyDown(keyboard.keys.d)) then
    forceDischarge = not forceDischarge
  end

  -- Enable / disable redstone signal based on status
  if (not forceDischarge and (forceOverride or status)) then
    redstoneProxy.setOutput({
        15, 15, 15, 15, 15, 15
    })
  else
    redstoneProxy.setOutput({
        0, 0, 0, 0, 0, 0
    })
  end

  -- Fetch exit hotkey
  if (keyboard ~= nil and keyboard.isKeyDown(keyboard.keys.q)) then
    os.exit()
  end

  if term ~= nil then
    printStats()
  end

  os.sleep(1 / 20) -- Sleep to match a tick
end
