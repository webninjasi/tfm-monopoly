--- monopoly.emoticons

local config = pshy.require("monopoly.config")
local command_list = pshy.require("pshy.commands.list")

local cfg = config.emoticon
local emoticons = config.images.emoticons

local move_button = '<p align="left"><font size="20" color="#%.6x"><a href="event:move_ui">⛶</a></font></p>'
local key_shift = {}
local key_alt = {}
local key_ctrl = {}
local moving_ui = {}
local timeout = {}
local emoticon_list = {}
local coords = {}
local toggle_state = {}


local function generateList()
  local list = { move_button .. '<textformat leading="7"><font size="20" face="Verdana">' }
  
  for i=1, #emoticons do
    if emoticons[i][2] and emoticons[i][3] then
      emoticons[i][4] = math.min(32 / emoticons[i][2], 32 / emoticons[i][3])
      emoticons[i][5] = emoticons[i][4]
    end

    list[1 + i] = '<a href="event:emoticon_' .. i .. '">     </a>'
  end

  emoticon_list = list
end
generateList()

local function hide(name)
  ui.removeImage("emoticon_" .. name)
end

local function show(name, id)
  if not id or not emoticons[id] then
    return
  end

  if timeout[name] then
    if timeout[name] - cfg.duration + 100 > os.time() then
      return
    end

    hide(name)
  end

  local player = tfm.get.room.playerList[name]
  local facingLeft = player and not player.isFacingRight
  local emoticon = emoticons[id]

  timeout[name] = os.time() + cfg.duration
  ui.addImage(
    "emoticon_" .. name,
    emoticon[1],
    '%' .. name,
    0, -32,
    nil,
    (facingLeft and 1 or -1), 1, 0, 1,
    facingLeft and 0.5 or -0.5, 1,
    false
  )
end

local function showList(target, x, y)
  ui.addImage(
    'emoticon_ui_bg',
    config.images.pixels.black,
    '!290',
    x - 15, y,
    target,
    60, 32 * (#emoticons + 1) + 10, 0, 0.8,
    0, 0,
    false
  )

  for i=1, #emoticons do
    ui.addImage(
      'emoticon_ui_' .. i,
      emoticons[i][1],
      '!300',
      x, y + i * 32 + 28,
      target,
      emoticons[i][4] or 1, emoticons[i][5] or 1, 0, 1,
      0, 1,
      false
    )
  end

  ui.addTextArea(
    "emoticons",
    table.concat(emoticon_list, '\n'),
    target,
    x, y,
    nil, nil,
    0, 0, 0,
    false
  )
end

local function hideList(target)
  ui.removeImage('emoticon_ui_bg', target)

  for i=1, #emoticons do
    ui.removeImage('emoticon_ui_' .. i, target)
  end

  ui.removeTextArea('emoticons', target)
end


-- Events
function eventNewGame()
  for name in pairs(tfm.get.room.playerList) do
    if toggle_state[name] then
      local xy = coords[name]
      showList(name, xy and xy[1] or cfg.x, xy and xy[2] or cfg.y)
    end
  end
end

function eventLoop()
  local now = os.time()
  local remaining = {}

  for name, time in pairs(timeout) do
    if now > time then
      hide(name)
    else
      remaining[name] = time
    end
  end

  timeout = remaining
end

function eventInitPlayer(name)
  for _, key in pairs({ 16, 17, 18 }) do
    tfm.exec.bindKeyboard(name, key, true, true)
    tfm.exec.bindKeyboard(name, key, false, true)
  end

  for i=0, 9 do
    tfm.exec.bindKeyboard(name, 96 + i, true, true) -- numpad
    tfm.exec.bindKeyboard(name, 112 + i, true, true) -- f1-10
  end
end

function eventKeyboard(name, key, down, x, y)
  if key == 16 then
    key_shift[name] = down or nil

  elseif key == 17 then
    key_ctrl[name] = down or nil

  elseif key == 18 then
    key_alt[name] = down or nil

  elseif key >= 96 and key <= 96 + 9 then -- numpad
    if key_alt[name] or key_ctrl[name] then
      local id = key - 96 + (key_ctrl[name] and 11 or 1)
      show(name, id)
    end

  elseif key >= 112 and key <= 112 + 9 then -- f1-10
    if key_shift[name] or key_ctrl[name] then
      local id = key - 112 + (key_ctrl[name] and 11 or 1)
      show(name, id)
    end

  end
end

function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 9) == 'emoticon_' then
    local id = tonumber(callback:sub(10))

    if id then
      show(name, id)
    end
  end
end

function eventTextAreaMove(id, name, x, y)
  if id == ui.textAreaId("emoticons") then
    coords[name] = {x,y}
    showList(name, x, y)
  end
end

command_list["emoticons"] = {
  perms = "everyone",
  func = function(name)
    toggle_state[name] = not toggle_state[name]

    if toggle_state[name] then
      local xy = coords[name]
      showList(name, xy and xy[1] or cfg.x, xy and xy[2] or cfg.y)
    else
      hideList(name)
    end
  end,
  desc = "browse emoticons",
}
