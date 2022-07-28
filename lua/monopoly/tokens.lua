--- monopoly.tokens

monopoly = monopoly or {}

if monopoly.tokens then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Tokens Variables
local defaultX = monopoly.config.tokens.defaultX
local defaultY = monopoly.config.tokens.defaultY
local images = monopoly.config.images.tokens
local circleImage = monopoly.config.images.circle
local tokens = { _len=0 }


-- Private Functions
local function showToken(token, clickable)
  ui.addImage(
    "token" .. token.id,
    token.img,
    '!1',
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
      false
    )
  end
end

local function hideToken(id)
  ui.removeImage("token" .. id)
  ui.removeTextArea("token" .. id)
end


-- Functions
monopoly.tokens = {}

monopoly.tokens.create = function()
  local x, y = defaultX, defaultY
  tokens._len = #images

  for i=1,tokens._len do
    x = x + images[i][2] / 2
    tokens[i] = {
      id = i,
      x = x,
      y = y,
      img = images[i][1],
      w = images[i][2],
      h = images[i][3],
      defaultX = x,
      defaultY = y,
      scale = 1,
      active = true,
      unused = true,
    }
    showToken(tokens[i], true)
    x = x + images[i][2] / 2 + 10
  end
end

monopoly.tokens.show = function()
  local token

  for i=1,tokens._len do
    token = tokens[i]

    if token.active then
      showToken(token, token.active)
    end
  end
end

monopoly.tokens.keep = function(id)
  if tokens[id] then
    tokens[id].unused = nil
    ui.removeTextArea("token" .. id)
  end
end

monopoly.tokens.hide = function(tokenid)
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
end

monopoly.tokens.update = function(tokenId, x, y, scale, rotation)
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

monopoly.tokens.circleMode = function(tokenId, enabled)
  local token = tokens[tokenId]

  if not token then
    return
  end

  token.circle = enabled
  showToken(token, false)
end

monopoly.tokens.randColor = function(tokenid)
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
