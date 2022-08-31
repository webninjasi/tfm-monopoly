--- monopoly.property

local config = pshy.require("monopoly.config")
local translations = pshy.require("monopoly.translations")
local players = pshy.require("monopoly.players")


-- Variables
local img = config.images
local boardCells = config.board.cells
local houseSize = config.board.houseSize
local positions = config.board.positions
local cellCount = #positions
local cardImages = config.images.cards
local pixels = config.images.pixels
local cardRowsByType = config.cardRows

for _, rows in pairs(cardRowsByType) do
  rows._len = #rows
end

local owners = {}
local houses = {}
local mortgage = {}

local cellsByGroup = {}
local cellsByType = {}
local separator = '<p align="center">' .. string.rep('━', 12) .. '</p>'
local empty_space = string.rep(' ', 30)

local battery_cap = 10
local battery = string.rep('█', battery_cap)
local battery_cell_size = #battery / battery_cap


-- Private Functions
local function cellDirection(cellId)
  return math.ceil(cellId / 10)
end

local function scanBoardCells()
  local list, cell, group

  for i=1, #boardCells do
    cell = boardCells[i]
    list = cellsByType[cell.type]

    if not list then
      list = { _len = 0 }
      cellsByType[cell.type] = list
    end

    if cell.header_color then
      group = cellsByGroup[cell.header_color]

      if group then
        group._len = 1 + group._len
        group[group._len] = cell
      else
        cellsByGroup[cell.header_color] = { cell, _len = 1 }
      end
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
      cell.header_color_int, cell.header_color_int, 1,
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

  -- TODO move rows to translations
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
    -- TODO use translations
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
  houses = {}
  mortgage = {}
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

module.getGroupOwner = function(cellId)
  local cell = cellId and boardCells[cellId]
  local owner = cellId and owners[cellId]

  if not cell or cell.header_color or owner then
    return
  end

  local group = cellsByGroup[cell.header_color]

  if not group then
    return
  end

  for i=1, group._len do
    if owners[group[i].id] ~= owner then
      return
    end
  end

  return owner
end

module.getProperties = function(owner)
  local list = { _len = 0 }

  for cellId, name in pairs(owners) do
    if name == owner then
      list._len = 1 + list._len
      list[list._len] = boardCells[cellId]
    end
  end

  return list
end

module.getHouses = function(cellId)
  return houses[cellId] or 0
end

module.getOwnerHouses = function(name)
  local properties = module.getProperties(name)
  local house_count = 0
  local hotel_count = 0
  local house

  for i=1, properties._len do
    house = houses[properties[i].id] or 0

    if house == 5 then
      house_count = 4 + house_count
      hotel_count = 1 + hotel_count
    else
      house_count = house + house_count
    end
  end

  return house_count, hotel_count
end

module.addHouse = function(cellId)
  houses[cellId] = 1 + (houses[cellId] or 0)
end

module.removeHouse = function(cellId)
  houses[cellId] = -1 + (houses[cellId] or 0)
end

module.getOwner = function(key)
  return key and owners[key]
end

module.setOwner = function(cellId, owner)
  local cell = cellId and boardCells[cellId]

  if cell then
    owners[cellId] = owner
  end
end

module.housePrice = function(cellId)
  local cell = cellId and boardCells[cellId]
  return cell and cell.house_hotel or 0
end

module.mortgagePrice = function(cellId)
  local cell = cellId and boardCells[cellId]
  return cell and cell.mortgage or 0
end

module.canBuy = function(card)
  return not module.getOwner(card.id)
    and (
      card.type == 'property'
      or card.type == 'utility'
      or card.type == 'station'
    )
end

module.canBuyHouse = function(cellId)
  local house = houses[cellId] or 0

  if house == 5 then
    return
  end

  local cell = cellId and boardCells[cellId]
  local owner = cellId and owners[cellId]

  if not cell or not cell.header_color or not owner then
    return
  end

  local group = cellsByGroup[cell.header_color]

  if not group then
    return
  end

  for i=1, group._len do
    -- Must own all properties in the color-group
    if owners[group[i].id] ~= owner then
      return
    end

    -- Evenly distribute
    if module.getHouses(group[i].id) < house then
      return
    end
  end

  return true
end

module.canMortgage = function(cellId)
  return cellId and not mortgage[cellId]
end

module.canUnmortgage = function(cellId)
  return cellId and mortgage[cellId]
end

module.mortgage = function(cellId, state)
  mortgage[cellId] = state
end

module.showMortgage = function(cellId, target)
  if not cellId then
    for i=1, boardCells._len do
      module.showMortgage(i, target)
    end

    return
  end

  if not mortgage[cellId] then
    ui.removeImage("cell_mortgaged_" .. cellId, target)
    return
  end

  local pos = positions[cellId]

  local direction = cellDirection(cellId)
  local x, y = (pos[1] + pos[3]) / 2, (pos[2] + pos[4]) / 2
  local rotation = (direction - 1) * math.pi / 2

  if direction == 3 then -- top
    rotation = 0
  end

  ui.addImage(
    "cell_mortgaged_" .. cellId,
    img.mortgaged,
    "_60",
    x, y,
    target,
    1, 1, rotation, 1,
    0.5, 0.5
  )
end

module.canSellHouse = function(cellId)
  local house = houses[cellId] or 0

  if house == 0 then
    return
  end

  local cell = cellId and boardCells[cellId]
  local owner = cellId and owners[cellId]

  if not cell or not cell.header_color or not owner then
    return
  end

  local group = cellsByGroup[cell.header_color]

  if not group then
    return
  end

  for i=1, group._len do
    -- Must own all properties in the color-group
    if owners[group[i].id] ~= owner then
      return
    end

    -- Evenly distribute
    if module.getHouses(group[i].id) > house then
      return
    end
  end

  return true
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
  if mortgage[cell.id] then
    return 0
  end

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

  local house_count = houses[cell.id] or 0

  if house_count == 1 then
    return cell.house
  elseif house_count == 2 then
    return cell.house2
  elseif house_count == 3 then
    return cell.house3
  elseif house_count == 4 then
    return cell.house4
  elseif house_count == 5 then
    return cell.hotel
  end

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
  ui.addImage(
    "auctionfold",
    pixels.red,
    "~110",
    415, 280,
    target,
    120, 20, 0, 1,
    true
  )
  ui.addTextArea(
    "auctionfold",
    '<p align="center"><a href="event:auction_fold"><b><font size="12" color="#ffffff">FOLD',
    target,
    415, 280,
    120, 20,
    0, 0, 0,
    true
  )
end

module.hideAuctionBid = function(target)
  ui.removeTextArea("auctionfold", target)
  ui.removeImage("auctionfold", target)
  ui.removeImage("auctionpopup", target)
  ui.addPopup(
    44, 2,
    "",
    target ~= "*" and target or nil,
    -5000, -5000,
    nil, true
  )
end

module.showAuction = function(cell, fold)
  ui.addTextArea(
    "auctiontimer",
    '',
    nil,
    490, 120,
    70, 30,
    0, 0, 0,
    true
  )

  for name in pairs(tfm.get.room.playerList) do
    ui.addImage(
      "auctionui",
      img.ui,
      "~100",
      234, 100,
      name,
      1, 1, 0, 1,
      true
    )
    ui.addImage(
      "auctionsep",
      pixels.black,
      "~100",
      400 - 1, 150,
      name,
      2, 160, 0, 1,
      true
    )

    module.hideCard(name)
    showPropertyCard(cell, name, 75, 110, false)

    ui.addTextArea(
      "auctiontitle",
      translations.get("auction_title", name),
      name,
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
        translations.get(cell.title_tr, name)
      ),
      name,
      260, 150,
      120, nil,
      cell.header_color_int, cell.header_color_int, 1,
      true
    )
  end

  for player in players.iter do
    if not fold[player.name] then
      module.showAuctionBid(player.name)
    end
  end
end

module.hideAuction = function(target)
  module.hideCard(target)
  module.hideAuctionBid(target)
  ui.removeTextArea("auctiontimer", target)
  ui.removeTextArea("auctiontitle", target)
  ui.removeTextArea("auctioncard", target)
  ui.removeTextArea("auctionhighest", target)
  ui.removeTextArea("auctionplayers", target)
  ui.removeImage("auctionui", target)
  ui.removeImage("auctionsep", target)
end

module.updateAuctionTimer = function(remaining, total)
  local index = math.ceil(remaining / total * 10)

  ui.updateTextArea(
    "auctiontimer",
    string.format(
      '<font size="6" face="Verdana">%s%s<font color="#000000">%s',
      remaining <= 5 and '<R>' or '<V>',
      battery:sub(1, index * battery_cell_size),
      battery:sub(index * battery_cell_size + 1)
    )
  )
end

module.updateAuction = function(whoseTurn, highestBid, highestBidder, fold)
  local list = {}

  for player in players.iter do
    list[1 + #list] = string.format(
      '<font color="#%.6x">%s%s',
      player.color,
      fold[player.name] and '\\o ' or (whoseTurn == player.name and '&gt; ' or ''),
      player.name
    )

    if fold[player.name] then
      module.hideAuctionBid(player.name)
    end
  end

  for name in pairs(tfm.get.room.playerList) do
    ui.addTextArea(
      "auctionhighest",
      translations.get("auction_highest", name, highestBid, highestBidder),
      name,
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

module.showManageHouses = function(cell, name)
  ui.addImage(
    "houseui",
    img.ui,
    "~100",
    234, 100,
    name,
    1, 1, 0, 1,
    true
  )
  ui.addImage(
    "housesep",
    pixels.black,
    "~100",
    400 - 1, 150,
    name,
    2, 160, 0, 1,
    true
  )
  ui.addTextArea(
    "housetitle",
    translations.get("ui_house_title", name),
    name,
    234, 110,
    332, nil,
    0, 0, 0,
    true
  )

  ui.addImage(
    "buy_house",
    img.buy_house,
    "~100",
    295, 160,
    name,
    0.5, 0.5, 0, 1,
    true
  )
  ui.addTextArea(
    "buy_house",
    translations.get("buy_house", name),
    name,
    250, 160+50,
    140, nil,
    0, 0, 0,
    true
  )
  ui.addTextArea(
    "buy_house_click",
    '<font size="100"><a href="event:buy_house">' .. empty_space,
    name,
    295-5, 160-5,
    50, 50,
    0, 0, 0,
    true
  )

  ui.addImage(
    "sell_house",
    img.sell_house,
    "~100",
    295, 240,
    name,
    0.5, 0.5, 0, 1
  )
  ui.addTextArea(
    "sell_house",
    translations.get("sell_house", name),
    name,
    250, 240+50,
    140, nil,
    0, 0, 0,
    true
  )
  ui.addTextArea(
    "sell_house_click",
    '<font size="100"><a href="event:sell_house">' .. empty_space,
    name,
    295-5, 240-5,
    50, 50,
    0, 0, 0,
    true
  )

  ui.addImage(
    "unmortgage",
    img.unmortgage,
    "~100",
    455, 160,
    name,
    0.5, 0.5, 0, 1
  )
  ui.addTextArea(
    "unmortgage",
    translations.get("unmortgage", name),
    name,
    410, 160+50,
    140, nil,
    0, 0, 0,
    true
  )
  ui.addTextArea(
    "unmortgage_click",
    '<font size="100"><a href="event:unmortgage">' .. empty_space,
    name,
    455-5, 160-5,
    50, 50,
    0, 0, 0,
    true
  )

  ui.addImage(
    "mortgage",
    img.mortgage,
    "~100",
    455, 240,
    name,
    0.5, 0.5, 0, 1
  )
  ui.addTextArea(
    "mortgage",
    translations.get("mortgage", name),
    name,
    410, 240+50,
    140, nil,
    0, 0, 0,
    true
  )
  ui.addTextArea(
    "mortgage_click",
    '<font size="100"><a href="event:mortgage">' .. empty_space,
    name,
    455-5, 240-5,
    50, 50,
    0, 0, 0,
    true
  )
end

module.hideManageHouses = function(name)
  ui.removeImage("houseui", name)
  ui.removeImage("housesep", name)
  ui.removeTextArea("housetitle", name)
  ui.removeImage("buy_house", name)
  ui.removeTextArea("buy_house", name)
  ui.removeTextArea("buy_house_click", name)
  ui.removeImage("sell_house", name)
  ui.removeTextArea("sell_house", name)
  ui.removeTextArea("sell_house_click", name)
  ui.removeImage("mortgage", name)
  ui.removeTextArea("mortgage", name)
  ui.removeTextArea("mortgage_click", name)
  ui.removeImage("unmortgage", name)
  ui.removeTextArea("unmortgage", name)
  ui.removeTextArea("unmortgage_click", name)
end

module.showHouses = function(cellId, target)
  if not cellId then
    for i=1, boardCells._len do
      module.showHouses(i, target)
    end

    return
  end

  local pos = positions[cellId]
  local house_count = houses[cellId] or 0
  local is_hotel = false
  local has_hotel = house_count == 5

  local direction = cellDirection(cellId)
  local x, y = 0, 0
  local offx, offy = 0, 0
  local rotation = (direction - 1) * math.pi / 2

  if direction == 1 then -- bottom
    offx = 1
    offy = 0
    x = pos[1]
    y = pos[2] + 5
  elseif direction == 2 then -- left
    offx = 0
    offy = 1
    x = pos[3] - 5
    y = pos[2]
  elseif direction == 3 then -- top
    offx = 1
    offy = 0
    x = pos[1]
    y = pos[4] - houseSize - 5
    rotation = 0
  elseif direction == 4 then -- right
    offx = 0
    offy = -1
    x = pos[1] + 5
    y = pos[4]
  end

  local d1, d2

  for i=1, house_count + 1 do
    if i == house_count + 1 then
      ui.removeImage("house_" .. cellId .. "_" .. (house_count + 1), target)
    else
      is_hotel = i == 1 and house_count == 5
      d1 = ((has_hotel and not is_hotel and 5 or 0) + 12 * (i - 1))
      d2 = (is_hotel and 0 or 3)

      ui.addImage(
        "house_" .. cellId .. "_" .. i,
        is_hotel and img.hotel or img.house,
        "!200",
        x + offx * d1 + -offy * d2, y + offy * d1 + offx * d2,
        target,
        1, 1, rotation, 1,
        true
      )
    end
  end
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
  elseif callback == 'auction_fold' then
    eventAuctionFold(name)
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
  elseif callback == "close_house" then
    module.hideManageHouses(name)
  elseif callback == "buy_house" then
    module.hideManageHouses(name)
    eventBuyHouseClicked(name)
  elseif callback == "sell_house" then
    module.hideManageHouses(name)
    eventSellHouseClicked(name)
  elseif callback == "mortgage" then
    module.hideManageHouses(name)
    eventMortgageClicked(name)
  elseif callback == "unmortgage" then
    module.hideManageHouses(name)
    eventUnmortgageClicked(name)
  end
end

return module
