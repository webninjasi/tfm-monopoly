--- monopoly.votes

monopoly = monopoly or {}

if monopoly.money then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Money Variables
local uiX, uiY = monopoly.config.money.x, monopoly.config.money.y
local money = {}
local lastChange = {}


-- Private Functions
local function updateUI(name)
  local str = ('<b><font size="30">$%s'):format(money[name] or 0)

  ui.addTextArea(
    "money-shadow",
    '<font color="#0">' .. str,
    name,
    uiX+1, uiY+1,
    nil, nil,
    0, 0, 0,
    false
  )

  if lastChange[name] then
    str = ('%s <font size="12">%s$%s'):format(
      str,
      lastChange[name] < 0 and '<R>-' or '<VP>+',
      math.abs(lastChange[name])
    )
  end

  ui.addTextArea(
    "money",
    '<VP>' .. str,
    name,
    uiX, uiY,
    nil, nil,
    0, 0, 0,
    false
  )
end


-- Functions
monopoly.money = {}

monopoly.money.reset = function(name)
  money = {}
  lastChange = {}
  ui.removeTextArea("money")
  ui.removeTextArea("money-shadow")
end

monopoly.money.give = function(name, amount)
  if not money[name] then
    money[name] = 0
  end

  money[name] = money[name] + amount
  lastChange[name] = amount
  updateUI(name)

  if eventMoneyChanged then
    eventMoneyChanged(name, money[name], amount)
  end
end

monopoly.money.take = function(name, amount)
  if not money[name] then
    money[name] = 0
  end

  money[name] = money[name] - amount
  lastChange[name] = -amount
  updateUI(name)

  if eventMoneyChanged then
    eventMoneyChanged(name, money[name], -amount)
  end
end

monopoly.money.hasEnough = function(name, amount)
  if not money[name] then
    money[name] = 0
  end

  return money[name] >= amount
end
