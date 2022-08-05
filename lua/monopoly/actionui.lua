--- monopoly.actionui

local config = pshy.require("monopoly.config")


-- Buttons
local buttons = {}

do
  local images = config.images.actionui
  local img
  local x = images.x - images.w / 2
  local y = images.y - images.h / 2
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
      enabled = img[3],

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
    "!200",
    btn.x, btn.y,
    name,
    1, 1, 0, enabled and 1 or btn.alpha
  )

  if enabled then
    ui.addTextArea(
      btn.key,
      btn.text,
      name,
      btn.tx, btn.ty,
      btn.tw, btn.th,
      0, 0, 0,
      false
    )
  else
    ui.removeTextArea(btn.key, name)
  end
end


-- Functions
local module = {}

module.show = function(name)
  for _, btn in pairs(buttons) do
    updateButton(btn, name, btn.enabled)
  end
end

module.hide = function(name)
  for _, btn in pairs(buttons) do
    ui.removeImage(btn.key, name)
    ui.removeTextArea(btn.key, name)
  end
end

module.update = function(name, action, enabled)
  if not action then
    for action in pairs(buttons) do
      module.update(name, action, enabled)
    end

    return
  end

  local btn = buttons[action]

  if btn then
    updateButton(btn, name, enabled)
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
