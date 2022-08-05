--- monopoly.init

monopoly = monopoly or {}

if monopoly.game then
  return
end


-- Dependencies
pshy.require("monopoly.config")
pshy.require("monopoly.tokens")
pshy.require("monopoly.board")
pshy.require("monopoly.votes")
pshy.require("monopoly.dice")
pshy.require("monopoly.actionui")
pshy.require("monopoly.cellactions")
pshy.require("monopoly.property")

local players = pshy.require("monopoly.players")
local command_list = pshy.require("pshy.commands.list")
local translations = pshy.require('monopoly.translations')


-- Game Variables
local scrollPos = monopoly.config.scrollPos
local mapXML = monopoly.config.mapXML:gsub("[%s\r\n]+<", "<"):gsub(">[%s\r\n]+", ">")
local states = {
  LOBBY = 0,
  WAITING = 1,
  ROLLING = 2,
  MOVING = 3,
  PLAYING = 4,
  GAME_OVER = 10,
}
local lobbyTurn
local whoseTurn
local game = {
  states = states,
  state = states.LOBBY,
}

monopoly.game = game


-- Helper Functions
local function removeValue(tbl, value)
  local j = 0

  for i=1, tbl._len do
    if tbl[i] ~= value then
      j = 1 + j
    end

    if j ~= i then
      tbl[j] = tbl[i]
      tbl[i] = nil
    end
  end

  tbl._len = j
end


-- Game Functions
local function showBoard(target)
  ui.addImage("bg", monopoly.config.images.background, "?1", 0, 20, target)
end

-- TODO auto move on to next turn after a timeout
local function nextTurn()
  if whoseTurn then
    monopoly.tokens.circleMode(whoseTurn.tokenid, false)
  end

  whoseTurn = players.next(whoseTurn)

  if whoseTurn then
    while whoseTurn.skipTurn and whoseTurn.skipTurn > 0 do
      whoseTurn.skipTurn = whoseTurn.skipTurn - 1
      whoseTurn = players.next(whoseTurn)
    end
  end

  if whoseTurn then
    monopoly.tokens.circleMode(whoseTurn.tokenid, true)
    monopoly.actionui.update(whoseTurn.name, "Dice", true)
  end

  game.state = states.WAITING
end


-- Pshy Events
function eventInit()
  system.disableChatCommandDisplay(nil, true)
  tfm.exec.disableAfkDeath(true)
  tfm.exec.disableAutoNewGame(true)
  tfm.exec.disableAutoScore(true)
  tfm.exec.disableAutoShaman(true)
  tfm.exec.disableAutoTimeLeft(true)
  tfm.exec.disableDebugCommand(true)
  tfm.exec.disableMinimalistMode(true)
  tfm.exec.disablePhysicalConsumables(true)

  tfm.exec.newGame(mapXML)
end


-- TFM Events
function eventNewGame()
  for name in pairs(tfm.get.room.playerList) do
    eventInitPlayer(name)
  end

  showBoard()

  lobbyTurn = nil
  players.reset()
  monopoly.board.reset()
  monopoly.tokens.create()
  monopoly.votes.reset()
  monopoly.property.reset()
end

function eventNewPlayer(name)
  showBoard(name)
  players.showUI()
  monopoly.tokens.show()
  tfm.exec.respawnPlayer(name)
  eventInitPlayer(name)
end

function eventInitPlayer(name)
  tfm.exec.bindKeyboard(name, 1, true, true)
  tfm.exec.bindKeyboard(name, 3, true, true)
  tfm.exec.freezePlayer(name, true, false)
end

function eventPlayersUpdated(name, player)
  if game.state == states.GAME_OVER then
    return
  end

  monopoly.board.removeToken(player.tokenid)
  monopoly.votes.unvote('start', name)

  if whoseTurn == player then
    nextTurn()
  end

  if players.count() == 1 then
    if whoseTurn then
      tfm.exec.chatMessage(("<ROSE>%s won the game!"):format(whoseTurn.name))
    end

    game.state = states.GAME_OVER
    tfm.exec.newGame(mapXML)
  end
end

function eventKeyboard(name, key, down, x, y)
  if key == 1 or key == 3 then -- UP/DOWN key
    local off = key == 1 and -1 or 1

    for i=1, 3 do
      if scrollPos[i + off] and math.abs(y - scrollPos[i]) < 10 then
        tfm.exec.movePlayer(name, scrollPos.x, scrollPos[i + off])
        break
      end
    end
  end
end


-- Monopoly Events
function eventDiceRoll(dice1, dice2)
  if game.state == states.ROLLING then
    local player = whoseTurn

    if player then
      game.state = states.MOVING
      player.diceSum = dice1 + dice2
      tfm.exec.chatMessage(('<ROSE>%s rolled %d + %d = %d'):format(player.name, dice1, dice2, dice1 + dice2))
      monopoly.board.moveToken(player.tokenid, player.diceSum, true)
    end
  elseif game.state == states.LOBBY then
    local player = lobbyTurn
    local name = player and player.name

    lobbyTurn = nil

    if player then
      players.update(player.name, 'order', dice1 + dice2)
      tfm.exec.chatMessage(('<ROSE>%s rolled %d + %d = %d'):format(name, dice1, dice2, dice1 + dice2))

      -- only start with 2+ players
      if players.count() < 2 then
        return
      end

      -- stop if there's still people who didn't roll dice
      for player in players.iter do
        if not player.order then
          return
        end
      end

      -- everyone is ready, start the game
      tfm.exec.chatMessage('<ROSE>The game is starting...')

      whoseTurn = nil
      game.state = states.WAITING
      nextTurn()
      monopoly.tokens.hide()

      -- enable actions
      for player in players.iter do
        monopoly.actionui.update(player.name, nil, true)

        if whoseTurn ~= player then
          monopoly.actionui.update(player.name, "Dice", false)
        end
      end
    end
  end
end

function eventMoneyChanged(name, amount, change)

end

function eventTokenMove(tokenId, cellId, passedGo)
  if game.state ~= states.MOVING then
    return
  end

  local player = whoseTurn
  local name = player and player.name

  if player then
    -- Possible using !move
    if player.tokenid ~= tokenId then
      return
    end

    if passedGo then
      players.add(name, 'money', 200)
    end

    local action = monopoly.board.cellAction(cellId)

    if action then
      -- diceSum can be nil if !move is used
      action(name, player.diceSum or 2)
    end

    game.state = states.PLAYING
  end
end

function eventTokenClicked(name, tokenid)
  if game.state == states.LOBBY then
    if monopoly.board.hasToken(tokenid) then
      return
    end

    if players.get(name) then
      return
    end
  
    -- reached the max number of players
    if players.count() == 6 then
      return
    end

    players.create({
      name = name,
      tokenid = tokenid,
      color = monopoly.tokens.randColor(tokenid),
      money = 1500,
    })

    monopoly.board.addToken(tokenid)
    monopoly.board.moveToken(tokenid, 1)
    monopoly.tokens.keep(tokenid)
    monopoly.actionui.show(name)

    tfm.exec.chatMessage("<ROSE>Roll the dice to determine start order", name)
  end
end

function eventActionUIClick(name, action)
  local player = players.get(name)

  if not player then
    return
  end

  if action == "Dice" then
    if game.state == states.LOBBY then
      -- play order is already decided or being decided right now
      if player.order or lobbyTurn then
        return
      end
  
      local count = monopoly.votes.vote('start', name)
  
      if count then
        lobbyTurn = player
        monopoly.dice.roll()
        monopoly.actionui.update(name, "Dice", false)
      end
    elseif game.state == states.WAITING then
      if whoseTurn ~= player then
        return
      end

      game.state = states.ROLLING
      monopoly.dice.roll()
      monopoly.actionui.update(name, "Dice", false)
    end
  elseif action == "Cards" then
  elseif action == "Build" then
    if game.state ~= states.PLAYING then
      return
    end
  elseif action == "Trade" then
  elseif action == "Stop" then
    if game.state ~= states.PLAYING then
      return
    end

    if whoseTurn ~= player then
      return
    end

    nextTurn()
  end
end

function eventBuyCardClick(name)
  if game.state ~= states.PLAYING then
    return
  end

  local player = players.get(name)

  if player ~= whoseTurn then
    return
  end

  local card = monopoly.board.getTokenCell(player.tokenid)

  if card and monopoly.property.canBuy(card) then
    if player.money < card.price then
      return
    end

    players.add(name, 'money', -card.price)
    monopoly.property.setOwner(card.id, name)
    monopoly.property.hideCard(name)
    monopoly.property.showCard(card, name, false)
    tfm.exec.chatMessage(("<V>%s <J>bought %s"):format(name, card.title))
  end
end

function eventAuctionCardClick(name)
  if game.state ~= states.PLAYING then
    return
  end

  local player = players.get(name)

  if player ~= whoseTurn then
    return
  end

  if card and monopoly.property.canBuy(card) then
    monopoly.property.auctionStart(card)
  end
end


-- Commands
local function ChatCommandMove(name, cellId)
  local player = players.get(name)

  if not player.tokenid then
    return
  end

  if not cellId or cellId < 1 or cellId > 40 then
    return
  end

  local prevState = game.state
  game.state = states.MOVING
  whoseTurn = player
  monopoly.board.moveToken(player.tokenid, cellId)
  game.state = prevState
end
command_list["move"] = {
  perms = "admins",
  func = ChatCommandMove,
  desc = "move players' token",
  argc_min = 1, argc_max = 1, arg_types = {"number"}
}

local function ChatCommandSetState(name, state)
  game.state = state or 0
end
command_list["setstate"] = {
  perms = "admins",
  func = ChatCommandSetState,
  desc = "set game state",
  argc_min = 1, argc_max = 1, arg_types = {"number"}
}

local function ChatCommandRespawn(name)
  tfm.exec.respawnPlayer(name)
end
command_list["r"] = {
  func = ChatCommandRespawn,
  desc = "respawns the player",
  argc_min = 0, argc_max = 0
}

command_list["money"] = {
  perms = "admins",
  func = function(name, money, target)
    players.add(target or name, 'money', money)
  end,
  desc = "set game state",
  argc_min = 1, argc_max = 2, arg_types = {"number", "player"}
}

command_list["tr"] = {
  perms = "admins",
  func = function(name, key, target, ...)
    target = target ~= '*' and target or nil
    translations.chatMessage(key, target, ...)
  end,
  desc = "send a translated message",
  argc_min = 2, argc_max = 10, arg_types = {"string", "string"}
}

command_list["lang"] = {
  perms = "everyone",
  func = function(name, lang)
    translations.setLanguage(name, lang)
  end,
  desc = "set your game language",
  argc_min = 0, argc_max = 1, arg_types = {"string"}
}
