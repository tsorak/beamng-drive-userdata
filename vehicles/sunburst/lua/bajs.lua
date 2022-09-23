
local M = {}

local tc
local airspeed
local e

local function onReset()
    tc = powertrain.getDevice("torqueConverter") or {}
    e = electrics.values

    if not tc then
        updateGFX = nil
    end
end

local function updateGFX(dt) -- ms
    airspeed = e.airspeed * 3.6

    tc.stallTorqueRatio = 1 + airspeed*0
end

-- public interface
M.onInit    = onReset
M.onReset   = onReset
M.updateGFX = updateGFX

return M