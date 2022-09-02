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
    addTextArea(getId(key), text, target, ...)
  end

  ui.removeTextArea = function(key, target, ...)
    removeTextArea(getId(key), target, ...)
  end

  ui.updateTextArea = function(key, text, target, ...)
    updateTextArea(getId(key), text, target, ...)
  end

  ui.textAreaId = getId
end

do
  local imageIds = {}

  local addImage = tfm.exec.addImage
  local removeImage = tfm.exec.removeImage

  ui._imageCleanup = function(name)
    if imageIds[name] then
      imageIds[name] = nil
    end
  end

  ui.addImage = function(key, imageId, target, x, y, name, ...)
    if not name then
      for pname in pairs(tfm.get.room.playerList) do
        ui.addImage(key, imageId, target, x, y, pname, ...)
      end

      return
    end

    local id = addImage(imageId, target, x, y, name, ...)

    if id then
      if name then
        imageIds[name] = imageIds[name] or {}

        -- Removes previous image
        if imageIds[name][key] then
          removeImage(imageIds[name][key])
        end

        imageIds[name][key] = id
      end
    end
  end

  ui.removeImage = function(key, name, ...)
    if not name then
      for pname in pairs(tfm.get.room.playerList) do
        ui.removeImage(key, pname, ...)
      end

      return
    end

    local id = imageIds[name] and imageIds[name][key]

    if id then
      removeImage(id, ...)

      if name then
        imageIds[name][key] = nil
      end
    end
  end

  function eventPlayerLeft(name)
    ui._imageCleanup(name)
  end
end
