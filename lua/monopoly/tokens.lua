--- monopoly.tokens

monopoly = monopoly or {}

if monopoly.tokens then
  return
end


-- Dependencies
pshy.require("monopoly.config")


-- Tokens Variables
local tokens = { _len=0 }


-- Private Functions
local function showToken(id, img, x, y)
  ui.addImage("token" .. id, img, '!1', x, y)
  ui.addTextArea(
    "token" .. id,
    '<font size="40"><a href="event:token' .. id .. '">  ',
    nil,
    x, y,
    40, 40,
    0, 0, 0,
    false
  )
end


-- Functions
monopoly.tokens = {}

monopoly.tokens.create = function()
  local x, y = monopoly.config.tokens.defaultX, monopoly.config.tokens.defaultY
  local images = monopoly.config.images.tokens
  tokens._len = #images

  for i=1,tokens._len do
    tokens[i] = {
      img = images[i],
      x = x,
      y = y,
      defaultX = x,
      defaultY = y,
    }
    showToken(i, images[i], x, y)
    x = x + 60
  end
end

monopoly.tokens.show = function()
  local token

  for i=1,tokens._len do
    token = tokens[i]
    showToken(i, token.img, token.x, token.y)
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

  showToken(tokenId, token.img, token.x, token.y)
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
