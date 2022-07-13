--- lays.ui
--
-- @author TFM:Lays#1146

if _G.__lays_ui then
  return
end

_G.__lays_ui = true

do
  local keyToId = {}
  local lastId = 0

  local function getId(key)
    if key == nil then
      return
    end

    if not keyToId[key] then
      keyToId[key] = lastId
      lastId = 1 + lastId
    end

    return keyToId[key]
  end

  local addTextArea = ui.addTextArea
  local removeTextArea = ui.removeTextArea
  local updateTextArea = ui.updateTextArea

  ui.addTextArea = function(key, ...)
    addTextArea(getId(key), ...)
  end

  ui.removeTextArea = function(key, ...)
    removeTextArea(getId(key), ...)
  end

  ui.updateTextArea = function(key, ...)
    updateTextArea(getId(key), ...)
  end

  ui.textAreaId = getId
end

do
  local keyToId = {}
  local keyToIdPlayer = {}

  local addImage = tfm.exec.addImage
  local removeImage = tfm.exec.removeImage

  function eventPlayerLeft(name)
    if keyToIdPlayer[name] then
      keyToIdPlayer[name] = nil
    end
  end

  ui.addImage = function(key, imageId, target, x, y, name, ...)
    local id = addImage(imageId, target, x, y, name, ...)

    if id then
      if name then
        keyToIdPlayer[name] = keyToIdPlayer[name] or {}

        -- Removes previous image
        if keyToIdPlayer[name][key] then
          removeImage(keyToIdPlayer[name][key])
        end

        keyToIdPlayer[name][key] = id
      else
        -- Removes previous image
        if keyToId[key] then
          removeImage(keyToId[key])
        end

        keyToId[key] = id
      end
    end
  end

  ui.removeImage = function(key, name, ...)
    local id

    if name then
      id = keyToIdPlayer[name] and keyToIdPlayer[name][key]
    else
      id = keyToId[key]
    end

    if id then
      removeImage(id, ...)

      if name then
        keyToIdPlayer[name][key] = nil
      else
        keyToId[key] = nil
      end
    end
  end
end
