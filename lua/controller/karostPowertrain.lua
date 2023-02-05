local M = {}
local tc
local eng
-- local RWDuntilGripLoss
local speedDiff
local snedism
local yawdir
local suggestedTorqueToRear
local yawSmooth
local wheelIDS = {
  FL = nil,
  FR = nil,
  RL = nil,
  RR = nil
}

local diffModes = {
  INPUT = "INPUT",
  RAW = "RAW",
  RWD = "RWD",
  FWD = "FWD",
  FIFTYFIFTY = "5050",
  DEFAULT = "DEFAULT"
}
local diffMode
local diffModeIndex
local defaultSplitA

local function updateGFX(dt) -- ms
  -- local torqueRear
  -- if(wheels.FL ~= nil and wheels.FR ~= nil and wheels.RL ~= nil and wheels.RR ~= nil) then
  --     local wheelSpeedFront = (wheels.FL.wheel.wheelSpeed + wheels.FR.wheel.wheelSpeed) / 2
  --     local wheelSpeedRear = (wheels.RL.wheel.wheelSpeed + wheels.RR.wheel.wheelSpeed) / 2

  --     if (wheelSpeedFront/wheelSpeedRear) < 0.975 and RWDuntilGripLoss then
  --         torqueRear = math.max(math.min(math.floor(wheelSpeedFront/wheelSpeedRear*100)/100, 1), 0.33)
  --     elseif (wheelSpeedRear/wheelSpeedFront) < 0.975 and not RWDuntilGripLoss then
  --         torqueRear = math.max(math.min(math.floor(wheelSpeedRear/wheelSpeedFront*100)/100, 1), 0.33)
  --     else
  --         torqueRear = 1
  --     end
  -- end

  -- snedism = math.min(math.max(((string.format("%0.2f", yawSmooth:get(-obj:getYawAngularVelocity()))^2)^0.5),0.00),1)
  yawdir = math.floor(string.format("%0.2f", yawSmooth:get(-obj:getYawAngularVelocity())) * 100) / 100
  speedDiff = math.floor(math.max(math.min(((electrics.values.airspeed + 1) / electrics.values.wheelspeed), 1.0), 0.0) *
    100) / 100




  -- if yawdir < 0 then
  --     -- suggestedTorqueToRear = math.max(math.min(math.max(1 + yawdir, 0) + steering, 1), 0)
  --     suggestedTorqueToRear = math.max(steering, 0)
  -- elseif yawdir > 0 then
  --     -- suggestedTorqueToRear = math.max(math.min(math.max(1 - yawdir, 0) - steering, 1), 0)
  --     suggestedTorqueToRear = math.max(steering, 0)
  -- else
  --     suggestedTorqueToRear = 1
  -- end

  local wheelSpeedFront = (wheels.wheels[wheelIDS.FL].wheelSpeed + wheels.wheels[wheelIDS.FR].wheelSpeed) / 2
  local wheelSpeedRear = (wheels.wheels[wheelIDS.RL].wheelSpeed + wheels.wheels[wheelIDS.RR].wheelSpeed) / 2
  local steering = math.floor(input.steering * 100) / 100
  local steerAmount = math.max(math.abs(steering) or 1, 0)
  local inputSteering = math.floor(input.state.steering.val * 100) / 100
  local inputSteerAmount = math.max(math.abs(inputSteering) or 1, 0)
  local speedDiffBetweenFrontAndRear = math.max(math.min(math.floor(((wheelSpeedFront / wheelSpeedRear) ^ 3) * 100) / 100
    + 0.05
    , 1), 0.5)
  local moreTorqueToRearWhenSteering = speedDiffBetweenFrontAndRear * (inputSteerAmount)

  local inputBrake = input.state.brake.val

  suggestedTorqueToRear = 1 * math.min(speedDiffBetweenFrontAndRear + moreTorqueToRearWhenSteering, 1)

  -- TODO:
  -- CHECK FOR COUNTER-STEER E.G if we are countersteering, give more torque to front wheels

  if diffMode == diffModes.RAW then

    -- RAW

    if yawdir > 0 and inputSteering > 0 then
      --user is steering to the right whilst the vehicle has an anti-clockwise rotation
      -- counterSteerRate = 1
      suggestedTorqueToRear = suggestedTorqueToRear * (1 - steerAmount)
    elseif yawdir < 0 and inputSteering < 0 then
      --user is steering to the left whilst the vehicle has a clockwise rotation
      -- counterSteerRate = -1
      suggestedTorqueToRear = suggestedTorqueToRear * (1 - steerAmount)
    end

    tc.diffTorqueSplitA = math.floor(math.min(suggestedTorqueToRear + inputBrake * 100, 1) * 100) / 100
  elseif diffMode == diffModes.INPUT then
    -- INPUT

    if yawdir > 0 and inputSteering > 0 then
      --user is steering to the right whilst the vehicle has an anti-clockwise rotation
      -- counterSteerRate = 1
      suggestedTorqueToRear = suggestedTorqueToRear * inputSteerAmount
    elseif yawdir < 0 and inputSteering < 0 then
      --user is steering to the left whilst the vehicle has a clockwise rotation
      -- counterSteerRate = -1
      suggestedTorqueToRear = suggestedTorqueToRear * inputSteerAmount
    end

    tc.diffTorqueSplitA = math.floor(math.min(suggestedTorqueToRear + inputBrake * 100, 1) * 100) / 100
  elseif diffMode == diffModes.RWD then
    tc.diffTorqueSplitA = 1
  elseif diffMode == diffModes.FWD then
    tc.diffTorqueSplitA = 0
  elseif diffMode == diffModes.FIFTYFIFTY then
    tc.diffTorqueSplitA = math.floor(math.min(0.5 + inputBrake * 100, 1) * 100) / 100
  elseif diffMode == diffModes.DEFAULT then
    -- tc.diffTorqueSplitA = defaultSplitA
    tc.diffTorqueSplitA = math.floor(math.min(speedDiffBetweenFrontAndRear + inputBrake * 100, 1) * 100) / 100
  end

  if electrics.values.parkingbrake ~= 0 then
    tc.diffTorqueSplitA = 0
    tc.diffTorqueSplitB = 1

    if electrics.values.throttle == 0 then
      electrics.values.clutch = 1
    end
  else
    tc.diffTorqueSplitB = 1 - tc.diffTorqueSplitA
    -- tc.diffTorqueSplitB = tc.diffTorqueSplitB
    -- tc.diffTorqueSplitA = tc.diffTorqueSplitA
  end

  -- speedDiff = math.max(math.min((electrics.values.airspeed/electrics.values.wheelspeed),0.9),0.85)^1 + 0.1
  -- tc.diffTorqueSplitB = tc.diffTorqueSplitB * speedDiff
  -- tc.diffTorqueSplitA = tc.diffTorqueSplitA * speedDiff

  -- print(speedDiff)

  -- if controller.getController("twoStepLaunch") ~= nil and (controller.getController("twoStepLaunch").serialize().state == "idle" or controller.getController("twoStepLaunch").serialize().state == "armed") then
  --     tc.diffTorqueSplitA = 0
  --     tc.diffTorqueSplitB = 0
  -- end

  if electrics.values.signal_right_input == 1 then
    diffModeIndex = diffModeIndex - 1
    if diffModeIndex < 0 then
      diffModeIndex = 5
    end

    if diffModeIndex == 0 then
      diffMode = diffModes.INPUT
    elseif diffModeIndex == 1 then
      diffMode = diffModes.RAW
    elseif diffModeIndex == 2 then
      diffMode = diffModes.FIFTYFIFTY
    elseif diffModeIndex == 3 then
      diffMode = diffModes.RWD
    elseif diffModeIndex == 4 then
      diffMode = diffModes.FWD
    elseif diffModeIndex == 5 then
      diffMode = diffModes.DEFAULT
    end

    -- RWDuntilGripLoss = true
    electrics.toggle_right_signal()
  end
  if electrics.values.signal_left_input == 1 then
    diffModeIndex = diffModeIndex + 1
    if diffModeIndex > 5 then
      diffModeIndex = 0
    end

    if diffModeIndex == 0 then
      diffMode = diffModes.INPUT
    elseif diffModeIndex == 1 then
      diffMode = diffModes.RAW
    elseif diffModeIndex == 2 then
      diffMode = diffModes.FIFTYFIFTY
    elseif diffModeIndex == 3 then
      diffMode = diffModes.RWD
    elseif diffModeIndex == 4 then
      diffMode = diffModes.FWD
    elseif diffModeIndex == 5 then
      diffMode = diffModes.DEFAULT
    end

    -- RWDuntilGripLoss = false
    electrics.toggle_left_signal()
  end

  -- yawRate = obj:getYawAngularVelocity()
  obj.debugDrawProxy:drawText2D(float3(40, 185, 0), color(0, 125, 0, 255), "SpeedDiff: " .. speedDiff)
  obj.debugDrawProxy:drawText2D(float3(40, 200, 0), color(0, 125, 0, 255),
    "SpeedDiffAxles: " .. speedDiffBetweenFrontAndRear)
  -- obj.debugDrawProxy:drawText2D(float3(40,200,0), color(0,125,0,255), "TorqueRear: " .. torqueRear)
  obj.debugDrawProxy:drawText2D(float3(40, 215, 0), color(0, 125, 0, 255), "Mode: " .. diffMode)
  obj.debugDrawProxy:drawText2D(float3(40, 230, 0), color(0, 125, 0, 255), "Yawrate: " .. yawdir)
  obj.debugDrawProxy:drawText2D(float3(40, 245, 0), color(0, 125, 0, 255), "Steering: " .. inputSteering)
  obj.debugDrawProxy:drawText2D(float3(40, 260, 0), color(0, 125, 0, 255), "A: " .. tc.diffTorqueSplitA)
  obj.debugDrawProxy:drawText2D(float3(40, 275, 0), color(0, 125, 0, 255), "B: " .. tc.diffTorqueSplitB)
  -- if RWDuntilGripLoss then
  --     obj.debugDrawProxy:drawText2D(float3(942,615,0), color(0,125,0,255), "RAW")
  -- else
  --     obj.debugDrawProxy:drawText2D(float3(935,615,0), color(0,125,0,255), "INPUT")
  -- end
  if electrics.values.rpm > (eng.maxRPM - 500) then
    obj.debugDrawProxy:drawText2D(float3(950, 600, 0), color(125, 0, 0, 255), electrics.values.gear)
  elseif electrics.values.rpm > (eng.maxRPM - 2500) then
    obj.debugDrawProxy:drawText2D(float3(950, 600, 0), color(125, 125, 0, 255), electrics.values.gear)
  else
    obj.debugDrawProxy:drawText2D(float3(950, 600, 0), color(0, 125, 0, 255), electrics.values.gear)
  end

  local wheelSpeed = math.floor(electrics.values.wheelspeed)
  local airspeed = math.floor(electrics.values.airspeed * 3.6)

  if speedDiff < 0.75 then
    if airspeed >= 100 then
      obj.debugDrawProxy:drawText2D(float3(942, 615, 0), color(125, 0, 0, 255), airspeed)
    elseif airspeed >= 10 then
      obj.debugDrawProxy:drawText2D(float3(946, 615, 0), color(125, 0, 0, 255), airspeed)
    else
      obj.debugDrawProxy:drawText2D(float3(950, 615, 0), color(125, 0, 0, 255), airspeed)
    end
  elseif speedDiff < 0.95 then
    if airspeed >= 100 then
      obj.debugDrawProxy:drawText2D(float3(942, 615, 0), color(125, 125, 0, 255), airspeed)
    elseif airspeed >= 10 then
      obj.debugDrawProxy:drawText2D(float3(946, 615, 0), color(125, 125, 0, 255), airspeed)
    else
      obj.debugDrawProxy:drawText2D(float3(950, 615, 0), color(125, 125, 0, 255), airspeed)
    end
  else
    if airspeed >= 100 then
      obj.debugDrawProxy:drawText2D(float3(942, 615, 0), color(0, 125, 0, 255), airspeed)
    elseif airspeed >= 10 then
      obj.debugDrawProxy:drawText2D(float3(946, 615, 0), color(0, 125, 0, 255), airspeed)
    else
      obj.debugDrawProxy:drawText2D(float3(950, 615, 0), color(0, 125, 0, 255), airspeed)
    end
  end
end

local function onReset(jbeamData)
  -- wheels.FL = powertrain.getDevice("spindleFL") or powertrain.getDevice("wheelaxleFL") or nil
  -- wheels.FR = powertrain.getDevice("spindleFR") or powertrain.getDevice("wheelaxleFR") or nil
  -- wheels.RL = powertrain.getDevice("spindleRL") or powertrain.getDevice("wheelaxleRL") or nil
  -- wheels.RR = powertrain.getDevice("spindleRR") or powertrain.getDevice("wheelaxleRR") or nil
  -- print()

  tc.diffTorqueSplitA = 0.5
  tc.diffTorqueSplitB = 0.5

  for i = 0, 3, 1 do
    wheelIDS[wheels.wheels[i].name] = i;
    -- print(wheelIDS[wheels.wheels[i].name])
    print(wheels.wheels[i].name)
  end

  print("xd")
  dump(wheelIDS)
  -- print(wheels.FL)
  -- print(wheels.FR)
  -- print(wheels.RL)
  -- print(wheels.RR)

  eng = powertrain.getDevice("mainEngine") or {}

  if diffMode == nil then
    diffMode = diffModes.DEFAULT
    diffModeIndex = 0
  end

  print(diffMode)
  -- print("tc info")
  -- dump(tc)
  print(tc.diffTorqueSplitA)

  yawSmooth = newExponentialSmoothing(10)

  if not tc or wheelIDS.FL == nil or wheelIDS.FR == nil or wheelIDS.RL == nil or wheelIDS.RR == nil then
    M.updateGFX = nil
    print("wheels or tc error")
  end

  print("karostPowertrain Loaded")

  -- eng.maxTorqueRating = 9999
end

local function onInit(jbeamData)
  tc = powertrain.getDevice("transfercase") or {}
  defaultSplitA = 0.5
  onReset(jbeamData)
end

-- public interface
M.init      = onInit
M.onReset   = onReset
M.updateGFX = updateGFX

return M
