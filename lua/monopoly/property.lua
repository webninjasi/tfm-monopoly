--- monopoly.property

local config = pshy.require("monopoly.config")
local translations = pshy.require("monopoly.translations")
local players = pshy.require("monopoly.players")
local board = pshy.require("monopoly.board")


-- Variables
local img = config.images
local boardCells = config.board.cells
local auctionUI = config.auctionUI
local houseSize = config.board.houseSize
local positions = config.board.positions
local cellCount = #boardCells
local cardImages = config.images.cards
local pixels = config.images.pixels

local owners = {}
local houses = {}
local mortgage = {}
local viewing_card = {}

local cellsByGroup = {}
local cellsByType = {}
local separator = '<p align="center">' .. string.rep('━', 12) .. '</p>'
local empty_space = '<font size="80">' .. string.rep(' ', 8)

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
    cell.title = "board_" .. i
    cell.card_title = "card_" .. i
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
      cell.card_width = 140

      if cell.type == 'chance' or cell.type == 'jailvisit' then
        cell.infoY = 50
      end
    end

    list._len = 1 + list._len
    list[list._len] = cell
  end

  -- Used in eventMouse
  positions[0] = positions[40]
  positions[41] = positions[1]
  boardCells[0] = boardCells[40]
  boardCells[41] = boardCells[1]
end

local function hideCard(name, cell)
  if name then
    if cell and viewing_card[name] ~= cell then
      return
    end

    viewing_card[name] = nil
  else
    viewing_card = {}
  end

  ui.removeTextArea("cardheader", name)
  ui.removeTextArea("cardinfo", name)
  ui.removeTextArea("cardbtnbuy", name)
  ui.removeTextArea("cardbtnauction", name)
  ui.removeImage("cardbg", name)
  ui.removeImage("cardbtnbuy", name)
  ui.removeImage("cardbtnauction", name)
end

local function showPropertyCard(cell, name, x, y, canBuy)
  hideCard(name)

  if name then
    if viewing_card[name] == cell then
      return
    end

    viewing_card[name] = cell
  end

  local w, h = 150, 200

  if cell.type == 'property' then
    translations.addTextArea(
      "cardheader",
      'ui_property_title', { cell.card_title },
      name,
      x + 10, y + 15,
      w - 20, 50,
      cell.header_color_int, cell.header_color_int, 1,
      true
    )
  end

  ui.addImage("cardbg", cell.card_image, "~150", x, y, name)

  if canBuy then
    ui.addImage("cardbtnbuy", pixels.black, "~160", x, y + 205, name, 70, 20, 0, 0.8)
    ui.addImage("cardbtnauction", pixels.black, "~160", x + 80, y + 205, name, 70, 20, 0, 0.8)
    translations.addTextArea(
      "cardbtnbuy",
      'ui_button_buy', nil,
      name,
      x, y + 205,
      70, nil,
      0, 0, 0,
      true
    )
    translations.addTextArea(
      "cardbtnauction",
      'ui_button_auction', nil,
      name,
      x + 80, y + 205,
      70, nil,
      0, 0, 0,
      true
    )
  end

  translations.addTextArea(
    "cardinfo",
    'cardinfo_' .. cell.type, {
      cell,
      separator,
    },
    name,
    x + 5, y + cell.infoY,
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
  hideCard()
end

module.showButtons = function(target)
  local pos

  for i=1, cellCount do
    pos = positions[i]
    ui.addTextArea(
      "boardcell_" .. i,
      '<a href="event:boardcell_' .. i .. '">' .. empty_space,
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

module.get = function(cellId)
  return cellId and boardCells[cellId]
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
    houses[cellId] = nil
    mortgage[cellId] = nil
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
  if mortgage[cellId] then
    return
  end

  local house = houses[cellId] or 0

  if house == 5 then
    return
  end

  local cell = cellId and boardCells[cellId]
  local owner = cellId and owners[cellId]

  if not cell or not cell.header_color or not owner or cell.type ~= 'property' then
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

    if mortgage[group[i].id] then
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
  local cell = cellId and boardCells[cellId]

  if not cell then
    return
  end

  if mortgage[cellId] or module.getHouses(cellId) > 0 then
    return
  end

  local group = cellsByGroup[cell.header_color]

  if not group then
    return
  end

  for i=1, group._len do
    if module.getHouses(group[i].id) ~= 0 then
      return
    end
  end

  return true
end

module.canTrade = function(cellId)
  return cellId and not mortgage[cellId]
end

module.canTradeAll = function(trade_cards, houses_allowed)
  for _, cell in pairs(trade_cards) do
    local group = cellsByGroup[cell.header_color]

    if group then
      local have_all = true
      local have_house = false

      for i=1, group._len do
        if not trade_cards[group[i].id] then
          have_all = false
        end

        if module.getHouses(group[i].id) > 0 then
          if not houses_allowed then
            return false
          end

          have_house = true
        end
      end

      if have_house and not have_all then
        return false
      end
    end
  end

  return true
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

  if direction == 1 then -- bottom
    y = y + houseSize / 2
  elseif direction == 2 then -- left
    x = x - houseSize / 2
  elseif direction == 3 then -- top
    y = y - houseSize / 2
    rotation = 0
  elseif direction == 4 then -- right
    x = x + houseSize / 2
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

module.hideCard = function(name, cell)
  hideCard(name, cell)
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
    340-35, 25+415,
    120, false
  )

  ui.addImage(
    "auctionfold",
    pixels.red,
    "!110",
    auctionUI.x + 181, auctionUI.y + 180,
    target,
    120, 20, 0, 1
  )
  translations.addTextArea(
    "auctionfold",
    'ui_auction_fold', nil,
    target,
    auctionUI.x + 181, auctionUI.y + 180,
    120, 20,
    0, 0, 0,
    false
  )
end

module.hideAuctionBid = function(target)
  ui.removeTextArea("auctionfold", target)
  ui.removeImage("auctionfold", target)
  ui.addPopup(
    44, 2,
    "",
    target,
    -5000, -5000,
    nil, true
  )
end

module.showAuction = function(cell, fold)
  ui.addTextArea(
    "auctiontimer",
    '',
    nil,
    auctionUI.x + 256, auctionUI.y + 20,
    70, 30,
    0, 0, 0,
    false
  )
  ui.addImage(
    "auctionui",
    img.ui,
    "!100",
    auctionUI.x, auctionUI.y,
    nil,
    1, 1, 0, 1
  )
  ui.addImage(
    "auctionsep",
    pixels.black,
    "!100",
    auctionUI.x + 166 - 1, auctionUI.y + 50,
    nil,
    2, 160, 0, 1
  )
  showPropertyCard(cell, nil, 75 + 50, 110, false)

  translations.addTextArea(
    "auctiontitle",
    'ui_auction_title', nil,
    name,
    auctionUI.x, auctionUI.y + 10,
    332, nil,
    0, 0, 0,
    false
  )
  translations.addTextArea(
    "auctioncard",
    'ui_auction_card', { cell.id, cell.card_title },
    name,
    auctionUI.x + 26, auctionUI.y + 50,
    120, nil,
    cell.header_color_int, cell.header_color_int, 1,
    false
  )

  for player in players.iter do
    if not fold[player.name] then
      module.showAuctionBid(player.name)
    end
  end
end

module.hideAuction = function(target)
  hideCard(target)
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
      '<font size="6">%s%s<font color="#000000">%s',
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

  translations.addTextArea(
    "auctionhighest",
    'ui_auction_highest', { highestBid, highestBidder },
    nil,
    auctionUI.x + 16, auctionUI.y + 90, -- there is a 10px space for long property names
    140, nil,
    0, 0, 0,
    false
  )

  ui.addTextArea(
    "auctionplayers",
    table.concat(list, '\n'),
    nil,
    auctionUI.x + 176, auctionUI.y + 50,
    nil, nil,
    0, 0, 0,
    false
  )
end

module.showManageHouses = function(name)
  ui.addImage(
    "houseui",
    img.ui,
    "~100",
    234, 100,
    name,
    1, 1, 0, 1
  )
  ui.addImage(
    "housesep",
    pixels.black,
    "~100",
    400 - 1, 150,
    name,
    2, 160, 0, 1
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
    0.5, 0.5, 0, 1
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
    '<a href="event:buy_house">' .. empty_space,
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
    '<a href="event:sell_house">' .. empty_space,
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
    '<a href="event:unmortgage">' .. empty_space,
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
    '<a href="event:mortgage">' .. empty_space,
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

  for i=1, 5 do
    if i > house_count then
      ui.removeImage("house_" .. cellId .. "_" .. i, target)
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
        1, 1, rotation, 1
      )
    end
  end
end

module.getPositions = function(cellId)
  return cellId and positions[cellId]
end


-- Events
function eventInit()
  scanBoardCells()
end

local bottom_line = positions[1][4]
local top_line = positions[21][2]

function eventMouse(name, x, y)
  if x < 0 or x > 800 or y < top_line or y > bottom_line then
    return
  end

  local bx = 1 + math.floor(x / 800 * 11)
  local by = 1 +  math.floor((y - top_line) / 800 * 11)

  if bx < 10 and bx > 2 and by < 10 and by > 2 then
    return
  end

  local idx, pos

  if by == 11 or by == 10 then
    idx = 11 - bx + 1
  elseif bx == 1 or bx == 2 then
    idx = 11 + 11 - by
  elseif by == 1 or by == 2 then
    idx = 21 + bx - 1
  elseif bx == 11 or bx == 10 then
    idx = 31 + by - 1
  else
    return
  end

  for id=idx - 1, idx + 1 do
    pos = positions[id]

    if x >= pos[1] and x <= pos[3] and y >= pos[2] and y <= pos[4] then
      local cell = id and boardCells[id]

      if board.isOverlayEnabled(cell.id) then
        return
      end

      eventPropertyClicked(name, cell)
      break
    end
  end
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
    hideCard(name)
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
      showPropertyCard(cell, name, 75 + 50, 110, false)
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
