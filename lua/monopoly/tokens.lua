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
local function showToken(id, x, y)
  x, y = x - images[id][2] / 2, y - images[id][3] / 2

  ui.addImage("token" .. id, images[id][1], '!1', x, y)
  ui.addTextArea(
    "token" .. id,
    '<font size="90"><a href="event:token' .. id .. '">    ',
    nil,
    x, y,
    images[id][2], images[id][3],
    0, 0, 0,
    false
  )
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
    }
    showToken(i, x, y)
    x = x + images[i][2] / 2 + 10
  end
end

monopoly.tokens.show = function()
  local token

  for i=1,tokens._len do
    token = tokens[i]
    showToken(i, token.x, token.y)
  end
end

monopoly.tokens.update = function(tokenId, x, y)
  local token = tokens[tokenId]

  if not token then
    return
  end

  if not x and not y then
    token.x, token.y = token.defaultX, token.defaultY
  else
    token.x, token.y = x, y
  end

  showToken(tokenId, token.x, token.y)
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
