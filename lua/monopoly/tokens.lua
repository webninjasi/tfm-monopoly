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
local tokens = { _len=0 }


-- Private Functions
local function showToken(id, x, y, scale, clickable)
  x, y = x - images[id][2] * scale / 2, y - images[id][3] * scale / 2

  ui.addImage("token" .. id, images[id][1], '!1', x, y, nil, scale, scale)

  if clickable then
    ui.addTextArea(
      "token" .. id,
      '<font size="90"><a href="event:token' .. id .. '">    ',
      nil,
      x, y,
      images[id][2] * scale, images[id][3] * scale,
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
      x = x,
      y = y,
      defaultX = x,
      defaultY = y,
      scale = 1,
      active = true,
      unused = true,
    }
    showToken(i, x, y, 1, true)
    x = x + images[i][2] / 2 + 10
  end
end

monopoly.tokens.show = function()
  local token

  for i=1,tokens._len do
    token = tokens[i]

    if token.active then
      showToken(i, token.x, token.y, token.scale, token.active)
    end
  end
end

monopoly.tokens.keep = function(id)
  if tokens[id] then
    tokens[id].unused = nil
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

monopoly.tokens.update = function(tokenId, x, y, scale)
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

  showToken(tokenId, token.x, token.y, token.scale, false)
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
