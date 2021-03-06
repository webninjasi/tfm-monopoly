--- monopoly.board

monopoly = monopoly or {}

if monopoly.board then
  return
end


-- Dependencies
pshy.require("monopoly.config")
pshy.require("monopoly.tokens")


-- Board Variables
local boardCells = monopoly.config.board.cells
local cellActions = {}
local houseSize = monopoly.config.board.houseSize
local tokenSize = monopoly.config.board.tokenSize
local tokenOffset = monopoly.config.board.tokenOffset
local positions = monopoly.config.board.positions
local tokenImages = monopoly.config.images.tokens
local cellCount = #positions
local tokenPos = {
  { 0, 0 }, -- 1 token
  { -1, 0, 1, 0 }, -- 2 tokens
  { -1, -1, 1, -1, 0, 1 }, -- 3 tokens
  { -1, -1, 1, -1, -1, 1, 1, 1 }, -- 4 tokens
  { -1, -1, 1, -1, -1, 1, 1, 1, 0, 2 }, -- 5 tokens
  { -1, -2, 1, -2, -1, 0, 1, 0, -1, 2, 1, 2 }, -- 6 tokens
}
local board = {}
local tokenCell = {}


-- Private Functions
local function updateCells()
  for i=1, #boardCells do
    boardCells[i].id = i
    boardCells[i].header_color = boardCells[i].header_color and tonumber(boardCells[i].header_color, 16)
  end
end

local function getPos(index, x, y, scale, count, tokenId)
  if index > count or index < 1 or not tokenImages[tokenId] then
    return x, y
  end

  local offX = tokenImages[tokenId][2] * scale / 2 + 1
  local offY = tokenImages[tokenId][3] * scale / 2 + 1

  return x + offX * tokenPos[count][index * 2 - 1],
         y + offY * tokenPos[count][index * 2]
end

local function placeToCell(cellId, tokenId)
  if not cellId or not tokenId then
    return
  end

  local token = board.tokens[tokenId]
  local cell = board.cells[cellId]

  if not cell or not token then
    return
  end

  if not cell[tokenId] then
    cell.count = 1 + cell.count
    cell[tokenId] = token
    tokenCell[tokenId] = cellId
  end

  return cellId
end

-- must be used before placeToCell so tokenCell can work properly
local function removeFromCell(cellId, tokenId)
  if not cellId or not tokenId then
    return
  end

  local cell = board.cells[cellId]

  if not cell then
    return
  end

  if cell[tokenId] then
    cell.count = -1 + cell.count
    cell[tokenId] = nil
    tokenCell[tokenId] = nil
  end
end

local function updateTokens(cellId)
  if not cellId then
    return
  end

  local cell = board.cells[cellId]
  local pos = positions[cellId]

  if not cell or not pos or cell.count == 0 then
    return
  end

  local direction = math.ceil(cellId / 10)
  local originX = pos[1] + pos[3]
  local originY = pos[2] + pos[4]
  local x, y, scale
  local index = 0
  local rotation = (direction - 1) * math.pi / 2

  if cellId % 10 ~= 1 then -- corners
    if direction == 1 then -- bottom
      originY = originY + houseSize
    elseif direction == 2 then -- left
      originX = originX - houseSize
    elseif direction == 3 then -- top
      originY = originY - houseSize
    elseif direction == 4 then -- right
      originX = originX + houseSize
    end
  end

  originX = originX / 2
  originY = originY / 2
  scale = cellId % 10 ~= 1 and cell.count > 1 and 0.5 or 1

  for tokenId in pairs(cell) do
    if tokenId ~= 'count' then
      index = 1 + index
      x, y = getPos(index, originX, originY, scale, cell.count, tokenId)
      monopoly.tokens.update(tokenId, x, y, scale, rotation)
    end
  end
end


-- Functions
monopoly.board = {}

monopoly.board.reset = function()
  tokenCell = {}
  board.tokens = {}
  board.cells = {}

  for i=1, cellCount do
    board.cells[i] = { count=0 }
  end
end

monopoly.board.hasToken = function(tokenId)
  return not not board.tokens[tokenId]
end

monopoly.board.addToken = function(tokenId)
  local token = board.tokens[tokenId]

  if token then
    return
  end

  board.tokens[tokenId] = {
    cell=nil
  }
end

monopoly.board.removeToken = function(tokenId)
  local token = board.tokens[tokenId]

  if not token then
    return
  end

  if token.cell then
    removeFromCell(token.cell, tokenId)
  end

  board.tokens[tokenId] = nil
  board.cells[tokenId] = nil
end

monopoly.board.moveToken = function(tokenId, cellId, relative)
  local token = board.tokens[tokenId]

  if not token then
    return
  end

  if token.cell then
    removeFromCell(token.cell, tokenId)
    updateTokens(token.cell)
  end

  if relative then
    cellId = ((token.cell + cellId - 1) % cellCount) + 1
  end

  local prevCellId = token.cell
  token.cell = placeToCell(cellId, tokenId)
  updateTokens(cellId)

  if eventTokenMove then
    eventTokenMove(tokenId, cellId, prevCellId and cellId < prevCellId)
  end
end

monopoly.board.getTokenCell = function(tokenId)
  return tokenId and tokenCell[tokenId] and boardCells[tokenCell[tokenId]]
end

monopoly.board.registerCellAction = function(cellType, fnc)
  cellActions[cellType] = fnc
end

monopoly.board.cellAction = function(cellId)
  local cell = boardCells[cellId]

  if not cell then
    return
  end

  local action = cellActions[cell.type]

  if not action then
    return
  end

  return action(cell)
end

-- Init
monopoly.board.reset()
updateCells()
