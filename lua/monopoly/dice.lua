--- monopoly.dice

monopoly = monopoly or {}

if monopoly.dice then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Variables
local images = monopoly.config.images.dices
local dice1 = monopoly.config.dice1
local dice2 = monopoly.config.dice2
local rollDelay = monopoly.config.roll.delay
local rollTime


-- Functions
monopoly.dice = {}

monopoly.dice.roll = function()
  if rollTime then
    return
  end

  rollTime = os.time()
  tfm.exec.addPhysicObject(1, dice1.x, dice1.y, {
    dynamic = true,
    fixedRotation = false,
    type = 12,
    color = 0xffffff,
    width = 30,
    height = 30,
  })
  tfm.exec.addPhysicObject(2, dice2.x, dice2.y, {
    dynamic = true,
    fixedRotation = false,
    type = 12,
    color = 0xffffff,
    width = 30,
    height = 30,
  })
  tfm.exec.movePhysicObject(1, 0, 0, true, math.random(-100, 100), math.random(-100, 100), false, 1, true)
  tfm.exec.movePhysicObject(2, 0, 0, true, math.random(-100, 100), math.random(-100, 100), false, 1, true)
end


-- Events
function eventLoop(elapsed, remaining)
  if not rollTime then
    return
  end

  if os.time() - rollTime < rollDelay then
    return
  end

  local num1, num2 = math.random(6), math.random(6)

  rollTime = nil
  tfm.exec.addImage(images[num1], "+1", -15, -15)
  tfm.exec.addImage(images[num2], "+2", -15, -15)
  tfm.exec.movePhysicObject(1, 0, 0, true, 0, 0, false, 0, false)
  tfm.exec.movePhysicObject(2, 0, 0, true, 0, 0, false, 0, false)

  if eventDiceRoll then
    eventDiceRoll(num1, num2)
  end
end
