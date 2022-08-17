--- monopoly.board

local config = pshy.require("monopoly.config")
local tokens = pshy.require("monopoly.tokens")


-- Board Variables
local boardCells = config.board.cells
local cellActions = {}
local houseSize = config.board.houseSize
local tokenSize = config.board.tokenSize
local tokenOffset = config.board.tokenOffset
local positions = config.board.positions
local tokenImages = config.images.tokens
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
local cellColors = {}
local movingToken


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

local function cellDirection(cellId)
  return math.ceil(cellId / 10)
end

local function cellCenter(cellId)
  if not cellId then
    return
  end

  local pos = positions[cellId]

  if not pos then
    return
  end

  local direction = cellDirection(cellId)
  local originX = pos[1] + pos[3]
  local originY = pos[2] + pos[4]

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

  return originX, originY
end

local function updateTokens(cellId)
  if not cellId then
    return
  end

  local cell = board.cells[cellId]

  if not cell or cell.count == 0 then
    return
  end

  local direction = cellDirection(cellId)
  local originX, originY = cellCenter(cellId)

  if not originX or not originY then
    return
  end

  local x, y, scale
  local index = 0
  local rotation = (direction - 1) * math.pi / 2

  scale = cellId % 10 ~= 1 and cell.count > 1 and 0.5 or 1

  for tokenId in pairs(cell) do
    if tokenId ~= 'count' then
      index = 1 + index
      x, y = getPos(index, originX, originY, scale, cell.count, tokenId)
      tokens.update(tokenId, x, y, scale, rotation)
    end
  end
end

local function getMoveTarget(cellId1, cellId2)
  local dir1 = cellDirection(cellId1)

  if cellId2 >= cellId1 and cellId2 <= dir1 * 10 + 1 then
    return cellId2
  end

  return ((dir1 * 10) % cellCount) + 1
end

local function getMoveAxis(cellId1, cellId2)
  local dir1 = cellDirection(cellId1)
  local dir2 = cellDirection(cellId2)

  if dir1 == 1 and (dir2 == 1 or dir2 == 2) then
    return "-1,0"
  end
  if dir1 == 3 and (dir2 == 3 or dir2 == 4) then
    return "1,0"
  end
  if dir1 == 2 and (dir2 == 2 or dir2 == 3) then
    return "0,-1"
  end
  if dir1 == 4 and (dir2 == 4 or dir2 == 1) then
    return "0,1"
  end
end

local function getMoveDuration(x1, y1, x2, y2)
  return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2)) * 50 / 3
end


-- Functions
local module = {}

module.reset = function()
  tokenCell = {}
  board.tokens = {}
  board.cells = {}

  for i=1, cellCount do
    board.cells[i] = { count=0 }
  end

  for id in pairs(cellColors) do
    ui.removeTextArea("cellcolor_" .. id)
  end

  cellColors = {}
  movingToken = nil
end

module.hasToken = function(tokenId)
  return not not board.tokens[tokenId]
end

module.addToken = function(tokenId)
  local token = board.tokens[tokenId]

  if token then
    return
  end

  board.tokens[tokenId] = {
    cell=nil
  }
end

module.removeToken = function(tokenId)
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

-- TODO implement counter-clockwise animation
module.moveToken = function(tokenId, cellId, relative, ignoreGo, noanim)
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
  local passedGo = not ignoreGo and prevCellId and cellId < prevCellId

  token.cell = placeToCell(cellId, tokenId)

  if movingToken then
    updateTokens(movingToken[2])

    if eventTokenMove then
      eventTokenMove(movingToken[1], movingToken[2], movingToken[3])
    end

    movingToken = nil
  end

  if not prevCellId or noanim then
    updateTokens(cellId)

    if eventTokenMove then
      eventTokenMove(tokenId, cellId, passedGo)
    end

    return
  end

  local targetCellId = getMoveTarget(prevCellId, cellId)
  local originX, originY = cellCenter(prevCellId)
  local targetX, targetY = cellCenter(targetCellId)

  movingToken = {
    tokenId,
    cellId,
    passedGo,
    targetCellId,
    os.time() + getMoveDuration(originX, originY, targetX, targetY)
  }
  tokens.animate(tokenId, originX, originY, targetX, targetY, getMoveAxis(prevCellId, targetCellId))
end

module.getTokenCell = function(tokenId)
  return tokenId and tokenCell[tokenId] and boardCells[tokenCell[tokenId]]
end

module.registerCellAction = function(cellType, fnc)
  cellActions[cellType] = fnc
end

module.cellAction = function(cellId)
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

module.showCellColor = function(cellId, target)
  if not cellId then
    for id in pairs(cellColors) do
      module.showCellColor(id, target)
    end

    return
  end

  local cell = board.cells[cellId]
  local pos = positions[cellId]
  local color = cellColors[cellId]

  if not cell or not pos or not color then
    return
  end

  local direction = cellDirection(cellId)
  local x, y = 0, 0
  local w, h = 0, 0
  local scale = 1 / 2.5
  local thickness = 1
  local offset = 10

  if direction == 1 then -- bottom
    w = (pos[3] - pos[1]) * scale
    h = thickness
    x = (pos[1] + pos[3] - w) / 2
    y = pos[2] - offset
  elseif direction == 2 then -- left
    w = thickness
    h = (pos[4] - pos[2]) * scale
    x = pos[3] + offset
    y = (pos[4] + pos[2] - h) / 2
  elseif direction == 3 then -- top
    w = (pos[3] - pos[1]) * scale
    h = thickness
    x = (pos[1] + pos[3] - w) / 2
    y = pos[4] + offset
  elseif direction == 4 then -- right
    w = thickness
    h = (pos[4] - pos[2]) * scale
    x = pos[1] - offset
    y = (pos[4] + pos[2] - h) / 2
  end

  ui.addTextArea(
    "cellcolor_" .. cellId,
    "",
    target,
    x, y, w, h,
    color, color, 1, false
  )
end

module.setCellColor = function(cellId, color)
  cellColors[cellId] = color

  if not color then
    ui.removeTextArea("cellcolor_" .. cellId)
    return
  end

  module.showCellColor(cellId)
end


-- Events
function eventLoop()
  if not movingToken or os.time() < movingToken[5] then
    return
  end

  if movingToken[4] == movingToken[2] then
    local token = movingToken

    movingToken = nil
    updateTokens(token[2])

    if eventTokenMove then
      eventTokenMove(token[1], token[2], token[3])
    end

    return
  end

  local targetCellId = getMoveTarget(movingToken[4], movingToken[2])
  local direction = cellDirection(movingToken[4])
  local originX, originY = cellCenter(movingToken[4])
  local targetX, targetY = cellCenter(targetCellId)
  local axis = getMoveAxis(movingToken[4], targetCellId)

  movingToken[4] = targetCellId
  movingToken[5] = os.time() + getMoveDuration(originX, originY, targetX, targetY)

  local rotation = (direction - 1) * math.pi / 2
  tokens.setRotation(movingToken[1], rotation)
  tokens.animate(movingToken[1], originX, originY, targetX, targetY, axis)
end


-- Init
module.reset()
updateCells()

return module
