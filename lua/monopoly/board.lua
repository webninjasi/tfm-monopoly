--- monopoly.board

monopoly = monopoly or {}

if monopoly.board then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Board Variables
local houseSize = monopoly.config.board.houseSize
local tokenSize = monopoly.config.board.tokenSize
local tokenOffset = monopoly.config.board.tokenOffset
local positions = monopoly.config.board.positions
local cellCount = #positions
local tokenPos = {
  { 0, 0 }, -- 1 token
  { -1, 0, 1, 0 }, -- 2 tokens
  { -1, -1, 1, -1, 0, 1 }, -- 3 tokens
  { -1, -1, 1, -1, -1, 1, 1, 1 }, -- 4 tokens
}
local board = {}


-- Private Functions
local function getPos(index, x, y, count)
  local off = tokenSize / 2 + tokenOffset / 2

  x, y = x - tokenSize / 2, y - tokenSize / 2

  if index > count or index < 1 then
    return x, y
  end

  return x + off * tokenPos[count][index * 2 - 1],
         y + off * tokenPos[count][index * 2]
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
  end

  return cellId
end

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

  local originX = (pos[1] + pos[3]) / 2
  local originY = (pos[2] + pos[4] + houseSize) / 2
  local x, y
  local index = 0

  for tokenId in pairs(cell) do
    if tokenId ~= 'len' then
      index = 1 + index
      x, y = getPos(index, originX, originY, cell.count)
      monopoly.tokens.update(tokenId, x, y)
    end
  end
end


-- Functions
monopoly.board = {}

monopoly.board.reset = function()
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
  end

  local prevCellId = cellId

  if relative then
    cellId = ((token.cell + cellId - 1) % cellCount) + 1
  end

  token.cell = placeToCell(cellId, tokenId)
  updateTokens(cellId)

  if eventTokenMove then
    eventTokenMove(tokenId, cellId, cellId < prevCellId)
  end
end

-- Init
monopoly.board.reset()
