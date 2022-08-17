--- monopoly.property

local config = pshy.require("monopoly.config")
local translations = pshy.require("monopoly.translations")
local players = pshy.require("monopoly.players")


-- Variables
local img = config.images.auction
local boardCells = config.board.cells
local positions = config.board.positions
local cellCount = #positions
local cardImages = config.images.cards
local pixels = config.images.pixels
local cardRowsByType = config.cardRows

for _, rows in pairs(cardRowsByType) do
  rows._len = #rows
end

local owners = {}
local cellsByType = {}
local separator = '<p align="center">' .. string.rep('━', 12) .. '</p>'


-- Private Functions
local function scanBoardCells()
  local list, cell

  for i=1, #boardCells do
    cell = boardCells[i]
    list = cellsByType[cell.type]

    if not list then
      list = { _len = 0 }
      cellsByType[cell.type] = list
    end

    cell.card_image = cardImages[cell.card_image or 'empty']
    cell.header_color = cell.header_color or '000000'
    cell.title_tr = "card_" .. i
    cell.infoY = 35

    if cell.type == 'station' then
      cell.station1 = 25
      cell.station2 = 50
      cell.station3 = 100
      cell.station4 = 200
    elseif cell.type == 'utility' then
      cell.utility1 = -1
      cell.utility2 = -1
    elseif cell.type ~= 'property' then
      cell.card_width = 136

      if cell.type == 'chance' or cell.type == 'jailvisit' then
        cell.infoY = 50
      end
    end

    list._len = 1 + list._len
    list[list._len] = cell
  end
end

local function showPropertyCard(cell, name, x, y, canBuy)
  local w, h = 150, 200
  local isProperty = cell.type == 'property'

  if isProperty then
    ui.addTextArea(
      "cardheader",
      string.format(
        '<p align="center"><font size="15" color="#000000"><a href="event:closecard">%s',
        translations.get(cell.title_tr, name)
      ),
      name,
      x + 10, y + 15,
      w - 20, 50,
      cell.header_color, cell.header_color, 1,
      true
    )
  end

  ui.addImage("cardbg", cell.card_image, "~150", x, y, name)

  local cardRows = cardRowsByType[cell.type]
  local rows = { _len = 0 }
  local val, card

  if isProperty then
    rows._len = 1 + rows._len
    rows[rows._len] = '<textformat tabstops="[90]"><font size="10" color="#000000">'
  else
    rows._len = 1 + rows._len
    rows[rows._len] = string.format(
      '\n\n\n\n<font size="9" color="#000000"><p align="center"><b><a href="event:closecard">%s</a></b></p>\n<textformat tabstops="[110]"><font size="8" color="#8E8E8E">',
      translations.get(cell.title_tr, name)
    )
  end

  if cardRows then
    for i=1, cardRows._len do
      card = cardRows[i]
      val = cell[card.key]

      if val then
        if card.key == 'house_hotel' then
          rows._len = 1 + rows._len
          rows[rows._len] = separator
        end

        rows._len = 1 + rows._len
        if val > 0 then
          rows[rows._len] = string.format(
            '%s\t<font color="#006400">$%d</font>',
            card.title_html or card.title,
            val
          )
        else
          rows[rows._len] = card.title_html or card.title
        end
      end
    end
  end

  if canBuy then
    ui.addImage("cardbtnbuy", pixels.black, "~160", x, y + 205, name, 70, 20, 0, 0.8)
    ui.addImage("cardbtnauction", pixels.black, "~160", x + 80, y + 205, name, 70, 20, 0, 0.8)
    ui.addTextArea(
      "cardbtnbuy",
      '<VP><b><p align="center"><a href="event:buy">BUY</a>',
      name,
      x, y + 205,
      70, nil,
      0, 0, 0,
      true
    )
    ui.addTextArea(
      "cardbtnauction",
      '<VP><b><p align="center"><a href="event:auction">AUCTION</a>',
      name,
      x + 80, y + 205,
      70, nil,
      0, 0, 0,
      true
    )
  end

  ui.addTextArea(
    "cardinfo",
    table.concat(rows, '\n'),
    name,
    x + (isProperty and 10 or 7), y + cell.infoY,
    cell.card_width, nil,
    0, 0, 0,
    true
  )
end


-- Public Functions
local module = {}

module.reset = function()
  owners = {}
end

module.showButtons = function(target)
  local spaces = string.rep(' ', 50)
  local pos

  for i=1, cellCount do
    pos = positions[i]
    ui.addTextArea(
      "boardcell_" .. i,
      '<a href="event:boardcell_' .. i .. '"><font size="72">' .. spaces,
      target,
      pos[1], pos[2],
      pos[3] - pos[1] - 5, pos[4] - pos[2] - 5,
      0, 0, 0,
      false
    )
  end
end

module.getOwner = function(key)
  return key and owners[key]
end

module.setOwner = function(key, owner)
  if key then
    owners[key] = owner
  end
end

module.canBuy = function(card)
  return not module.getOwner(card.id)
    and (
      card.type == 'property'
      or card.type == 'utility'
      or card.type == 'station'
    )
end

module.hideCard = function(name)
  ui.removeTextArea("cardheader", name)
  ui.removeTextArea("cardinfo", name)
  ui.removeTextArea("cardbtnbuy", name)
  ui.removeTextArea("cardbtnauction", name)
  ui.removeImage("cardbg", name)
  ui.removeImage("cardbtnbuy", name)
  ui.removeImage("cardbtnauction", name)
end

module.showCard = function(cell, name, canBuy)
  showPropertyCard(cell, name, 325, 100, canBuy)
end

module.calculateRent = function(cell, diceSum)
  if cell.type == 'utility' or cell.type == 'station' then
    local list = cellsByType[cell.type]
    local owner = owners[cell.id]
    local count = 0

    -- calculate number of same property owned
    for i=1, list._len do
      if owners[list[i].id] == owner then
        count = 1 + count
      end
    end

    if cell.type == 'utility' then
      return diceSum * (count == 1 and 4 or 10)
    end

    return 25 * math.pow(2, count - 1) -- station rent
  end

  -- TODO house/hotel rents

  return cell.rent
end

module.showAuctionBid = function(target)
  ui.addPopup(
    44, 2,
    "",
    target,
    260, 235,
    120, true
  )
  ui.addImage(
    "auctionpopup",
    img.popup,
    "~110",
    256, 231,
    target,
    1, 1, 0, 1,
    true
  )
end

module.showAuction = function(cell)
  for player in players.iter do
    ui.addImage(
      "auctionui",
      img.ui,
      "~100",
      234, 100,
      player.name,
      1, 1, 0, 1,
      true
    )
    ui.addImage(
      "auctionsep",
      pixels.black,
      "~100",
      400 - 1, 150,
      player.name,
      2, 160, 0, 1,
      true
    )

    module.showAuctionBid(player.name)
    module.hideCard(player.name)
    showPropertyCard(cell, player.name, 75, 110, false)

    ui.addTextArea(
      "auctiontitle",
      translations.get("auction_title", player.name),
      player.name,
      234, 110,
      332, nil,
      0, 0, 0,
      true
    )
    ui.addTextArea(
      "auctioncard",
      string.format(
        '<p align="center"><font size="12" color="#000000"><a href="event:auctioncard_%d">%s',
        cell.id,
        translations.get(cell.title_tr, player.name)
      ),
      name,
      260, 150,
      120, nil,
      cell.header_color, cell.header_color, 1,
      true
    )
  end
end

module.hideAuction = function(target)
  ui.removeTextArea("auctiontitle", target)
  ui.removeTextArea("auctioncard", target)
  ui.removeTextArea("auctionhighest", target)
  ui.removeTextArea("auctionplayers", target)
  ui.removeImage("auctionpopup", target)
  ui.removeImage("auctionui", target)
  ui.removeImage("auctionsep", target)
  ui.addPopup(
    44, 2,
    "",
    target ~= "*" and target or nil,
    -5000, -5000,
    nil, true
  )
end

module.updateAuction = function(whoseTurn, highestBid, highestBidder)
  local list = {}

  for player in players.iter do
    list[1 + #list] = string.format(
      '<font color="#%.6x">%s%s',
      player.color,
      whoseTurn == player.name and '&gt; ' or '',
      player.name
    )

    ui.addTextArea(
      "auctionhighest",
      translations.get("auction_highest", player.name, highestBid, highestBidder),
      player.name,
      250, 180,
      140, nil,
      0, 0, 0,
      true
    )
  end

  ui.addTextArea(
    "auctionplayers",
    table.concat(list, '\n'),
    nil,
    410, 150,
    nil, nil,
    0, 0, 0,
    true
  )
end


-- Events
function eventInit()
  scanBoardCells()
end

function eventPopupAnswer(popupId, name, answer)
  if popupId == 44 then
    local bid = tonumber(answer)

    if eventAuctionBid then
      bid = bid and math.floor(bid)
      eventAuctionBid(name, bid)
    end
  end
end

function eventTextAreaCallback(id, name, callback)
  if callback == "closecard" then
    module.hideCard(name)
  elseif id == ui.textAreaId("cardbtnbuy") then
    if eventBuyCardClick then
      eventBuyCardClick(name)
    end
  elseif id == ui.textAreaId("cardbtnauction") then
    if eventAuctionCardClick then
      eventAuctionCardClick(name)
    end
  elseif callback:sub(1, 12) == 'auctioncard_' then
    local id = tonumber(callback:sub(13))
    local cell = id and boardCells[id]

    if cell then
      module.hideCard(name)
      showPropertyCard(cell, name, 75, 110, false)
    end
  elseif callback:sub(1, 10) == 'boardcell_' then
    local id = tonumber(callback:sub(11))
    local cell = id and boardCells[id]

    if cell and eventPropertyClicked then
      eventPropertyClicked(name, cell)
    end
  end
end

return module
