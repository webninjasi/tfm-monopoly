--- monopoly.logs

local config = pshy.require('monopoly.config')
local translations = pshy.require('monopoly.translations')

local getForEachLang = translations.getForEachLang
local getLanguage = translations.getLanguage
local max = math.max

local uiX, uiY, uiW = config.logsUI.x, config.logsUI.y,  config.logsUI.width
local lineLimit = config.logsUI.lines

local allLogs = {}
local module = {}

local function getPage(lang, pageNum)
  local logs = allLogs[lang] or { _len = 0 }
  local lines = {}
  local lineNum = max(0, logs._len - pageNum * lineLimit)

  for i=1, lineLimit do
    lineNum = 1 + lineNum

    if not logs[lineNum] then
      break
    end

    lines[i] = logs[lineNum]
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

  ui.addTextArea(
    "logs",
    getPage(getLanguage(target), pageNum),
    target,
    uiX, uiY, uiW, nil,
    0, 0, 0, false
  )
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

return module
