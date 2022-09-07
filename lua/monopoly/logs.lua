--- monopoly.logs

local config = pshy.require('monopoly.config')
local translations = pshy.require('monopoly.translations')

local getForEachLang = translations.getForEachLang
local getLanguage = translations.getLanguage
local max = math.max

local uiX, uiY, uiW = config.logsUI.x, config.logsUI.y,  config.logsUI.width
local centerX = (800 - uiW) / 2
local lineLimit = config.logsUI.lines
local move_button = '<p align="left"><font size="20" color="#%.6x"><a href="event:move_ui">⛶</a></font></p>'

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

local function updateUI(target)
  if not target then
    for name in pairs(tfm.get.room.playerList) do
      updateUI(name)
    end

    return
  end

  local page = getPage(getLanguage(target), 1)

  if page then
    ui.updateTextArea(
      "logs",
      move_button:format(0xDEDEDE) .. page,
      target
    )
  end
end

module.showUI = function(target, x, y)
  if not target then
    for name in pairs(tfm.get.room.playerList) do
      module.showUI(name, x, y)
    end

    return
  end

  x = x or uiX
  y = y or uiY

  ui.addTextArea(
    "logs",
    '',
    target,
    x, y, uiW, nil,
    0, 0, 0, false
  )
  updateUI(target)
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
      0x495451, 1, 0.9, true
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
  updateUI()
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

function eventTextAreaMove(id, name, x, y)
  if id == ui.textAreaId("logs") then
    module.showUI(name, x, y)
  end
end

return module
