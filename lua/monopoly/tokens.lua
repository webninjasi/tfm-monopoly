--- monopoly.tokens

local config = pshy.require("monopoly.config")
local translations = pshy.require("monopoly.translations")


-- Tokens Variables
local imgX = config.tokens.imgX
local imgY = config.tokens.imgY
local tokenColors = config.tokenColors
local defaultX = config.tokens.defaultX
local defaultY = config.tokens.defaultY
local rowItems = config.tokens.rowItems
local colorsOffset = config.tokens.colorsOffset
local images = config.images.tokens
local background = config.images.tokensbg
local circleImage = config.images.circle
local tokens = { _len=#images }
local selectedColors = {}
local colorUIx, colorUIy

tokenColors._len = #tokenColors


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
      active = false,
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

  colorUIx = startX
  colorUIy = tokens[tokens._len].y + colorsOffset
end

-- Private Functions
local function showToken(token, clickable, target, groundId)
  local upside_down = token.rotation == math.pi
  ui.addImage(
    "token" .. token.id,
    token.img,
    groundId and ('+' .. groundId) or (clickable and ':70' or '!70'),
    groundId and 0 or token.x,
    groundId and 0 or token.y,
    target,
    upside_down and -token.scale or token.scale, token.scale,
    upside_down and 0 or token.rotation, 1,
    upside_down and -0.5 or 0.5, 0.5
  )

  if token.circle then
    if groundId then
      ui.removeImage("token_circle", target)
    else
      tfm.exec.addPhysicObject(43, token.x, token.y, {
        type = 14,
        miceCollision = false,
        groundCollision = false,
      })
      tfm.exec.addPhysicObject(44, token.x, token.y, {
        dynamic = true,
        type = 14,
        mass = 1,
        miceCollision = false,
        groundCollision = false,
        foreground = true,
      })
      tfm.exec.addJoint(3, 44, 43, {
        type = 3,
        speedMotor = -1.2,
        forceMotor = 100,
      })

      ui.addImage(
        "token_circle",
        circleImage,
        '+44',
        0, 0,
        target,
        token.scale, token.scale,
        0, 1,
        0.5, 0.5
      )
    end
  end

  if clickable then
    local w = token.w * token.scale
    local h = token.h * token.scale

    ui.addTextArea(
      "token" .. token.id,
      '<font size="90"><a href="event:token' .. token.id .. '">    ',
      target,
      token.x - w / 2, token.y - h / 2,
      w, h,
      0, 0, 0,
      true
    )
  end
end

local function hideToken(id, target)
  ui.removeImage("token" .. id, target)
  ui.removeTextArea("token" .. id, target)
end

local function updateColors(target)
  local text = {'<p align="center"><font size="35" face="Verdana">'}
  local len = 1

  for i=1,tokenColors._len do
    len = 1 + len
    text[len] = string.format(
      '<font color="#%.6x"><a href="event:color%d">█</a>  ',
      selectedColors[i] and 0xFAE1D2 or tokenColors[i], i
    )

    if i % rowItems == 0 then
      len = 1 + len
      text[len] = "\n"
    end
  end

  ui.updateTextArea(
    "tokencolors",
    table.concat(text, ''),
    target
  )
end

local function showColors(target)
  ui.addTextArea(
    "tokencolors",
    '',
    target,
    colorUIx, colorUIy,
    nil, nil,
    0, 0, 0,
    true
  )
  updateColors(target)
end


-- Functions
local module = {}

module.reset = function()
  for i=1, tokens._len do
    tokens[i].x = tokens[i].defaultX
    tokens[i].y = tokens[i].defaultY
    tokens[i].scale = 1
    tokens[i].rotation = 0
    tokens[i].active = false
  end

  selectedColors = {}
end

module.showUI = function(target)
  local token

  ui.addImage(
    "tokensbg",
    background,
    ":50",
    imgX, imgY,
    target,
    1, 1, 0, 1,
    0.5, 0.5
  )
  showColors(target)

  if target == "*" then
    for name in pairs(tfm.get.room.playerList) do
      ui.addTextArea(
        "tokens_title",
        translations.get("ui_tokens_title", name),
        name,
        imgX-166, imgY-105,
        332, nil,
        0, 0, 0,
        true
      )
    end
  else
    ui.addTextArea(
      "tokens_title",
      translations.get("ui_tokens_title", target),
      target,
      imgX-166, imgY-105,
      332, nil,
      0, 0, 0,
      true
    )
  end

  for i=1,tokens._len do
    token = tokens[i]

    if not token.active then
      showToken(token, true, target)
    end
  end
end

module.hideUI = function(target)
  local token

  ui.removeImage("tokensbg", target)
  ui.removeTextArea("tokens_title", target)
  ui.removeTextArea("tokencolors", target)

  for i=1,tokens._len do
    token = tokens[i]

    if not token.active then
      hideToken(token.id, target)
    end
  end
end

module.show = function()
  local token

  for i=1,tokens._len do
    token = tokens[i]

    if token.active then
      showToken(token, false)
    end
  end
end

module.selectColor = function(id)
  selectedColors[id] = true
  updateColors()
end

module.attachGround = function(tokenId, groundId)
  local token = tokens[tokenId]

  if not token then
    return
  end

  showToken(token, false, nil, groundId)
end

module.animate = function(tokenId, x1, y1, x2, y2, axis)
  local token = tokens[tokenId]

  if not token then
    return
  end

  local limit = math.max(math.abs(x1 - x2), math.abs(y1 - y2)) / 30

  tfm.exec.addPhysicObject(76, x1, y1, {
    type = 14,
    miceCollision = false,
    groundCollision = false,
  })
  tfm.exec.addPhysicObject(77, x1, y1, {
    dynamic = true,
    type = 14,
    miceCollision = false,
    groundCollision = false,
    mass = 1,
  })
  tfm.exec.addJoint(75, 76, 77, {
    type = 1,
    axis = axis,
    speedMotor = 2,
    forceMotor = 100,
    limit2 = limit,
  })
  showToken(token, false, nil, 77)
end

module.setRotation = function(tokenId, rotation)
  local token = tokens[tokenId]

  if not token then
    return
  end

  token.rotation = rotation
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

  if not token.active then
    token.active = true
    hideToken(token.id, "*")
  end

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


-- Events
function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 5) == 'token' then
    local tokenid = tonumber(callback:sub(6))

    if tokenid and tokens[tokenid] and not tokens[tokenid].active and eventTokenClicked then
      eventTokenClicked(name, tokenid)
    end
  elseif callback:sub(1, 5) == 'color' then
    local idx = tonumber(callback:sub(6))

    if idx and tokenColors[idx] and not selectedColors[idx] and eventColorSelected then
      eventColorSelected(name, idx, tokenColors[idx])
    end
  end
end

return module
