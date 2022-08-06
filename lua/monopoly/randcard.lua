--- monopoly.cardui

local config = pshy.require('monopoly.config')
local translations = pshy.require('monopoly.translations')
local cardactions = pshy.require('monopoly.cardactions')

local chanceBg = config.images.cards.chance
local communityBg = config.images.cards.community
local uiX, uiY = config.randCard.x, config.randCard.y
local uiW, uiH = config.randCard.width, config.randCard.height
local communityCount = config.randCard.communityCount
local chanceCount = config.randCard.chanceCount

local function showCard(name, type, id)
  local img = type == 'chance' and chanceBg or communityBg
  local trkey = type .. '_' .. id

  ui.addImage("randcardbg", img, "~150", uiX, uiY, name)
  ui.addTextArea(
    "randcardinfo",
    '<p align="center"><b><font size="12" color="#000000"><a href="event:closeRandCard">' ..
    translations.get(trkey, name),
    name,
    uiX + 10, uiY + 10,
    uiW - 20, uiH - 20,
    0, 0, 0,
    true
  )
end

local module = {}

module.community = function(name, player)
  local id = math.random(communityCount)
  showCard(name, 'community', id)
  cardactions.community[id](name, player)
end

module.chance = function(name, player)
  local id = math.random(chanceCount)
  showCard(name, 'chance', id)
  cardactions.chance[id](name, player)
end

function eventTextAreaCallback(id, name, callback)
  if callback == 'closeRandCard' then
    ui.removeImage("randcardbg", name)
    ui.removeTextArea("randcardinfo", name)
  end
end

return module
