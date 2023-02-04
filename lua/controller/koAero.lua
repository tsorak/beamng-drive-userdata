local M = {}
local yawSmooth

local function onInit()
  yawSmooth = newExponentialSmoothing(10)
  velZSmoother = newExponentialSmoothing(10)
end

local function updateGFX()
  local rotAcc = math.floor(string.format("%0.2f", yawSmooth:get(-obj:getYawAngularVelocity())) * 100) / 100

  local airspdKMH = math.floor(electrics.values.airspeed * 3.6)

  -- print(rotAcc)
  if rotAcc > 0 then
    electrics.values.wingL = math.max(math.min(1, rotAcc - input.steering), 0)
    -- print(electrics.values.wingL)
  else
    electrics.values.wingL = math.max(0, input.steering * -1)
  end

  if rotAcc < 0 then
    electrics.values.wingR = math.max(math.min(1, rotAcc * -1 + input.steering), 0)
    -- print(electrics.values.wingR)
  else
    electrics.values.wingR = math.max(0, input.steering)
  end

  -- local speedBelow100Factor = math.max(0, math.min(1, 1 - airspdKMH / 100))

  -- dump()
  -- dump(obj:getVelocityXYZ())
  -- dump(obj:getObjectDirectionVectorUp())
  -- dump(obj:getDistanceFromTerrain())
  -- dump(obj:getDirectionVectorUp())
  -- dump(obj:getDirectionVectorUpXYZ())
  -- dump(obj:getDirectionVectorXYZ())
  -- dump(obj:getDirectionVectorXYZ())

  local velZ = math.max(0, math.min(1, velZSmoother:get(-obj:getSensorZ()) / 5 - 1))

  electrics.values.wingL = math.min(1,
    electrics.values.wingL + math.max(0, electrics.values.brake * (1 - math.abs(input.steering * 2))) +
    (airspdKMH / 1500) + velZ)

  electrics.values.wingR = math.min(1,
    electrics.values.wingR + math.max(0, electrics.values.brake * (1 - math.abs(input.steering * 2))) +
    (airspdKMH / 1500) + velZ)

  electrics.values.wingM = (electrics.values.wingL + electrics.values.wingR) / 2


  electrics.values.wingRL = math.max(0, math.min(1, rotAcc))
  -- if rotAcc > 0 then
  --   -- print(electrics.values.wingL)
  -- else
  --   electrics.values.wingRL = math.max(0, input.steering * -1)
  -- end

  electrics.values.wingRR = math.max(-1, math.min(0, rotAcc)) * -1
  -- if rotAcc < 0 then
  --   -- print(electrics.values.wingR)
  -- else
  --   electrics.values.wingRR = math.max(0, input.steering)
  -- end



  electrics.values.wingRR = math.min(1,
    electrics.values.wingRR + math.max(0, electrics.values.brake * (1 - math.abs(input.steering))) +
    (airspdKMH / 600) + velZ)

  electrics.values.wingRL = math.min(1,
    electrics.values.wingRL + math.max(0, electrics.values.brake * (1 - math.abs(input.steering))) +
    (airspdKMH / 600) + velZ)

  electrics.values.wingRM = (electrics.values.wingRL + electrics.values.wingRR) / 2.25
end

-- public interface
M.init = onInit
-- M.onReset = onReset
M.updateGFX = updateGFX

return M
