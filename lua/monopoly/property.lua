--- monopoly.property

monopoly = monopoly or {}

if monopoly.property then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Variables
local boardCells = monopoly.config.board.cells
local cardImages = monopoly.config.images.cards
local pixels = monopoly.config.images.pixels
local cardRows = monopoly.config.cardRows
cardRows._len = #cardRows

local owners = {}


-- Private Functions
local function showPropertyCard(cell, name, x, y, canBuy)
  local w, h = 150, 200

  ui.addTextArea(
    "cardheader",
    string.format(
      '<p align="center"><font size="15" color="#000000"><a href="event:close">%s',
      cell.title
    ),
    name,
    x + 10, y + 15,
    w - 20, 50,
    cell.header_color, cell.header_color, 1,
    true
  )
  ui.addImage("cardbg", cardImages.empty, "~150", x, y, name)

  local rows = {
    _len = 1,
    '<textformat tabstops="[90]"><font size="10" color="#000000">'
  }
  local separator = '<p align="center">' .. string.rep('━', 12) .. '</p>'
  local val, card

  for i=1, cardRows._len do
    card = cardRows[i]
    val = cell[card.key]

    if val then
      if card.key == 'house_hotel' then
        rows._len = 1 + rows._len
        rows[rows._len] = separator
      end

      rows._len = 1 + rows._len
      rows[rows._len] = string.format('%s\t<font color="#006400">$%d</font>', card.title, val)
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
    x + 10, y + 35,
    nil, nil,
    0, 0, 0,
    true
  )
end


-- Public Functions
monopoly.property = {}

monopoly.property.reset = function()
  owners = {}
end

monopoly.property.getOwner = function(key)
  return key and owners[key]
end

monopoly.property.setOwner = function(key, owner)
  if key then
    owners[key] = owner
  end
end

monopoly.property.canBuy = function(card)
  return not monopoly.property.getOwner(card.id)
    and (
      card.type == 'property'
      or card.type == 'utility'
      or card.type == 'station'
    )
end

monopoly.property.hideCard = function(name)
  ui.removeTextArea("cardheader", name)
  ui.removeTextArea("cardinfo", name)
  ui.removeTextArea("cardbtnbuy", name)
  ui.removeTextArea("cardbtnauction", name)
  ui.removeImage("cardbg", name)
  ui.removeImage("cardbtnbuy", name)
  ui.removeImage("cardbtnauction", name)
end

monopoly.property.showCard = function(cell, name, canBuy)
  if cell.type == 'property' then
    showPropertyCard(cell, name, 325, 100, canBuy)
  end
end

monopoly.property.calculateRent = function(cell)
  -- TODO house/hotel/utility rents
  return cell.rent
end

monopoly.property.auctionStart = function(cell)

end


-- Events
function eventTextAreaCallback(id, name, callback)
  if id == ui.textAreaId("cardheader") then
    monopoly.property.hideCard(name)
  elseif id == ui.textAreaId("cardbtnbuy") then
    if eventBuyCardClick then
      eventBuyCardClick(name)
    end
  elseif id == ui.textAreaId("cardbtnauction") then
    if eventAuctionCardClick then
      eventAuctionCardClick(name)
    end
  end
end
