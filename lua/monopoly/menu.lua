--- monopoly.menu

local config = pshy.require("monopoly.config")
local translations = pshy.require('monopoly.translations')

local img = config.images.menu
local cfg = config.menu

local toggled = {}


local function showMenuButton(target)
  ui.addTextArea(
    "menu_button",
    '<b><ROSE><font size="18"><a href="event:menu">?',
    target,
    20, 20,
    nil, nil,
    0, 0, 0, false
  )
end

local function hideMenu(target)
  toggled[target] = nil

  ui.removeImage("menu_bg", target)
  ui.removeImage("menu_tab", target)
  ui.removeTextArea("menu_content", target)

  for i=1, cfg.tabs do
    ui.removeTextArea("menu_tab_" .. i, target)
  end
end

local function showMenu(target, tabidx)
  if not tabidx then
    tabidx = 1
  end

  if tabidx < 1 or tabidx > cfg.tabs then
    return
  end

  toggled[target] = true

  ui.addImage(
    "menu_bg",
    img.bg, ":1",
    400, 200,
    target,
    1, 1, 0, 1, 0.5, 0.5
  )
  ui.addImage(
    "menu_tab",
    img.tab, ":2",
    233, 125 + (tabidx - 1) * 50,
    target,
    1, 1, 0, 1, 0.5, 0.5
  )

  for i=1, cfg.tabs do
    ui.addTextArea(
      "menu_tab_" .. i,
      '<BL><a href="event:menu ' .. i .. '">' .. translations.get('menu_tab_' .. i, target),
      target,
      200, 115 + (i - 1) * 50,
      nil, nil,
      0, 0, 1, true
    )
  end

  ui.addTextArea(
    "menu_content",
    translations.get('menu_content_' .. tabidx, target),
    target,
    270, 65,
    320, 275,
    0, 0, 1, true
  )
end

local function toggleMenu(target)
  if toggled[target] then
    hideMenu(target)
  else
    showMenu(target)
  end
end


function eventInitPlayer(name)
  tfm.exec.bindKeyboard(name, 72, true, true)
  showMenuButton(name)
end

function eventKeyboard(name, key, down, x, y)
  if key == 72 then
    toggleMenu(name)
  end
end

function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 4) == 'menu' then
    local tabidx = tonumber(callback:sub(6, 6)) or 1
    showMenu(name, tabidx)
  end
end
