--- monopoly.trade

local config = pshy.require("monopoly.config")
local translations = pshy.require("monopoly.translations")

local img = config.images

local currentTrade

local function buildItemList(trade, target)
  local list = { _len = 0 }

  list._len = 1 + list._len
  if trade.lock then
    list[list._len] = '<VP><font face="Verdana" size="20">☑</font>   '
  else
    list[list._len] = '<R><font face="Verdana" size="20">☐</font>   '
  end

  list._len = 1 + list._len
  list[list._len] = trade.jailcard and '<VP>' or '<BL>'

  list._len = 1 + list._len
  list[list._len] = '<font size="20"><a href="event:tradecb_jailcard">☔</a></font>\n'

  list._len = 1 + list._len
  list[list._len] = '<V><font size="16"><b><u>' .. trade.name .. '</u></b></font>\n'

  list._len = 1 + list._len
  list[list._len] = trade.money > 0 and '<VP>' or '<BL>'

  list._len = 1 + list._len
  list[list._len] = '<a href="event:tradecb_money">$' .. trade.money .. '</a>\n'

  if trade.houseCount > 0 then
    list._len = 1 + list._len
    list[list._len] = '<FC>' .. trade.houseCount .. ' houses\n'
  end

  for key, card in pairs(trade.cards) do
    list._len = 1 + list._len
    list[list._len] = string.format(
      '<font color="#%s">%s\n',
      card.header_color or 0,
      card.title
    )
  end

  return list
end

local function getTrade(name)
  if not currentTrade then
    return
  end

  if currentTrade.left.name == name then
    return currentTrade.left
  end

  if currentTrade.right.name == name then
    return currentTrade.right
  end
end

local module = {}

module.startTrade = function(player1, player2)
  currentTrade = {
    left = {
      is_left = true,
      name = player1,
      money = 0,
      jailcard = false,
      houses = {},
      houseCount = 0,
      cards = {},
      cardCount = 0,
      lock = false,
    },

    right = {
      is_left = false,
      name = player2,
      money = 0,
      jailcard = false,
      houses = {},
      houseCount = 0,
      cards = {},
      cardCount = 0,
      lock = false,
    },
  }
end

module.cancelTrade = function()
  if currentTrade then
    currentTrade.canceled = true
    eventTradeEnded(currentTrade)
    currentTrade = nil
  end
end

module.addHouse = function(name, card_name)
  local trade = getTrade(name)

  if trade then
    if trade.houses[card_name] then
      return
    end

    trade.houses[card_name] = true
    trade.houseCount = trade.houseCount + 1
  end
end

module.removeHouse = function(name, card_name)
  local trade = getTrade(name)

  if trade then
    if not trade.houses[card_name] then
      return
    end

    trade.houses[card_name] = nil
    trade.houseCount = trade.houseCount - 1
  end
end

module.toggleCard = function(name, card)
  if not card then
    return
  end

  local trade = getTrade(name)

  if trade then
    if trade.cards[card.id] then
      trade.cards[card.id] = nil
      trade.cardCount = trade.cardCount - 1
    else
      trade.cards[card.id] = card
      trade.cardCount = trade.cardCount + 1
      return true
    end
  end
end

module.setMoney = function(name, amount)
  local trade = getTrade(name)

  if trade then
    trade.money = amount
  end
end

module.toggleJailCard = function(name)
  local trade = getTrade(name)

  if trade then
    trade.jailcard = not trade.jailcard
  end
end

module.setLock = function(name, state)
  local trade = getTrade(name)

  if trade then
    trade.lock = state

    if currentTrade.left.lock and currentTrade.right.lock then 
      eventTradeEnded(currentTrade)
      currentTrade = nil
    end
  end
end

module.showPopup = function(target)
  ui.addPopup(
    128, 2,
    '',
    target,
    340, 235,
    120, true
  )
  ui.addImage(
    "tradepopup",
    img.popup,
    "~150",
    336, 231,
    target,
    1, 1, 0, 1
  )
end

module.showUI = function(target)
  ui.addImage(
    "tradeui",
    img.ui,
    "~100",
    234, 100,
    target,
    1, 1, 0, 1
  )
  ui.addImage(
    "tradesep",
    img.pixels.black,
    "~100",
    400 - 1, 150,
    target,
    2, 160, 0, 1
  )

  translations.addTextArea(
    "tradetitle",
    "ui_trade_title", nil,
    target,
    234, 110,
    332, nil,
    0, 0, 0,
    true
  )

  ui.addTextArea(
    "tradeleft",
    '',
    target,
    250, 115,
    150, 195,
    0, 0, 0,
    true
  )
  ui.addTextArea(
    "traderight",
    '',
    target,
    400, 115,
    150, 195,
    0, 0, 0,
    true
  )

  ui.addImage(
    "tradeconfirm",
    img.pixels.black,
    "~100",
    300, 330,
    target,
    90, 20, 0, 1
  )
  translations.addTextArea(
    "tradeconfirm",
    'trade_confirm', nil,
    target,
    300, 330,
    90, nil,
    0, 0, 0,
    true
  )

  ui.addImage(
    "tradecancel",
    img.pixels.black,
    "~100",
    410, 330,
    target,
    90, 20, 0, 1
  )
  translations.addTextArea(
    "tradecancel",
    'trade_cancel', nil,
    target,
    410, 330,
    90, nil,
    0, 0, 0,
    true
  )
end

module.hideUI = function(target)
  ui.removeImage("tradeui", target)
  ui.removeImage("tradesep", target)
  ui.removeTextArea("tradetitle", target)
  ui.removeTextArea("tradeleft", target)
  ui.removeTextArea("traderight", target)
  ui.removeImage("tradeconfirm", target)
  ui.removeTextArea("tradeconfirm", target)
  ui.removeImage("tradecancel", target)
  ui.removeTextArea("tradecancel", target)
  ui.removeImage("tradepopup", target)
  ui.addPopup(
    128, 2,
    "",
    target,
    -5000, -5000,
    nil, true
  )
end

module.updateUI = function(target)
  if not currentTrade then
    return
  end

  local left = buildItemList(currentTrade.left, target)
  local right = buildItemList(currentTrade.right, target)

  ui.updateTextArea("tradeleft", table.concat(left, ''), target)
  ui.updateTextArea("traderight", '<p align="right">' .. table.concat(right, ''), target)
end


function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 8) == 'tradecb_' then
    local trade = getTrade(name)
    local action = callback:sub(9)
    local is_left = ui.textAreaId("tradeleft") == id

    if trade and (trade.is_left == is_left or action == 'confirm' or action == 'cancel') then
      eventTradeCallback(name, callback:sub(9))
    end
  end
end

function eventPopupAnswer(popupId, name, answer)
  if popupId == 128 then
    ui.removeImage("tradepopup", name)

    local trade = getTrade(name)
    local amount = tonumber(answer)

    if amount and amount >= 0 and trade then
      eventTradeSetMoney(name, amount)
    end
  end
end

return module
