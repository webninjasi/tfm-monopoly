--- monopoly.dice

local config = pshy.require("monopoly.config")


-- Variables
local diceArea = config.diceArea
local images = config.images.dices
local dice1 = config.dice1
local dice2 = config.dice2
local rollDelay = config.roll.delay
local rollTime
local cage = {
  { x=-70, y=0, w=10, h=60, a=0 },
  { x=70, y=0, w=10, h=60, a=0 },
  { x=0, y=70, w=60, h=10, a=0 },
  { x=0, y=-70, w=60, h=10, a=0 },
  { x=-50, y=-50, w=10, h=60, a=45 },
  { x=50, y=50, w=10, h=60, a=45 },
  { x=50, y=-50, w=60, h=10, a=45 },
  { x=-50, y=50, w=60, h=10, a=45 },
}


-- Functions
local module = {}

module.roll = function(x, y)
  if rollTime then
    return
  end

  x = math.max(diceArea.x1 + diceArea.offset, math.min(diceArea.x2 - diceArea.offset, x))
  y = math.max(diceArea.y1 + diceArea.offset, math.min(diceArea.y2 - diceArea.offset, y))

  for i=1, #cage do
    tfm.exec.addPhysicObject(2+i, x + cage[i].x, y + cage[i].y, {
      type = 14,
      width = cage[i].w,
      height = cage[i].h,
      angle = cage[i].a,
    })
  end

  rollTime = os.time()
  tfm.exec.addPhysicObject(1, x + dice1.x, y + dice1.y, {
    dynamic = true,
    fixedRotation = false,
    type = 12,
    color = 0xffffff,
    width = 30,
    height = 30,
  })
  tfm.exec.addPhysicObject(2, x + dice2.x, y + dice2.y, {
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

return module
