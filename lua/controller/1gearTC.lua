local M = {}
local tc
-- local eng

local function updateGFX(dt) -- ms
    local stallTR = 0.1 + (99 * input.throttle)
    tc.stallTorqueRatio = stallTR
end

local function onReset(jbeamData)
    -- eng = powertrain.getDevice("mainEngine") or {}
    
    if tc == nil then
        M.updateGFX = nil
    end

    print("1gearTC Loaded")
end

local function onInit(jbeamData)
    tc = powertrain.getDevice("torqueConverter") or nil
    onReset(jbeamData)
end

-- public interface
M.init      = onInit
M.onReset   = onReset
M.updateGFX = updateGFX

return M