--- monopoly.init

local config = pshy.require("monopoly.config")
local tokens = pshy.require("monopoly.tokens")
local board = pshy.require("monopoly.board")
local votes = pshy.require("monopoly.votes")
local dice = pshy.require("monopoly.dice")
local actionui = pshy.require("monopoly.actionui")
local cellactions = pshy.require("monopoly.cellactions")
local property = pshy.require("monopoly.property")
local players = pshy.require("monopoly.players")
local translations = pshy.require('monopoly.translations')
local logs = pshy.require('monopoly.logs')
local command_list = pshy.require("pshy.commands.list")


-- Game Variables
local gameTime = config.gameTime
local scrollPos = config.scrollPos
local diceArea = config.diceArea
local mapXML = config.mapXML:gsub("[%s\r\n]+<", "<"):gsub(">[%s\r\n]+", ">")
local states = {
  LOBBY = 0,
  WAITING = 1,
  ROLLING = 2,
  MOVING = 3,
  PROPERTY = 4,
  PLAYING = 5,
  AUCTION = 6,
  GAME_OVER = 10,
}
local lobbyTurn
local whoseTurn
local game = {
  states = states,
  state = states.LOBBY,
}
local currentAuction


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
  ui.addImage("bg", config.images.background, "?1", 0, 20, target)
end

-- TODO auto move on to next turn after a timeout
local function nextTurn()
  local prev = whoseTurn

  if not whoseTurn or not whoseTurn.double then
    whoseTurn = players.next(whoseTurn)
  end

  if whoseTurn then
    while whoseTurn.skipTurn and whoseTurn.skipTurn > 0 do
      whoseTurn.skipTurn = whoseTurn.skipTurn - 1
      whoseTurn = players.next(whoseTurn)
    end
  end

  if whoseTurn then
    if prev ~= whoseTurn then
      if prev then
        actionui.update(prev.name, "Stop", false)
        tokens.circleMode(prev.tokenid, false)
        prev.turn = nil
      end

      tokens.circleMode(whoseTurn.tokenid, true)
      logs.add('player_turn', whoseTurn.name)
      players.update(whoseTurn.name, "turn", true)
    end

    if whoseTurn.jail then
      actionui.update(whoseTurn.name, "JailPay", true)

      if whoseTurn.jailcard then
        actionui.update(whoseTurn.name, "JailCard", true)
      end
    end

    actionui.update(whoseTurn.name, "Dice", true)
    tfm.exec.playSound('transformice/son/chamane', 100, nil, nil, whoseTurn.name)

    whoseTurn.timer = os.time() + gameTime.dice * 1000
  end

  tfm.exec.setGameTime(gameTime.dice)
  game.state = states.WAITING
end

local function createPlayer(name, coloridx, color, tokenid)
  local player = players.get(name)

  if player and player.color and player.tokenid then
    return
  end  

  -- reached the max number of players
  if players.count() == 6 then
    return
  end

  if not player then
    players.create({
      name = name,
      money = 1500,
    })
    player = players.get(name)
  end

  if not player.color and color then
    players.update(player.name, "color", color)
    tokens.selectColor(coloridx)
  end

  if not player.tokenid and tokenid then
    player.tokenid = tokenid
    board.addToken(player.tokenid)
    board.moveToken(player.tokenid, 1)
  end

  if player.color and player.tokenid then
    tokens.hideUI(name)
    actionui.show(name)

    translations.chatMessage('start_roll', name)
  end
end

local function buyProperty(name, color, card, bid)
  players.add(name, 'money', bid and -bid or -card.price)
  property.setOwner(card.id, name)
  board.setCellColor(card.id, color)
  property.hideCard(name)

  if bid then
    logs.add("auction", name, card.header_color, card.title)
  else
    logs.add("purchase", name, card.header_color, card.title)
  end
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
  tfm.exec.disableMortCommand(true)
  tfm.exec.disablePhysicalConsumables(true)

  tfm.exec.newGame(mapXML)
end


-- TFM Events
function eventNewGame()
  ui.setBackgroundColor(config.bgcolor)

  for name in pairs(tfm.get.room.playerList) do
    eventInitPlayer(name)
  end

  game.state = states.LOBBY

  showBoard()
  property.showButtons()

  lobbyTurn = nil
  players.reset()
  board.reset()
  tokens.reset()
  votes.reset()
  property.reset()
  tokens.showUI("*")
  actionui.hide("*")
end

function eventLoop(elapsed, remaining)
  if remaining < 1 then
    eventTimeout()
  end
end

function eventNewPlayer(name)
  ui.setBackgroundColor(config.bgcolor)
  showBoard(name)
  property.showButtons(name)
  players.showUI()
  tokens.show()
  board.showCellColor(nil, name)

  if game.state == states.LOBBY then
    tokens.showUI(name)
  end

  tfm.exec.respawnPlayer(name)
  eventInitPlayer(name)
end

function eventInitPlayer(name)
  tfm.exec.bindKeyboard(name, 1, true, true)
  tfm.exec.bindKeyboard(name, 3, true, true)
  tfm.exec.freezePlayer(name, true, false)
  system.bindMouse(name, true)
end

function eventPlayersUpdated(name, player)
  if game.state == states.GAME_OVER then
    return
  end

  board.removeToken(player.tokenid)
  votes.unvote('start', name)

  if whoseTurn == player then
    nextTurn()
  end

  logs.add("player_left", name)

  if players.count() == 1 then
    if whoseTurn then
      logs.add("won", whoseTurn.name)
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

function eventMouse(name, x, y)
  local player = players.get(name)

  if not player or not player.allowMouse then
    return
  end

  if not (x >= diceArea.x1 and x <= diceArea.x2 and y >= diceArea.y1 and y <= diceArea.y2) then
    return
  end

  player.allowMouse = false

  if game.state == states.LOBBY then
    -- play order is already decided or being decided right now
    if player.order or lobbyTurn then
      return
    end

    local count = votes.vote('start', name)

    if count then
      lobbyTurn = player
      dice.roll(x, y)
      actionui.update(name, "Dice", false)
    end
  elseif game.state == states.WAITING then
    if whoseTurn ~= player then
      return
    end

    game.state = states.ROLLING
    dice.roll(x, y)
    actionui.update(name, "Dice", false)
  end
end


-- Monopoly Events
function eventDiceRoll(dice1, dice2)
  if game.state == states.ROLLING then
    local player = whoseTurn

    if player then
      game.state = states.MOVING

      if player.luck then
        dice2 = dice1
      end

      player.diceSum = dice1 + dice2

      if player.jail then
        player.jail = player.jail + 1

        if player.jail == 3 then
          player.jail = nil
          players.add(name, 'money', -50)

          logs.add('jail_out_money', player.name)
          actionui.update(player.name, "JailCard", false)
          actionui.update(player.name, "JailPay", false)

          game.state = states.ROLLING
          eventDiceRoll(dice1, dice2)

          return
        end

        if dice1 == dice2 then
          player.jail = nil

          logs.add('roll_double', player.name, dice1, dice2, dice1 + dice2)
          logs.add('jail_out_dice', player.name)
          actionui.update(player.name, "JailCard", false)
          actionui.update(player.name, "JailPay", false)

          board.moveToken(player.tokenid, player.diceSum, true)
          return
        end

        -- TODO use a different translation
        logs.add('roll_once', player.name, dice1, dice2, dice1 + dice2)
        nextTurn()

        return
      end

      if dice1 == dice2 then
        if player.double and player.double > 1 then
          player.double = nil
          player.jail = 0

          logs.add('roll_double', player.name, dice1, dice2, dice1 + dice2)
          logs.add('roll_jail', player.name)
          board.moveToken(player.tokenid, 11, nil, nil, true)
          nextTurn()

          return
        end

        player.double = 1 + (player.double or 0)

        logs.add('roll_double', player.name, dice1, dice2, dice1 + dice2)
        board.moveToken(player.tokenid, player.diceSum, true)

        return
      end

      player.double = nil

      logs.add('roll_once', player.name, dice1, dice2, dice1 + dice2)
      board.moveToken(player.tokenid, player.diceSum, true)
    end
  elseif game.state == states.LOBBY then
    local player = lobbyTurn
    local name = player and player.name

    lobbyTurn = nil

    if player then
      players.update(player.name, 'order', dice1 + dice2)
      -- TODO use a different translation
      logs.add('roll_once', player.name, dice1, dice2, dice1 + dice2)

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
      whoseTurn = nil
      game.state = states.WAITING
      nextTurn()
      tokens.hideUI("*")
      logs.add('newgame')

      -- enable actions
      for player in players.iter do
        actionui.update(player.name, "Cards", true)
        actionui.update(player.name, "Build", true)
        actionui.update(player.name, "Trade", true)
        actionui.update(player.name, "Stop", false)

        if whoseTurn ~= player then
          actionui.update(player.name, "Dice", false)
        end
      end
    end
  end
end

function eventMoneyChanged(name, amount, change)

end

function eventStartMoving()
  game.state = states.MOVING
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

    if player.jail then
      nextTurn()
      return
    end

    if passedGo and not player.jail and cellId ~= 1 then
      players.add(name, 'money', 200)
      logs.add('passed_go', name)
    end

    local action = board.cellAction(cellId)

    game.state = states.PLAYING

    if action then
      -- diceSum can be nil if !move is used
      action(name, player.diceSum or 2, player)

      if player.jail then
        player.double = nil
        board.moveToken(player.tokenid, 11, nil, nil, true)
        logs.add('jail_in', name)
        return
      end
    end

    if game.state == states.PLAYING then
      whoseTurn.timer = os.time() + gameTime.play * 1000
      tfm.exec.setGameTime(gameTime.play)
    end

    if game.state == states.PLAYING or game.state == states.PROPERTY then
      actionui.update(whoseTurn.name, "Stop", true)
    end
  end
end

function eventColorSelected(name, index, color)
  if game.state ~= states.LOBBY then
    return
  end

  createPlayer(name, index, color)
end

function eventTokenClicked(name, tokenid)
  if game.state == states.LOBBY then
    if board.hasToken(tokenid) then
      return
    end

    createPlayer(name, nil, nil, tokenid)
  end
end

function eventActionUIClick(name, action)
  local player = players.get(name)

  if not player then
    return
  end

  if action == "JailPay" then
    if not player.jail or whoseTurn ~= player then
      return
    end
    if game.state ~= states.WAITING or player.money < 50 then
      return
    end

    players.add(player.name, "money", -50)
    player.jail = nil
    logs.add('jail_out_money', player.name)
    actionui.update(player.name, "JailCard", false)
    actionui.update(player.name, "JailPay", false)
  elseif action == "JailCard" then
    if not player.jail or whoseTurn ~= player then
      return
    end
    if not player.jailcard or game.state ~= states.WAITING then
      return
    end

    player.jailcard = nil
    player.jail = nil
    logs.add('jail_out_card', player.name)
    actionui.update(player.name, "JailCard", false)
    actionui.update(player.name, "JailPay", false)
  elseif action == "Dice" then
    player.allowMouse = true
  elseif action == "Cards" then
  elseif action == "Build" then
    if game.state ~= states.PLAYING then
      return
    end
  elseif action == "Trade" then
  elseif action == "Stop" then
    if whoseTurn ~= player then
      return
    end

    if game.state ~= states.PLAYING and game.state ~= states.PROPERTY then
      return
    end

    nextTurn()
  end
end

function eventBuyCardClick(name)
  if game.state ~= states.PROPERTY then
    return
  end

  local player = players.get(name)

  if player ~= whoseTurn then
    return
  end

  local card = board.getTokenCell(player.tokenid)

  if card and property.canBuy(card) then
    if player.money < card.price then
      return
    end

    buyProperty(name, player.color, card)
  end

  game.state = states.PLAYING
  whoseTurn.timer = os.time() + gameTime.play * 1000
  tfm.exec.setGameTime(gameTime.play)
  actionui.update(whoseTurn.name, "Stop", true)
end

function eventAuctionCardClick(name)
  if game.state ~= states.PROPERTY then
    return
  end

  local player = players.get(name)

  if player ~= whoseTurn or not player.tokenid then
    return
  end
  
  local card = board.getTokenCell(player.tokenid)

  if card and property.canBuy(card) then
    game.state = states.AUCTION
    currentAuction = {
      bid = 1,
      bidder = '',
      card = card,
      start = os.time(),
      timer = os.time() + gameTime.auction * 1000,
    }
    property.showAuction(card)
    property.updateAuction(whoseTurn.name, 1, 'BANK')
    tfm.exec.setGameTime(gameTime.auction)
  end
end

function eventAuctionBid(name, bid)
  if game.state ~= states.AUCTION then
    return
  end

  local player = players.get(name)

  if not player or not player.tokenid or not currentAuction then
    return
  end

  property.showAuctionBid(name)

  if not bid or bid > player.money or bid <= currentAuction.bid then
    return
  end

  local now = os.time()

  if currentAuction.timer < now then
    return
  end

  currentAuction.bid = bid
  currentAuction.bidder = name
  property.updateAuction(name, bid, name)

  if currentAuction.timer - now < gameTime.auctionBid * 1000 then
    currentAuction.timer = now + gameTime.auctionBid * 1000
    tfm.exec.setGameTime(gameTime.auctionBid)
  end
end

function eventTimeout()
  local now = os.time()

  if game.state == states.WAITING then
    if not whoseTurn or not whoseTurn.timer then
      return
    end

    if whoseTurn.timer > now then
      return
    end

    whoseTurn.allowMouse = true
    actionui.update(whoseTurn.name, "Dice", false)
    eventMouse(whoseTurn.name, 400, 400)

    return
  elseif game.state == states.PROPERTY then
    if not whoseTurn then
      return
    end

    if whoseTurn.timer > now then
      return
    end

    local card = board.getTokenCell(whoseTurn.tokenid)

    if card then
      if whoseTurn.money >= card.price then
        eventBuyCardClick(whoseTurn.name)
      else
        eventAuctionCardClick(whoseTurn.name)
      end
    end

    return
  elseif game.state == states.PLAYING then
    if whoseTurn and whoseTurn.timer > now then
      return
    end

    nextTurn()

    return
  end

  if game.state ~= states.AUCTION or not currentAuction then
    return
  end

  if currentAuction.timer > now then
    return
  end

  local player = players.get(currentAuction.bidder)

  if player then
    local card = currentAuction.card

    -- TODO log auction ended with no bid
    buyProperty(player.name, player.color, card, currentAuction.bid)
    property.hideAuction("*")
    currentAuction = nil
  end

  game.state = states.PLAYING
  whoseTurn.timer = os.time() + gameTime.play * 1000
  tfm.exec.setGameTime(gameTime.play)
  actionui.update(whoseTurn.name, "Stop", true)
end

function eventEmptyProperty(name, cell)
  property.showCard(cell, name, true)
  whoseTurn.timer = os.time() + gameTime.property * 1000
  tfm.exec.setGameTime(gameTime.property)
  game.state = states.PROPERTY
end

function eventPropertyClicked(name, cell)
  local canBuy = false
  local player = players.get(name)

  if player and player.tokenid then
    local card = board.getTokenCell(player.tokenid)

    canBuy = card and card.id == cell.id and property.canBuy(cell)
  end

  property.hideCard(name)
  property.showCard(cell, name, canBuy)
end


-- Commands
command_list["move"] = {
  perms = "admins",
  func = function(name, cellId, doAnim)
    local player = players.get(name)
  
    if not player or not player.tokenid then
      return
    end
  
    if not cellId or cellId < 1 or cellId > 40 then
      return
    end
  
    local prevState = game.state
    whoseTurn = player
    eventStartMoving()
    board.moveToken(player.tokenid, cellId, false, true, not doAnim)
    game.state = prevState
  end,
  desc = "move players' token",
  argc_min = 1, argc_max = 2, arg_types = {"number", "boolean"}
}

command_list["roll"] = {
  perms = "admins",
  func = function(name, dice1, dice2)
    if game.state ~= states.WAITING then
      return
    end

    dice1 = dice1 or 6
    dice2 = dice2 or dice1
    game.state = states.ROLLING
    eventDiceRoll(dice1, dice2)
  end,
  desc = "simulate dice roll",
  argc_min = 0, argc_max = 2, arg_types = {"number", "number"}
}

command_list["jailcard"] = {
  perms = "admins",
  func = function(name)
    local player = players.get(name)
  
    if not player or not player.tokenid then
      return
    end

    player.jailcard = true
  end,
  desc = "receive a free get out of jail card",
}

command_list["jail"] = {
  perms = "admins",
  func = function(name, target)
    local player = players.get(target or name)
  
    if not player or not player.tokenid or player.jail then
      return
    end

    player.jail = 0
    logs.add('jail_in', player.name)
    board.moveToken(player.tokenid, 11, nil, nil, true)
  end,
  desc = "put someone into jail",
  argc_min = 0, argc_max = 1, arg_types = {"player"}
}

command_list["unjail"] = {
  perms = "admins",
  func = function(name, target)
    local player = players.get(target or name)
  
    if not player or not player.tokenid or not player.jail then
      return
    end

    player.jail = nil
    logs.add('jail_out_card', player.name)
    actionui.update(player.name, "JailCard", false)
    actionui.update(player.name, "JailPay", false)
  end,
  desc = "get someone out of jail",
  argc_min = 0, argc_max = 1, arg_types = {"player"}
}

command_list["skip"] = {
  perms = "admins",
  func = function(name)
    if whoseTurn then
      whoseTurn.double = nil
    end

    nextTurn()
  end,
  desc = "skip turn",
}

command_list["state"] = {
  perms = "admins",
  func = function(name, state)
    if state then
      game.state = state
    else
      tfm.exec.chatMessage("<ROSE>Game State: <V>" .. game.state, name)
    end
  end,
  desc = "set game state",
  argc_min = 0, argc_max = 1, arg_types = {"number"}
}

command_list["r"] = {
  perms = "admins",
  func = function(name)
    tfm.exec.respawnPlayer(name)
  end,
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

command_list["setlang"] = {
  perms = "admins",
  func = function(name, lang)
    translations.setLanguage(nil, lang or 'en')
  end,
  desc = "set default language",
  argc_min = 0, argc_max = 1, arg_types = {"string"}
}

command_list["time"] = {
  perms = "admins",
  func = function(name, time)
    tfm.exec.setGameTime(time or 5)
  end,
  desc = "set game time",
  argc_min = 0, argc_max = 1, arg_types = {"integer"}
}

command_list["reset"] = {
  perms = "admins",
  func = function(name)
    tfm.exec.newGame(mapXML)
  end,
  desc = "restart the game",
  argc_min = 0, argc_max = 0, arg_types = {}
}

command_list["wishmeluck"] = {
  perms = "admins",
  func = function(name)
    local player = players.get(name)
  
    if not player or not player.tokenid then
      return
    end

    player.luck = not player.luck or nil
  end,
  desc = "restart the game",
  argc_min = 0, argc_max = 0, arg_types = {}
}

command_list["randcard"] = {
  perms = "admins",
  func = function(name, type, id)
    local player = players.get(name)
  
    if not player then
      return
    end

    if type == 'chance' or type == 'ch' then
      player.chanceid = id
    elseif type == 'community' or type == 'cm' then
      player.communityid = id
    end
  end,
  desc = "set rand card id",
  argc_min = 1, argc_max = 2, arg_types = {"string", "number"}
}

command_list["logs"] = {
  perms = "everyone",
  func = function(name)
    logs.showPage(1, name)
  end,
  desc = "browse logs",
}
