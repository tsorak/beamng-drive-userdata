local M = {}
local tc
local eng
local airspeed
local e
local yawrate
local RWDuntilGripLoss
local speedDiff
local snedism
local yawSmooth

local function onReset(jbeamData)
    tc = powertrain.getDevice("transfercase") or {}
    eng = powertrain.getDevice("mainEngine") or {}
    -- e = electrics.values
    if jbeamData.RWDuntilGripLoss ~= nil and jbeamData.RWDuntilGripLoss == 0 then
        RWDuntilGripLoss = false
    else
        RWDuntilGripLoss = true
    end
    print(RWDuntilGripLoss)

    yawSmooth = newExponentialSmoothing(10)

    if not tc then
        updateGFX = nil
    end
end

local function updateGFX(dt) -- ms
    local torqueRear
    if(powertrain.getDevice("spindleFL").wheel ~= nil and powertrain.getDevice("spindleFR").wheel ~= nil and powertrain.getDevice("wheelaxleRL").wheel ~= nil and powertrain.getDevice("wheelaxleRR").wheel ~= nil) then
        local wheelSpeedFront = (powertrain.getDevice("spindleFL").wheel.wheelSpeed + powertrain.getDevice("spindleFR").wheel.wheelSpeed) / 2
        local wheelSpeedRear = (powertrain.getDevice("wheelaxleRL").wheel.wheelSpeed + powertrain.getDevice("wheelaxleRR").wheel.wheelSpeed) / 2

        if (wheelSpeedFront/wheelSpeedRear) < 0.975 and RWDuntilGripLoss then
            torqueRear = math.max(math.min(wheelSpeedFront/wheelSpeedRear, 1), 0.33)
        elseif (wheelSpeedRear/wheelSpeedFront) < 0.975 and not RWDuntilGripLoss then
            torqueRear = math.max(math.min(wheelSpeedRear/wheelSpeedFront, 1), 0.33)
        else
            torqueRear = 1
        end
        -- print("xd")
    end
    -- print("xd")

    snedism = math.min(math.max(((string.format("%0.2f", yawSmooth:get(-obj:getYawAngularVelocity()))^2)^0.5),0.00),1)
    
    if RWDuntilGripLoss then
        if torqueRear ~= nil then
            tc.diffTorqueSplitA = torqueRear - snedism
        else
            tc.diffTorqueSplitA = 1
        end
    
        if electrics.values.parkingbrake == 1 then
            tc.diffTorqueSplitA = 0
        end
    
        tc.diffTorqueSplitB = 1.0 - tc.diffTorqueSplitA
    else
        if torqueRear ~= nil then
            tc.diffTorqueSplitB = torqueRear
        else
            tc.diffTorqueSplitB = 1
        end
    
        if electrics.values.parkingbrake == 1 then
            tc.diffTorqueSplitB = 1
        end
    
        tc.diffTorqueSplitA = 1.0 - tc.diffTorqueSplitB
    end
    
    speedDiff = math.max(math.min((electrics.values.airspeed/electrics.values.wheelspeed),0.9),0.85)^1 + 0.1
    tc.diffTorqueSplitB = tc.diffTorqueSplitB * speedDiff
    tc.diffTorqueSplitA = tc.diffTorqueSplitA * speedDiff

    print(speedDiff)
    
    if electrics.values.signal_right_input == 1 then
        RWDuntilGripLoss = true
        electrics.toggle_right_signal()
    end
    if electrics.values.signal_left_input == 1 then
        RWDuntilGripLoss = false
        electrics.toggle_left_signal()
    end

    -- yawRate = obj:getYawAngularVelocity()
    obj.debugDrawProxy:drawText2D(float3(40,200,0), color(0,125,0,255), "Yawrate: " .. snedism)
    if RWDuntilGripLoss then
        obj.debugDrawProxy:drawText2D(float3(40,215,0), color(0,125,0,255), "Mode: RWD")
    else
        obj.debugDrawProxy:drawText2D(float3(40,215,0), color(0,125,0,255), "Mode: FWD")
    end
    if electrics.values.rpm > (eng.maxRPM-500) then
        obj.debugDrawProxy:drawText2D(float3(950,600,0), color(125,0,0,255), electrics.values.gear)
    elseif electrics.values.rpm > (eng.maxRPM-2500) then
        obj.debugDrawProxy:drawText2D(float3(950,600,0), color(125,125,0,255), electrics.values.gear)
    else
        obj.debugDrawProxy:drawText2D(float3(950,600,0), color(0,125,0,255), electrics.values.gear)
    end

end

-- public interface
M.init    = onReset
M.onReset   = onReset
M.updateGFX = updateGFX

return M