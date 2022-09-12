--- monopoly.cardui

local config = pshy.require('monopoly.config')
local translations = pshy.require('monopoly.translations')
local cardactions = pshy.require('monopoly.cardactions')
local logs = pshy.require("monopoly.logs")

local chanceBg = config.images.cards.chance
local communityBg = config.images.cards.community
local uiX, uiY = config.randCard.x, config.randCard.y
local uiW, uiH = config.randCard.width, config.randCard.height
local communityCount = config.randCard.communityCount
local chanceCount = config.randCard.chanceCount
local lastCommunity
local lastChance

local jailcard = {
  chance = true,
  community = true,
}

local function showCard(player, type, id)
  local img = type == 'chance' and chanceBg or communityBg
  local trkey = type .. '_' .. id

  ui.addImage("randcardbg", img, "~150", uiX, uiY, player.name)
  ui.addTextArea(
    "randcardinfo",
    '<p align="center"><b><font size="12" color="#000000"><a href="event:closeRandCard">' ..
    translations.get(trkey, player.name),
    player.name,
    uiX + 10, uiY + 10,
    uiW - 20, uiH - 20,
    0, 0, 0,
    true
  )
end

local function logCard(player, type, id)
  local trkey = type .. '_' .. id

  logs.add('log_card', player.colorname, type)
  logs.add('log_card_detail', trkey)
end

local function randomWithException(count, exception)
  local rand = math.random(count)

  if exception == rand then
    if rand == count then
      rand = rand - 1
    else
      rand = rand + 1
    end
  end

  return rand
end

local module = {}

module.reset = function()
  jailcard = {
    chance = true,
    community = true,
  }
end

module.putJailCard = function(type)
  jailcard[type] = true
end

module.community = function(name, player)
  local count = jailcard.community and communityCount or (communityCount - 1)
  local id = player.communityid or randomWithException(count, lastCommunity)
  if id > 0 and id <= communityCount then
    lastCommunity = id
    if not player.afk then
      showCard(player, 'community', id)
    end
    logCard(player, 'community', id)
    cardactions.community[id](name, player)
  end
end

module.chance = function(name, player)
  local count = jailcard.chance and chanceCount or (chanceCount - 1)
  local id = player.chanceid or randomWithException(count, lastChance)
  if id > 0 and id <= chanceCount then
    lastChance = id
    if not player.afk then
      showCard(player, 'chance', id)
    end
    logCard(player, 'chance', id)
    cardactions.chance[id](name, player)
  end
end

module.hide = function(name)
  ui.removeImage("randcardbg", name)
  ui.removeTextArea("randcardinfo", name)
end

function eventTextAreaCallback(id, name, callback)
  if callback == 'closeRandCard' then
    ui.removeImage("randcardbg", name)
    ui.removeTextArea("randcardinfo", name)
  end
end

return module
