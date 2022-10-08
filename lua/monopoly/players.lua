--- monopoly.players

-- Config
local cfg = pshy.require('monopoly.config').playersUI
local uiX, uiY = cfg.x, cfg.y
local initY, offX, offY = cfg.inity, cfg.offx, cfg.offy


-- Variables
local players = {}
local lastX, lastY = {}, {}
local _count = 0
local first, last = nil, nil -- linked list of players
local uiText = '' -- cached ui text
local uiTextShadow = ''
local move_button_shadow = '<p align="left"><font size="20" color="#000000">⛶</font></p>'
local move_button = '<p align="left"><font size="20" color="#%.6x"><a href="event:move_ui">⛶</a></font></p>'
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

local function updateTokens(target)
  if not target then
    for name in pairs(tfm.get.room.playerList) do
      updateTokens(name)
    end

    return
  end

  local x = lastX[target] or uiX
  local y = lastY[target] or uiY
  local player = first
  local imgY = y + initY
  local scale

  while player do
    if player.tokenid and player.token then
      scale = math.min(1, offY / player.token.h)
      ui.addImage(
        "playerlist_token_" .. player.tokenid,
        player.token.img,
        "!1",
        x + offX - player.token.w / 2 * scale, imgY + player.token.h / 2 * scale,
        target,
        scale, scale, 0, 1,
        0.5, 0.5
      )
    end

    imgY = offY + imgY
    player = player.next
  end
end

local function updateUI()
  local player = first
  local list = {move_button:format(0xDEDEDE) .. '<font size="15">'}
  local listShadow = {move_button_shadow .. '<font size="15" color="#000000">'}
  local i = #list
  local money_diff
  local money

  while player do
    i = 1 + i
    money_diff = player.money_diff or 0
    money = player.money or 0

    listShadow[i] = string.format(
      '<b>%s%s <font size="-2">#%s</font></b>%s\n' ..
      '%s$%s <font size="-2">%s$%s<font size="+2">%s%s',
      player.turn and "• " or "",
      player.username,
      player.usertag,
      player.afk and ' [AFK]' or '',
      money < 0 and "-" or "",
      math.abs(money),
      money_diff < 0 and '-' or '+',
      math.abs(money_diff),
      player.jailcard and ' - ☔' or '',
      player.tradeMode and ' - ☕' or ''
    )
    list[i] = string.format(
      '<b><font color="#%.6x">%s</font>%s</b>%s\n' ..
      '%s%s$%s <BL><font size="-2">%s%s$%s<font size="+2"><BL>%s%s',
      player.color or 0,
      player.turn and "• " or "",
      player.colorname,
      player.afk and ' <V>[AFK]' or '',
      money < 0 and '<R>' or '<VP>',
      money < 0 and '-' or '',
      math.abs(money),
      money_diff < 0 and '<R>' or '<VP>',
      money_diff < 0 and '-' or '+',
      math.abs(money_diff),
      player.jailcard and ' <G>- <FC>☔' or '',
      player.tradeMode and string.format(
        ' <G>- <FC><a href="event:trade_%s">☕</a>',
        player.name
      ) or ''
    )
    player = player.next
  end

  uiText = table.concat(list, '\n')
  uiTextShadow = table.concat(listShadow, '\n')

  ui.updateTextArea(
    "playerlistshadow",
    uiTextShadow
  )
  ui.updateTextArea(
    "playerlist",
    uiText
  )
  updateTokens()
end

local function showUI(target, x, y)
  if target then
    lastX[target] = x
    lastY[target] = y
  end

  ui.addTextArea(
    "playerlistshadow",
    uiTextShadow,
    target,
    x+1, y+1,
    nil, nil,
    0, 0, 0,
    false
  )
  ui.addTextArea(
    "playerlist",
    uiText,
    target,
    x, y,
    nil, nil,
    0, 0, 0,
    false
  )
  updateTokens(target)
end

local function hideUI()
  ui.removeTextArea("playerlistshadow")
  ui.removeTextArea("playerlist")
end

local function hideTokens()
  local player = first

  while player do
    if player.tokenid then
      ui.removeImage("playerlist_token_" .. player.tokenid)
    end

    player = player.next
  end
end

local function reset()
  hideTokens()
  first = nil
  last = nil
  uiText = ''
  uiTextShadow = ''
  players = {}
  _count = 0
  updateUI()
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

    if player.tokenid then
      ui.removeImage("playerlist_token_" .. player.tokenid)
    end

    players[name] = nil
    _count = _count - 1

    return player
  end
end

local function colorName(player)
  if player then
    if not player.username then
      player.username, player.usertag = player.name:match('(%S-)#(%d+)')
    end

    player.colorname = string.format(
      '<font color="#%.6x">%s</font> <font size="-2"><BL>#%s</BL></font>',
      player.color or 0,
      player.username,
      player.usertag
    )
  end
end

-- Public Functions
module.reset = reset
module.showUI = function(target)
  showUI(target, uiX, uiY)
end

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

  colorName(obj)
  updateUI()
end

module.get = function(name, key)
  if not key then
    return players[name]
  end

  return players[name] and players[name][key]
end

module.update = function(name, key, value)
  if name then
    local player = players[name]

    if player then
      if key == 'money' then
        player.money_diff = value - (player.money or 0)
      end

      player[key] = value

      if key == 'order' then
        reorder(player)
      elseif key == 'color' or key == 'name' then
        colorName(player)
      elseif key == 'money' then
        tfm.exec.setPlayerScore(name, player.money)
        eventMoneyChanged(name, player.money, player.money_diff)
      end
    end
  end

  updateUI()
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
    eventPlayersUpdated(name, player)
  end
end


-- Events
function eventPlayerLeft(name)
  local player = module.get(name)

  if player then
    module.update(name, 'afk', true)
  end
end

function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 6) == 'trade_' then
    local target = callback:sub(7)

    eventTradeRequest(name, target)
  end
end

function eventTextAreaMove(id, name, x, y)
  if id == ui.textAreaId("playerlist") or id == ui.textAreaId("playerlistshadow") then
    showUI(name, x, y)
  end
end

return module
