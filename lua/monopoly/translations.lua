--- monopoly.translations

local chatMessage = tfm.exec.chatMessage

local translations = pshy.require('monopoly.generated_translations')

local defaultLang = 'en'
local defaultTrans = translations[defaultLang]
local playerLang = {}
local playerTrans = {}

local module = {}
local cache = {}

local _translate

_translate = function(key, target, arg1, ...)
  local translation = target and playerTrans[target] and playerTrans[target][key] or defaultTrans[key]

  if arg1 then
    return translation(_translate, target, arg1, ...)
  end

  return translation
end

module.getLanguage = function(target)
  return playerLang[target] or defaultLang
end

module.setLanguage = function(target, language)
  if target then
    playerTrans[target] = language and translations[language] or nil
    playerLang[target] = playerTrans[target] and language or nil
  else
    defaultTrans = language and translations[language] or defaultTrans
    defaultLang = defaultTrans and language or defaultLang
  end
end

module.get = function(key, target, arg1, ...)
  if cache[key] then
    local lang = target and playerLang[target] or defaultLang
    local translation = cache[key][lang]

    if not translation then
      translation = _translate(key, target, arg1, ...)
      cache[key][lang] = translation
    end

    return translation
  end

  return _translate(key, target, arg1, ...)
end

module.cacheEnable = function(key)
  cache[key] = {}
end

module.cacheDisable = function(key)
  cache[key] = nil
end

module.getForEachLang = function(key, ...)
  local ret = {}
  local cacheEnabled = cache[key]
    
  if not cacheEnabled then
    module.cacheEnable(key)
  end

  ret[defaultLang] = module.get(key, nil, ...)

  for name in pairs(tfm.get.room.playerList) do
    if playerLang[name] then
      ret[playerLang[name]] = module.get(key, name, ...)
    end
  end

  if not cacheEnabled then
    module.cacheDisable(key)
  end

  return ret
end

module.chatMessage = function(key, target, ...)
  if not target then
    local cacheEnabled = cache[key]
    
    if not cacheEnabled then
      module.cacheEnable(key)
    end

    for name in pairs(tfm.get.room.playerList) do
      module.chatMessage(key, name, ...)
    end

    if not cacheEnabled then
      module.cacheDisable(key)
    end

    return
  end

  chatMessage(module.get(key, target, ...), target)
end


-- Events
function eventInit()
  chatMessage = tfm.exec.chatMessage
end

return module
