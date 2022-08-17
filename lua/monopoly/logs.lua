--- monopoly.logs

local config = pshy.require('monopoly.config')
local translations = pshy.require('monopoly.translations')

local getForEachLang = translations.getForEachLang
local getLanguage = translations.getLanguage
local max = math.max

local uiX, uiY, uiW = config.logsUI.x, config.logsUI.y,  config.logsUI.width
local centerX = (800 - uiW) / 2
local lineLimit = config.logsUI.lines

local allLogs = {}
local module = {}

local function getPage(lang, pageNum)
  local logs = allLogs[lang] or { _len = 0 }
  local lines = {}
  local lineNum = max(0, logs._len - pageNum * lineLimit)

  if pageNum > math.ceil(logs._len / lineLimit) then
    return
  end

  for i=1, lineLimit do
    lineNum = 1 + lineNum

    if not logs[lineNum] then
      break
    end

    lines[i] = logs[lineNum]
  end

  if #lines == 0 then
    return
  end

  return table.concat(lines, '\n')
end

module.show = function(pageNum, target)
  if not target then
    for name in pairs(tfm.get.room.playerList) do
      module.show(pageNum, name)
    end

    return
  end

  local page = getPage(getLanguage(target), pageNum)

  if page then
    ui.addTextArea(
      "logs",
      getPage(getLanguage(target), pageNum),
      target,
      uiX, uiY, uiW, nil,
      0, 0, 0, false
    )
  end
end

module.showPage = function(pageNum, target)
  local page = getPage(getLanguage(target), pageNum)

  if page then
    local str = '<R><p align="center"><a href="event:x">[X]</a></p>\n' ..
                '%s\n\n' ..
                '<p align="center"><V><a href="event:%d">&lt;</a> <G>- <BL>%d <G>- <V><a href="event:%d">&gt;</a>'

    ui.addTextArea(
      "logspage",
      string.format(
        str,
        page:sub(1, 2000 - #str),
        pageNum - 1,
        pageNum,
        pageNum + 1
      ),
      target,
      centerX, 50, uiW, 300,
      1, 0, 0.9, true
    )
  end
end

module.add = function(key, ...)
  local translated = getForEachLang(key, ...)
  local langLogs

  for lang, str in pairs(translated) do
    langLogs = allLogs[lang] or { _len = 0 }
    langLogs._len = 1 + langLogs._len
    langLogs[langLogs._len] = str:gsub('\n', ' ')

    if not allLogs[lang] then
      allLogs[lang] = langLogs
    end
  end

  print(translated[translations.getLanguage()])
  module.show(1)
end


-- Events
function eventTextAreaCallback(id, name, callback)
  if id == ui.textAreaId('logspage') then
    if callback == 'x' then
      ui.removeTextArea("logspage", name)
      return
    end

    local page = tonumber(callback) or 1
    module.showPage(page, name)
  end
end

return module
