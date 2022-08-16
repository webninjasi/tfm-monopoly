--- lays.ui
--
-- @author TFM:Lays#1146

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

  ui.addTextArea = function(key, text, target, ...)
    target = target ~= "*" and target or nil
    addTextArea(getId(key), text, target, ...)
  end

  ui.removeTextArea = function(key, target, ...)
    target = target ~= "*" and target or nil
    removeTextArea(getId(key), target, ...)
  end

  ui.updateTextArea = function(key, text, target, ...)
    target = target ~= "*" and target or nil
    updateTextArea(getId(key), text, target, ...)
  end

  ui.textAreaId = getId
end

do
  local keyToId = {}
  local keyToIdPlayer = {}

  local addImage = tfm.exec.addImage
  local removeImage = tfm.exec.removeImage
    
  ui._imageCleanup = function(name)
    if keyToIdPlayer[name] then
        keyToIdPlayer[name] = nil
    end
  end

  ui.addImage = function(key, imageId, target, x, y, name, ...)
    if name == "*" then
      for pname in pairs(tfm.get.room.playerList) do
        ui.addImage(key, imageId, target, x, y, pname, ...)
      end

      return
    end

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
    if name == "*" then
      for pname in pairs(tfm.get.room.playerList) do
        ui.removeImage(key, pname, ...)
      end

      return
    end

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

  function eventPlayerLeft(name)
    ui._imageCleanup(name)
  end
end
