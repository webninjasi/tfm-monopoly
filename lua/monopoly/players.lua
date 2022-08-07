--- monopoly.players

-- Config
local cfg = pshy.require('monopoly.config').playersUI
local uiX, uiY = cfg.x, cfg.y


-- Variables
local players = {}
local _count = 0
local first, last = nil, nil -- linked list of players
local uiText = '' -- cached ui text
local uiTextShadow = ''
local module = {}


-- Private Functions
local function reorder(target)
  local player = first

  while player ~= target do
    if not player.order or player.order < target.order then
      if first == player then
        first = target
      else
        player.prev.next = target
      end

      if last == target then
        last = target.prev
      else
        target.next.prev = target.prev
      end

      target.prev.next = target.next
      target.prev = player.prev
      target.next = player
      player.prev = target

      return
    end

    player = player.next
  end
end

local function updateUI()
  local player = first
  local list = {'<p align="right"><font size="15">'}
  local listShadow = {'<p align="right"><font size="15" color="#000000">'}
  local i = #list

  while player do
    i = 1 + i
    listShadow[i] = string.format(
      '<b>%s%s</b>\n$%s',
      player.turn and "• " or "",
      player.name,
      player.money or 0
    )
    list[i] = string.format(
      '<font color="#%.6x"><b>%s%s</b>\n<VP>$%s',
      player.color or 0,
      player.turn and "• " or "",
      player.name,
      player.money or 0
    )
    player = player.next
  end

  uiText = table.concat(list, '\n')
  uiTextShadow = table.concat(listShadow, '\n')
end

local function showUI(target)
  ui.addTextArea(
    "playerlistshadow",
    uiTextShadow,
    target,
    uiX+1, uiY+1,
    260, nil,
    0, 0, 0,
    false
  )
  ui.addTextArea(
    "playerlist",
    uiText,
    target,
    uiX, uiY,
    260, nil,
    0, 0, 0,
    false
  )
end

local function hideUI()
  ui.removeTextArea("playerlistshadow")
  ui.removeTextArea("playerlist")
end

local function reset()
  first = nil
  last = nil
  uiText = ''
  uiTextShadow = ''
  players = {}
  _count = 0
  hideUI()
end

local function remove(name)
  local player = players[name]

  if player then
    if player.prev then
      player.prev.next = player.next
    end

    if player.next then
      player.next.prev = player.prev
    end

    if player == first then
      first = player.next
    end

    if player == last then
      last = player.prev
    end

    players[name] = nil
    _count = _count - 1

    return player
  end
end


-- Public Functions
module.reset = reset
module.showUI = showUI

module.create = function(obj)
  if last then
    last.next = obj
    obj.next = nil
    obj.prev = last
    last = obj
  else
    first = obj
    last = obj
    obj.prev = nil
    obj.next = nil
  end

  if not players[obj.name] then
    players[obj.name] = obj
    _count = _count + 1
  end

  updateUI()
  showUI()
end

module.get = function(name, key)
  if not key then
    return players[name]
  end

  return players[name] and players[name][key]
end

module.update = function(name, key, value)
  local player = players[name]

  if player then
    player[key] = value

    if key == 'order' then
      reorder(player)
    end
  end

  updateUI()
  showUI()
end

module.next = function(player)
  return player and player.next or first
end

module.count = function()
  return _count
end

module.iter = function(_, player)
  if player then
    return player.next
  end

  return first
end

module.add = function(name, key, value)
  local current = module.get(name, key) or 0
  return module.update(name, key, current + value)
end

module.remove = function(name)
  local player = remove(name)

  if player and eventPlayersUpdated then
    updateUI()
    showUI()
    eventPlayersUpdated(name, player)
  end
end


-- Events
function eventPlayerLeft(name)
  module.remove(name)
end

return module
