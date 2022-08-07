--- monopoly.tokens

local config = pshy.require("monopoly.config")


-- Tokens Variables
local imgX = config.tokens.imgX
local imgY = config.tokens.imgY
local defaultX = config.tokens.defaultX
local defaultY = config.tokens.defaultY
local rowItems = config.tokens.rowItems
local images = config.images.tokens
local blackpx = config.images.pixels.black
local circleImage = config.images.circle
local tokens = { _len=#images }

-- Initialize tokens
do
  local x, y = 0, 0
  local widthList = {}
  local width = 0
  local startX, startY
  local maxHeight = 0

  for i=1, tokens._len do
    width = width + images[i][2] + 10
    x = x + images[i][2] / 2

    tokens[i] = {
      id = i,
      x = x,
      y = y,
      img = images[i][1],
      w = images[i][2],
      h = images[i][3],
      scale = 1,
      active = true,
      unused = true,
    }

    maxHeight = math.max(maxHeight, tokens[i].h)
    x = x + 10 + images[i][2] / 2

    if i % rowItems == 0 then
      widthList[1 + #widthList] = width - 10
      x = 0
      width = 0
      y = y + maxHeight + 10
      maxHeight = 0
    end
  end

  widthList[1 + #widthList] = width - 10

  local j = 1

  for i=1, tokens._len do
    if tokens[i].y ~= y then
      startX = defaultX - widthList[j] / 2
      j = 1 + j
      y = tokens[i].y
    end

    tokens[i].x = startX + tokens[i].x
    tokens[i].y = defaultY + tokens[i].y
    tokens[i].defaultX = tokens[i].x
    tokens[i].defaultY = tokens[i].y
  end
end

-- Private Functions
local function showToken(token, clickable)
  ui.addImage(
    "token" .. token.id,
    token.img,
    clickable and ':1' or '!1',
    token.x, token.y,
    nil,
    token.scale, token.scale,
    token.rotation, 1,
    0.5, 0.5
  )

  if token.circle then
    ui.addImage(
      "token_circle",
      circleImage,
      '!100',
      token.x, token.y,
      nil,
      token.scale, token.scale,
      0, 1,
      0.5, 0.5
    )
  end

  if clickable then
    local w = token.w * token.scale
    local h = token.h * token.scale

    ui.addTextArea(
      "token" .. token.id,
      '<font size="90"><a href="event:token' .. token.id .. '">    ',
      nil,
      token.x - w / 2, token.y - h / 2,
      w, h,
      0, 0, 0,
      true
    )
  end
end

local function hideToken(id)
  ui.removeImage("token" .. id)
  ui.removeTextArea("token" .. id)
end


-- Functions
local module = {}

module.create = function()
  for i=1, tokens._len do
    tokens[i].x = tokens[i].defaultX
    tokens[i].y = tokens[i].defaultY
    tokens[i].scale = 1
    tokens[i].active = true
    tokens[i].unused = true
  end

  module.show()
end

module.show = function()
  local token

  ui.addImage(
    "tokensbg",
    blackpx,
    ":50",
    imgX, imgY,
    nil,
    290, 120, 0, 0.9,
    0.5, 0.5
  )

  for i=1,tokens._len do
    token = tokens[i]

    if token.active then
      showToken(token, token.active)
    end
  end
end

module.keep = function(id)
  if tokens[id] then
    tokens[id].unused = nil
    ui.removeTextArea("token" .. id)
  end
end

module.hide = function(tokenid)
  local token

  if tokenid then
    token = tokens[tokenid]

    if token then
      token.active = false
      hideToken(tokenid)
    end

    return
  end

  for i=1,tokens._len do
    token = tokens[i]

    if token.unused then
      token.active = false
      hideToken(i)
    end
  end

  ui.removeImage("tokensbg")
end

module.update = function(tokenId, x, y, scale, rotation)
  local token = tokens[tokenId]

  if not token then
    return
  end

  if not x and not y then
    token.x, token.y = token.defaultX, token.defaultY
  else
    token.x, token.y = x, y
  end

  token.scale = scale
  token.rotation = rotation

  showToken(token, false)
end

module.circleMode = function(tokenId, enabled)
  local token = tokens[tokenId]

  if not token then
    return
  end

  token.circle = enabled
  showToken(token, false)
end

module.randColor = function(tokenid)
  local range = 0xffffff / tokens._len
  return math.random((tokenid - 1) * range, tokenid * range)
end


-- Events
function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 5) == 'token' then
    local tokenid = tonumber(callback:sub(6))

    if tokenid and tokens[tokenid] and eventTokenClicked then
      eventTokenClicked(name, tokenid)
    end
  end
end

return module
