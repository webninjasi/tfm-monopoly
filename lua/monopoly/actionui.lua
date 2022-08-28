--- monopoly.actionui

local config = pshy.require("monopoly.config")


-- Buttons
local buttons = {}

do
  local images = config.images.actionui
  local img
  local x = images.x
  local y = images.y
  local tx = images.x - images.taw / 2
  local ty = images.y - images.tah / 2
  local step = images.w + images.sep
  local spaces = string.rep(' ', 10)

  for i=1,#images do
    img = images[i]
    buttons[img[1]] = {
      key = "actionui" .. img[1],
      img = img[2],
      x = x, y = y,
      alpha = images.alpha,
      invisible = img[3],

      text = ('<font size="72"><a href="event:actionui %s">%s'):format(img[1], spaces),
      tx = tx, ty = ty,
      tw = images.taw, th = images.tah,
    }
    x = x + step
    tx = tx + step
  end
end


-- Private Functions
local function updateButton(btn, name, enabled)
  ui.addImage(
    btn.key,
    btn.img,
    ":200",
    btn.x, btn.y,
    name,
    1, 1, 0, enabled and 1 or 0.5,
    0.5, 0.5
  )

  if enabled then
    ui.addTextArea(
      btn.key,
      btn.text,
      name,
      btn.tx, btn.ty,
      btn.tw, btn.th,
      0, 0, 0,
      true
    )
  else
    ui.removeTextArea(btn.key, name)
  end
end

local function hideButton(btn, name)
  ui.removeImage(btn.key, name)
  ui.removeTextArea(btn.key, name)
end


-- Functions
local module = {}

module.show = function(name)
  for _, btn in pairs(buttons) do
    if not btn.invisible then
      updateButton(btn, name, false)
    end
  end
end

module.hide = function(name)
  for _, btn in pairs(buttons) do
    hideButton(btn, name)
  end
end

module.reset = function(name)
  for _, btn in pairs(buttons) do
    if not btn.invisible then
      updateButton(btn, name, false)
    else
      hideButton(btn, name)
    end
  end
end

module.update = function(name, action, enabled)
  local btn = buttons[action]

  if btn then
    if enabled or not btn.invisible then
      updateButton(btn, name, enabled)
    else
      hideButton(btn, name)
    end
  end
end


-- Events
function eventTextAreaCallback(id, name, callback)
  if callback:sub(1, 9) == 'actionui ' then
    local action = callback:sub(10)

    if eventActionUIClick then
      eventActionUIClick(name, action)
    end
  end
end

return module
