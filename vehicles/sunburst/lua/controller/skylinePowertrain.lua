local M = {}
local tc
local airspeed
local e
local yawrate

local function onReset()
    tc = powertrain.getDevice("transfercase") or {}
    -- e = electrics.values

    print("tc")

    if not tc then
        updateGFX = nil
    end
end

local function updateGFX(dt) -- ms
    local torqueRear
    if(powertrain.getDevice("spindleFL").wheel ~= nil and powertrain.getDevice("spindleFR").wheel ~= nil and powertrain.getDevice("spindleRL").wheel ~= nil and powertrain.getDevice("spindleRR").wheel ~= nil) then
        local wheelSpeedFront = (powertrain.getDevice("spindleFL").wheel.wheelSpeed + powertrain.getDevice("spindleFR").wheel.wheelSpeed) / 2
        local wheelSpeedRear = (powertrain.getDevice("spindleRL").wheel.wheelSpeed + powertrain.getDevice("spindleRR").wheel.wheelSpeed) / 2

        torqueRear = math.max(math.min(wheelSpeedFront/wheelSpeedRear, 1), 0.33)
        print(torqueRear)
        -- print("xd")
    end
    -- print("xd")
    
    
    -- yawRate = obj:getYawAngularVelocity()

    

    if torqueRear ~= nil then
        tc.diffTorqueSplitA = torqueRear
    else
        tc.diffTorqueSplitA = 1
    end

    tc.diffTorqueSplitB = 1.0 - tc.diffTorqueSplitA

end

-- public interface
M.init    = onReset
M.onReset   = onReset
M.updateGFX = updateGFX

return M