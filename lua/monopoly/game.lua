--- monopoly.init

local config = pshy.require("monopoly.config")
local tokens = pshy.require("monopoly.tokens")
local board = pshy.require("monopoly.board")
local dice = pshy.require("monopoly.dice")
local actionui = pshy.require("monopoly.actionui")
local cellactions = pshy.require("monopoly.cellactions")
local property = pshy.require("monopoly.property")
local players = pshy.require("monopoly.players")
local translations = pshy.require('monopoly.translations')
local logs = pshy.require('monopoly.logs')
local trade = pshy.require("monopoly.trade")
local command_list = pshy.require("pshy.commands.list")


-- Game Variables
local pixels = config.images.pixels
local boardOffset = config.board.offset
local gameTime = config.gameTime
local diceArea = config.dice
local mapXML = config.mapXML:gsub("[%s\r\n]+<", "<"):gsub(">[%s\r\n]+", ">")
local states = {
  LOBBY = 0,
  WAITING = 1,
  ROLLING = 2,
  MOVING = 3,
  PROPERTY = 4,
  PLAYING = 5,
  AUCTION = 6,
  JAIL_ANIM = 7,
  TRADING = 8,
  GAME_OVER = 10,
}
local lobbyTurn
local whoseTurn
local gameState = states.LOBBY
local currentAuction
local currentTimer
local player_speed = {}
local player_ctrl = {}
local player_move_ui = {}


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
local function setGameState(newState)
  local oldState = gameState
  gameState = newState

  if newState ~= oldState then
    eventGameStateChanged(newState, oldState)
  end
end

local function showBoard(target)
  ui.addImage("bg", config.images.background, "?1", 0, 20 + boardOffset, target)
end

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

  if prev ~= whoseTurn then
    if prev then
      board.setCellOverlay(nil, prev.name, nil)
      property.hideManageHouses(prev.name)
      actionui.reset(prev.name)
      actionui.update(prev.name, "Trade", true)
      tokens.circleMode(prev.tokenid, false)
      prev.turn = nil
    end

    for playerit in players.iter do
      playerit.tradeMode = nil
    end

    if whoseTurn then
      logs.add('player_turn', whoseTurn.colorname)
      players.update(whoseTurn.name, "turn", true)
    else
      players.update()
    end
  end

  setGameState(states.WAITING)
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
      money = 0,
    })
    player = players.get(name)
  end

  if not player.color and color then
    player.coloridx = coloridx
    players.update(player.name, "color", color)
    tokens.selectColor(coloridx)
  end

  if not player.tokenid and tokenid then
    player.tokenid = tokenid
    players.update(player.name, "token", tokens.getToken(tokenid))
    board.addToken(player.tokenid)
    board.moveToken(player.tokenid, 1)
  end

  if player.color and player.tokenid then
    tokens.hideUI(name)
    actionui.show(name)
    actionui.update(name, "Dice", true)

    translations.chatMessage('start_roll', name)
  end
end

local function buyProperty(name, color, card, bid)
  players.add(name, 'money', bid and -bid or -card.price)
  property.setOwner(card.id, name)
  board.setCellColor(card.id, color)
  property.hideCard(name, card)

  if bid then
    logs.add("auction", players.get(name, "colorname"), card, bid)
  else
    logs.add("purchase", players.get(name, "colorname"), card, card.price)
  end
end

local function startGame()
  for player in players.iter do
    players.add(player.name, 'money', 1500)
    actionui.update(player.name, "Trade", true)
  end

  whoseTurn = nil
  nextTurn()
end

local function jailPlayer(player, jail_type)
  player.jail = 0

  logs.add(jail_type, player.colorname)

  if whoseTurn == player then
    setGameState(states.JAIL_ANIM)
  else
    board.moveToken(player.tokenid, 11, nil, nil, true)
  end
end

local function unjail(player, unjail_type)
  player.jail = nil
  logs.add(unjail_type, player.colorname)

  if whoseTurn == player then
    actionui.update(whoseTurn.name, "JailPay", false)
    actionui.update(whoseTurn.name, "JailCard", false)
  end
end

local function setTimer(time)
  currentTimer = os.time() + time * 1000
  tfm.exec.setGameTime(time)
end

local function checkAuctionPlayers()
  local count = 0

  if currentAuction then
    for player in players.iter do
      if not currentAuction.fold[player.name] then
        count = 1 + count
      end
    end
  end

  if count < 2 then
    setTimer(5)
    return true
  end
end

local function auctionFilter()
  if currentAuction then
    for player in players.iter do
      if player.money <= currentAuction.bid and currentAuction.bidder ~= player.name then
        currentAuction.fold[player.name] = true
      end
    end
  end
end

local function startAuction(card)
  setGameState(states.AUCTION)
  currentAuction = {
    bid = 1,
    bidder = 'BANK',
    fold = {},
    card = card,
    start = os.time(),
  }
  auctionFilter()
  property.showAuction(card, currentAuction.fold)
  property.updateAuction(whoseTurn.name, 1, 'BANK', currentAuction.fold)

  for player in players.iter do
    if not currentAuction.fold[player.name] then
      tfm.exec.movePlayer(player.name, 400, 455)
    end
  end

  checkAuctionPlayers()
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

  for pname in pairs(tfm.get.room.playerList) do
    eventInitPlayer(pname)
  end

  tfm.exec.newGame(mapXML)
end


-- TFM Events
function eventNewGame()
  ui.setBackgroundColor(config.bgcolor)

  player_speed = {}

  for name in pairs(tfm.get.room.playerList) do
    tfm.exec.setPlayerScore(name, 0)
    eventPlayerRespawn(name)
  end

  setGameState(states.LOBBY)

  showBoard()
  --property.showButtons()

  currentTimer = nil
  currentAuction = nil
  lobbyTurn = nil
  players.reset()
  board.reset()
  tokens.reset()
  property.reset()
  tokens.showUI()
  property.showHouses()
end

function eventLoop(elapsed, remaining)
  if gameState == states.AUCTION and currentAuction then
    local totalSeconds = math.max(0, math.ceil((currentTimer - currentAuction.start) / 1000))
    local remainingSeconds = math.max(0, math.ceil((currentTimer - os.time()) / 1000))

    property.updateAuctionTimer(remainingSeconds, totalSeconds)
  end

  if remaining < 1 then
    eventTimeout()
  end
end

function eventNewPlayer(name)
  for pname in pairs(tfm.get.room.playerList) do
    tfm.exec.setPlayerGravityScale(pname, 0, 0)
    ui.addImage("player_" .. pname, pixels.black, "%" .. pname, 0, 0, name, 100, 200, 0, 0, 0.5, 0.5)
  end

  ui.setBackgroundColor(config.bgcolor)
  showBoard(name)
  --property.showButtons(name)
  tokens.show(name)
  board.showCellColor(nil, name)
  property.showHouses(nil, name)
  property.showMortgage(nil, name)

  if gameState == states.LOBBY then
    tokens.showUI(name)
  elseif gameState == states.TRADING then
    trade.showUI(name)
    trade.updateUI(name)
  end

  tfm.exec.respawnPlayer(name)
  eventInitPlayer(name)
end

function eventInitPlayer(name)
  for _, key in pairs({ 0, 1, 2, 3, 17 }) do
    tfm.exec.bindKeyboard(name, key, true, true)
    tfm.exec.bindKeyboard(name, key, false, true)
  end

  system.bindMouse(name, true)
  players.showUI(name)
  logs.showUI(name)
end

function eventPlayerRespawn(name)
  tfm.exec.setPlayerGravityScale(name, 0, 0)
  ui.addImage("player_" .. name, pixels.black, "%" .. name, 0, 0, nil, 1, 1, 0, 0, 0.5, 0.5)
end


function eventPlayersUpdated(name, player)
  if gameState == states.GAME_OVER then
    return
  end

  board.removeToken(player.tokenid)
  tokens.remove(player.tokenid, player.coloridx)

  local houses = property.getProperties(player.name)

  for i=1, houses._len do
    property.setOwner(houses[i].id, nil)
    board.setCellColor(houses[i].id, nil)
    property.showHouses(houses[i].id)
    property.showMortgage(houses[i].id)
  end

  logs.add("player_left", player.colorname)

  if player.tradeMode then
    trade.cancelTrade()
  end

  if whoseTurn == player then
    player.double = nil
    nextTurn()
  end

  if players.count() < 2 then
    if whoseTurn then
      logs.add("won", whoseTurn.colorname)
    end

    setGameState(states.GAME_OVER)
    tfm.exec.newGame(mapXML)
  end
end

function eventKeyboard(name, key, down, x, y)
  if key >= 0 and key <= 3 then
    local ox = (key == 0 and -1 or (key == 2 and 1 or 0))
    local oy = (key == 1 and -1 or (key == 3 and 1 or 0))

    if not player_speed[name] then
      player_speed[name] = { 0, 0 }
    end

    local speed = 100
    local vx, vy = player_speed[name][1], player_speed[name][2]

    if down then
      if key == 0 or key == 2 then
        vx = ox * speed
      else
        vy = oy * speed
      end
    else
      if key == 0 or key == 2 then
        vx = 0
      else
        vy = 0
      end
    end

    player_speed[name][1] = vx
    player_speed[name][2] = vy

    tfm.exec.movePlayer(name, 0, 0, true, vx, vy, false)
  elseif key == 17 then
    player_ctrl[name] = down or nil
  end
end

function eventMouse(name, x, y)
  if player_ctrl[name] then
    local tpx = math.max(140, math.min(660, x))
    local tpy = math.max(230, math.min(780, y))

    tfm.exec.movePlayer(name, tpx, tpy)

    return
  end

  if player_move_ui[name] then
    local id = player_move_ui[name]

    player_move_ui[name] = nil
    eventTextAreaMove(id, name, x, y)

    return
  end

  local player = players.get(name)

  if not player then
    return
  end

  if not (x >= diceArea.x1 and x <= diceArea.x2 and y >= diceArea.y1 and y <= diceArea.y2) then
    return
  end

  if gameState == states.LOBBY then
    -- play order is already decided or being decided right now
    if player.order or lobbyTurn then
      return
    end

    if not player.color or not player.tokenid then
      return
    end 

    lobbyTurn = player
    dice.roll(x, y)
    actionui.update(name, "Dice", false)
  elseif gameState == states.WAITING then
    if whoseTurn ~= player then
      return
    end

    setGameState(states.ROLLING)
    dice.roll(x, y)
  end
end

function eventTextAreaCallback(id, name, callback)
  if callback == 'move_ui' then
    player_move_ui[name] = id
  end
end


-- Monopoly Events
function eventDiceRoll(dice1, dice2)
  if gameState == states.ROLLING then
    local player = whoseTurn

    if player then
      setGameState(states.MOVING)

      if player.luck then
        dice2 = dice1
      end

      player.diceSum = dice1 + dice2

      if player.jail then
        player.jail = player.jail + 1

        if player.jail == 3 then
          player.jail = nil
          players.add(player.name, 'money', -50)
          logs.add('jail_out_money', player.colorname)

          setGameState(states.ROLLING)
          eventDiceRoll(dice1, dice2)

          return
        end

        if dice1 == dice2 then
          player.jail = nil

          logs.add('roll_double', player.colorname, dice1, dice2, dice1 + dice2)
          logs.add('jail_out_dice', player.colorname)

          board.moveToken(player.tokenid, player.diceSum, true)
          return
        end

        logs.add('roll_jail_fail', player.colorname, dice1, dice2)
        nextTurn()

        return
      end

      if dice1 == dice2 then
        if player.double and player.double > 1 then
          player.double = nil
          logs.add('roll_double', player.colorname, dice1, dice2, dice1 + dice2)
          jailPlayer(player, 'roll_jail')

          return
        end

        player.double = 1 + (player.double or 0)

        logs.add('roll_double', player.colorname, dice1, dice2, dice1 + dice2)
        board.moveToken(player.tokenid, player.diceSum, true)

        return
      end

      player.double = nil

      logs.add('roll_once', player.colorname, dice1, dice2, dice1 + dice2)
      board.moveToken(player.tokenid, player.diceSum, true)
    end
  elseif gameState == states.LOBBY then
    local player = lobbyTurn
    local name = player and player.name

    lobbyTurn = nil

    if player then
      players.update(player.name, 'order', dice1 + dice2)
      logs.add('roll_lobby', player.colorname, dice1, dice2, dice1 + dice2)

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
      startGame()
    end
  end
end

function eventMoneyChanged(name, amount, change)
  if change > 0 then
    tfm.exec.playSound("cite18/piece2", 100, nil, nil, name)
  end
end

function eventStartMoving()
  setGameState(states.MOVING)
end

function eventTokenMove(tokenId, cellId, passedGo)
  if gameState ~= states.MOVING then
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
      logs.add('log_passed_go', player.colorname)
    end

    local action = board.cellAction(cellId)

    setGameState(states.PLAYING)

    if action then
      -- diceSum can be nil if !move is used
      action(name, player.diceSum or 2, player)

      if player.jail then
        player.double = nil
        jailPlayer(player, 'jail_in')
        return
      end
    else
      -- TODO logs.add('log_move', ...)
    end
  end
end

function eventColorSelected(name, index, color)
  if gameState ~= states.LOBBY then
    return
  end

  createPlayer(name, index, color)
end

function eventTokenClicked(name, tokenid)
  if gameState == states.LOBBY then
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
    if gameState ~= states.WAITING or player.money < 50 then
      return
    end

    players.add(player.name, 'money', -50)
    unjail(player, 'jail_out_money')
  elseif action == "JailCard" then
    if not player.jail or whoseTurn ~= player then
      return
    end

    if not player.jailcard or gameState ~= states.WAITING then
      return
    end

    players.update(player.name, "jailcard", nil)
    unjail(player, 'jail_out_card')
  elseif action == "Dice" then
    if whoseTurn ~= player then
      return
    end

    if gameState ~= states.LOBBY and gameState ~= states.WAITING then
      return
    end

    eventMouse(whoseTurn.name, 400, 400)
  elseif action == "Cards" then
  elseif action == "Build" then
    if whoseTurn ~= player then
      return
    end

    if gameState ~= states.PLAYING and gameState ~= states.PROPERTY and gameState ~= states.WAITING then
      return
    end

    if not player.tokenid and not player.tradeMode then
      return
    end

    board.setCellOverlay(nil, player.name, nil)
    property.showManageHouses(player.name)
  elseif action == "Trade" then
    if not whoseTurn or whoseTurn == player or player.tradeMode then
      return
    end

    players.update(player.name, "tradeMode", true)
    tfm.exec.playSound("cite18/baguette2", 100, nil, nil, whoseTurn.name)

  elseif action == "Stop" then
    if whoseTurn ~= player then
      return
    end

    if gameState ~= states.PLAYING and gameState ~= states.PROPERTY then
      return
    end

    if gameState == states.PROPERTY then
      local card = board.getTokenCell(whoseTurn.tokenid)

      if card and property.canBuy(card) then
        startAuction(card)
        return
      end
    end

    nextTurn()
  end
end

function eventBuyCardClick(name)
  if gameState ~= states.PROPERTY then
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

  setGameState(states.PLAYING)
end

function eventAuctionCardClick(name)
  if gameState ~= states.PROPERTY then
    return
  end

  local player = players.get(name)

  if player ~= whoseTurn or not player.tokenid then
    return
  end
  
  local card = board.getTokenCell(player.tokenid)

  if card and property.canBuy(card) then
    startAuction(card)
  end
end

function eventAuctionBid(name, bid)
  if gameState ~= states.AUCTION then
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

  if not currentTimer then
    return
  end

  local remaining = currentTimer - os.time()

  if remaining < 0 then
    return
  end

  currentAuction.bid = bid
  currentAuction.bidder = name
  auctionFilter()
  property.updateAuction(name, bid, name, currentAuction.fold)

  if remaining > 5000 and checkAuctionPlayers() then
    return
  end

  if remaining < gameTime.auctionBid * 1000 then
    setTimer(gameTime.auctionBid)
  end
end

function eventAuctionFold(name)
  if gameState ~= states.AUCTION then
    return
  end

  local player = players.get(name)

  if not player or not player.tokenid or not currentAuction then
    return
  end

  local bid = currentAuction.bid
  local bidder = currentAuction.bidder

  -- Current bidder cannot fold
  if bidder == name then
    return
  end

  local remaining = currentTimer - os.time()

  if remaining < 0 then
    return
  end

  currentAuction.fold[name] = true
  property.updateAuction(bidder, bid, bidder, currentAuction.fold)
  tfm.exec.playSound("cite18/bulle1", 100)

  if remaining > 5000 then
    checkAuctionPlayers()
  end
end

function eventTimeout()
  if not currentTimer then
    return
  end

  local now = os.time()

  if currentTimer > now then
    return
  end

  if gameState == states.WAITING then
    if not whoseTurn then
      return
    end

    eventMouse(whoseTurn.name, 400, 400)

    return
  elseif gameState == states.PROPERTY then
    if not whoseTurn then
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
  elseif gameState == states.PLAYING then
    nextTurn()

    return
  elseif gameState == states.AUCTION then
    if not currentAuction then
      return
    end

    local player = players.get(currentAuction.bidder)

    if player then
      buyProperty(player.name, player.color, currentAuction.card, currentAuction.bid)
    else
      logs.add('auction_no_bid')
    end

    setGameState(states.PLAYING)
  elseif gameState == states.JAIL_ANIM then
    if whoseTurn then
      board.moveToken(whoseTurn.tokenid, 11, nil, nil, true)
    end

    nextTurn()
  elseif gameState == states.TRADING then
    trade.cancelTrade()
  end
end

function eventEmptyProperty(name, cell)
  property.showCard(cell, name, true)
  setGameState(states.PROPERTY)
end

function eventPropertyClicked(name, cell)
  if player_ctrl[name] or player_move_ui[name] then
    return
  end

  local canBuy = false
  local player = players.get(name)

  if player and player.tokenid then
    local card = board.getTokenCell(player.tokenid)

    canBuy = card and card.id == cell.id and property.canBuy(cell)
  end

  property.showCard(cell, name, canBuy)
end

function eventBuyHouseClicked(name)
  local player = players.get(name)

  if not player or player ~= whoseTurn then
    return
  end

  if gameState ~= states.PLAYING then
    return
  end

  player.overlay_mode = 'buy'

  local properties = property.getProperties(name)
  local ok = false

  for i=1, properties._len do
    if property.canBuyHouse(properties[i].id) then
      board.setCellOverlay(properties[i].id, name, 0x00ff00)
      ok = true
    end
  end

  if not ok then
    translations.chatMessage('warn_need_fullset', name)
  end
end

function eventSellHouseClicked(name)
  local player = players.get(name)

  if not player or player ~= whoseTurn then
    return
  end

  if gameState ~= states.PLAYING then
    return
  end

  player.overlay_mode = 'sell'

  local properties = property.getProperties(name)
  local ok = false

  for i=1, properties._len do
    if property.canSellHouse(properties[i].id) then
      board.setCellOverlay(properties[i].id, name, 0xff0000)
      ok = true
    end
  end

  if not ok then
    translations.chatMessage('warn_need_house', name)
  end
end

function eventMortgageClicked(name)
  local player = players.get(name)

  if not player or player ~= whoseTurn then
    return
  end

  if gameState ~= states.PLAYING then
    return
  end

  player.overlay_mode = 'mortgage'

  local properties = property.getProperties(name)
  local ok = false

  for i=1, properties._len do
    if property.canMortgage(properties[i].id) then
      board.setCellOverlay(properties[i].id, name, 0x00ff00)
      ok = true
    end
  end

  if not ok then
    translations.chatMessage('warn_need_house2', name)
  end
end

function eventUnmortgageClicked(name)
  local player = players.get(name)

  if not player or player ~= whoseTurn then
    return
  end

  if gameState ~= states.PLAYING then
    return
  end

  player.overlay_mode = 'unmortgage'

  local properties = property.getProperties(name)
  local ok = false

  for i=1, properties._len do
    if property.canUnmortgage(properties[i].id) then
      board.setCellOverlay(properties[i].id, name, 0xff0000)
      ok = true
    end
  end

  if not ok then
    translations.chatMessage('warn_need_house3', name)
  end
end

function eventCellOverlayClicked(cellId, name)
  local player = players.get(name)

  if not player then
    return
  end

  if player.overlay_mode ~= 'trade' then
    if gameState ~= states.PLAYING then
      return
    end

    board.setCellOverlay(nil, name, nil)
  else
    if gameState ~= states.TRADING then
      return
    end
  end

  if property.getOwner(cellId) ~= name then
    return
  end

  local price = property.housePrice(cellId)
  local mortage_price = property.mortgagePrice(cellId) 

  -- TODO add logs for these actions

  if player.overlay_mode == 'sell' then
    if player ~= whoseTurn or not property.canSellHouse(cellId) then
      return
    end

    players.add(name, 'money', price / 2)
    property.removeHouse(cellId)
    property.showHouses(cellId)

    local count = property.getHouses(cellId)

    logs.add('log_sell_house', player.colorname, property.get(cellId), count)

  elseif player.overlay_mode == 'buy' then
    if player ~= whoseTurn or not property.canBuyHouse(cellId) then
      return
    end

    if player.money < price then
      return
    end

    players.add(name, 'money', -price)
    property.addHouse(cellId)
    property.showHouses(cellId)

    local count = property.getHouses(cellId)

    if count == 5 then
      logs.add('log_buy_hotel', player.colorname, property.get(cellId))
    else
      logs.add('log_buy_house', player.colorname, property.get(cellId), count)
    end

  elseif player.overlay_mode == 'mortgage' then
    if player ~= whoseTurn or not property.canMortgage(cellId) then
      return
    end

    players.add(name, 'money', mortage_price)
    property.mortgage(cellId, true)
    property.showMortgage(cellId)
    logs.add('log_mortgage', player.colorname, property.get(cellId))

  elseif player.overlay_mode == 'unmortgage' then
    if player ~= whoseTurn or not property.canUnmortgage(cellId) then
      return
    end

    if player.money < mortage_price then
      return
    end

    players.add(name, 'money', -mortage_price)
    property.mortgage(cellId, nil)
    property.showMortgage(cellId)
    logs.add('log_unmortgage', player.colorname, property.get(cellId))

  elseif player.overlay_mode == 'trade' then
    if player.tradeMode and property.canTrade(cellId) then
      trade.setLock(name, false)
      local state = trade.toggleCard(name, property.get(cellId))
      board.setCellOverlay(cellId, name, state and 0xff0000 or 0x0000ff)
      trade.updateUI()
    end

  end
end

function eventGameStateChanged(newState, oldState)
  if whoseTurn then
    actionui.reset(whoseTurn.name)
    actionui.update(whoseTurn.name, "Trade", true)
  end

  if oldState == states.AUCTION then
    currentAuction = nil
    property.hideAuction()

  elseif oldState == states.LOBBY then
    tokens.hideUI()

  elseif oldState == states.JAIL_ANIM then
    tfm.exec.removePhysicObject(202)
    tfm.exec.removePhysicObject(203)
  
  elseif oldState == states.TRADING then
    trade.cancelTrade()

  end

  if newState == states.LOBBY then
    if newState ~= states.GAME_OVER then
      actionui.hide()
    end

  elseif newState == states.WAITING then
    if oldState == states.LOBBY then
      logs.add('newgame')
    end

    if whoseTurn then
      actionui.update(whoseTurn.name, "JailPay", whoseTurn.jail and true)
      actionui.update(whoseTurn.name, "JailCard", whoseTurn.jail and whoseTurn.jailcard and true)
      actionui.update(whoseTurn.name, "Dice", true)

      tokens.circleMode(whoseTurn.tokenid, true)
      tfm.exec.playSound('transformice/son/chamane', 100, nil, nil, whoseTurn.name)
    end

    setTimer(gameTime.dice)

  elseif newState == states.ROLLING then
  elseif newState == states.MOVING then
  elseif newState == states.PROPERTY then
    if whoseTurn then
      actionui.update(whoseTurn.name, "Stop", true)
    end

    setTimer(gameTime.property)

  elseif newState == states.PLAYING then
    if whoseTurn then
      actionui.update(whoseTurn.name, "Build", true)
      actionui.update(whoseTurn.name, "Stop", true)
    end

    setTimer(gameTime.play)

  elseif newState == states.AUCTION then
    setTimer(gameTime.auction)

  elseif newState == states.JAIL_ANIM then
    setTimer(5)

    if whoseTurn then
      local card = board.getTokenCell(whoseTurn.tokenid)
      local player_pos = card and property.getPositions(card.id)
      local jail_pos = property.getPositions(11)

      if player_pos and jail_pos then
        local x = (player_pos[3] + jail_pos[3]) / 2
        local y = (player_pos[4] + jail_pos[4]) / 2
        local w = (player_pos[3] - jail_pos[3])
        local h = (jail_pos[4] - player_pos[4])
        local r = -math.atan(h / w)

        dice.hide()
        tfm.exec.addPhysicObject(202, x, y, {
          miceCollision = false,
          type = 14,
          width = 1500,
          height = 10,
          angle = math.deg(r),
          color = 0xffffff,
          friction = 0.1,
        })

        local x2 = (player_pos[1] + player_pos[3]) / 2
        local y2 = (player_pos[2] + player_pos[4]) / 2
        local powerx = -math.max(10, math.ceil((x2 - jail_pos[3]) / 10))
        local powery = -math.max(10, math.ceil((y2 - jail_pos[4]) / 10))

        tfm.exec.addPhysicObject(203, x2, y2, {
          dynamic = true,
          fixedRotation = false,
          miceCollision = false,
          angle = 0,
          type = 13,
          width = 30,
          height = 30,
          color = 0xffffff,
          friction = 0.1,
        })
        tfm.exec.movePhysicObject(203, 0, 0, true, powerx, powery, false, math.random(360), false)
        tokens.setRotation(whoseTurn.tokenid, 0)
        tokens.attachGround(whoseTurn.tokenid, 203)
      end
    end
  
  elseif newState == states.TRADING then
    setTimer(gameTime.trading)
    trade.showUI()

  elseif newState == states.GAME_OVER then
    if newState ~= states.LOBBY then
      actionui.hide()
    end

  end
end

function eventTradeRequest(to_name, from_name)
  if from_name == to_name then
    return
  end

  local from_player = players.get(from_name)
  local to_player = players.get(to_name)

  if not from_player or not to_player then
    return
  end

  if whoseTurn ~= from_player and whoseTurn ~= to_player then
    return
  end

  if gameState ~= states.PLAYING and gameState ~= states.WAITING then
    return
  end

  if whoseTurn.tradeMode or not from_player.tradeMode then
    return
  end

  whoseTurn.tradeMode = true
  tfm.exec.playSound("cite18/baguette2", 100, nil, nil, from_name)

  tfm.exec.movePlayer(from_name, 400, 400)
  tfm.exec.movePlayer(to_name, 400, 400)
  trade.startTrade(from_name, to_name, {
    prev_state = gameState,
    remaining = currentTimer and math.ceil((currentTimer - os.time()) / 1000) or 5,
  })
  setGameState(states.TRADING)
  trade.showButtons(from_name)
  trade.showButtons(to_name)

  if from_player.jailcard then
    trade.allowJailCard(from_name)
  end

  if to_player.jailcard then
    trade.allowJailCard(to_name)
  end

  trade.updateUI()

  from_player.overlay_mode = 'trade'
  board.setCellOverlay(nil, from_name, nil)

  local cards = property.getProperties(from_name)
  for i=1, cards._len do
    if property.canTrade(cards[i].id) then
      board.setCellOverlay(cards[i].id, from_name, 0x0000ff)
    end
  end

  to_player.overlay_mode = 'trade'
  board.setCellOverlay(nil, to_name, nil)

  local cards = property.getProperties(to_name)
  for i=1, cards._len do
    if property.canTrade(cards[i].id) then
      board.setCellOverlay(cards[i].id, to_name, 0x0000ff)
    end
  end
end

function eventTradeCallback(name, callback)
  local player = players.get(name)

  if not player or not player.tradeMode or gameState ~= states.TRADING then
    return
  end

  if callback == 'money' then
    trade.setLock(name, false)
    trade.setMoney(name, 0)
    trade.updateUI()
    trade.showPopup(name)

  elseif callback == 'jailcard' then
    if not player.jailcard then
      return
    end

    trade.setLock(name, false)
    trade.toggleJailCard(name)
    trade.updateUI()

  elseif callback == 'confirm' then
    if player.tradeConfirmTime and player.tradeConfirmTime > os.time() then
      return
    end

    local lock = trade.setLock(name, true)
    if lock then
      trade.updateUI()
    elseif not player.warn_trade_house or player.warn_trade_house < os.time() then
      player.warn_trade_house = os.time() + 30 * 1000
      translations.chatMessage('warn_trade_house', name)
    end

  elseif callback == 'cancel' then
    player.tradeConfirmTime = os.time() + 1000
    trade.setLock(name, false, true)
    trade.updateUI()

  elseif callback == 'close' then
    trade.cancelTrade()

  end
end

function eventTradeSetMoney(name, amount)
  local player = players.get(name)

  if not player or not player.tradeMode or gameState ~= states.TRADING then
    return
  end

  if player.money < amount then
    return
  end

  trade.setLock(name, false)
  trade.setMoney(name, amount)
  trade.updateUI()
end

function eventTradeEnded(tradeData)
  trade.hideUI()
  board.setCellOverlay()

  local player1 = players.get(tradeData.left.name)
  local player2 = players.get(tradeData.right.name)

  if player1 then
    player1.tradeMode = nil
  end

  if player2 then
    player2.tradeMode = nil
  end

  if gameState == states.TRADING then
    setGameState(tradeData.extra.prev_state)
    setTimer(tradeData.extra.remaining)
  end

  if tradeData.canceled then
    players.update()
    return
  end

  if tradeData.left.money ~= tradeData.right.money then
    if tradeData.left.money > 0 then
      players.add(player1.name, 'money', -tradeData.left.money)
      players.add(player2.name, 'money', tradeData.left.money)
      logs.add('log_trade_money', player1.colorname, player2.colorname, tradeData.left.money)
    end

    if tradeData.right.money > 0 then
      players.add(player2.name, 'money', -tradeData.right.money)
      players.add(player1.name, 'money', tradeData.right.money)
      logs.add('log_trade_money', player2.colorname, player1.colorname, tradeData.right.money)
    end
  end

  if tradeData.left.jailcard ~= tradeData.right.jailcard then
    if tradeData.left.jailcard then
      player1.jailcard = nil
      player2.jailcard = true
      logs.add('log_trade_jailcard', player1.colorname, player2.colorname)
    end

    if tradeData.right.jailcard then
      player1.jailcard = true
      player2.jailcard = nil
      logs.add('log_trade_jailcard', player2.colorname, player1.colorname)
    end
  end

  for _, card in pairs(tradeData.left.cards) do
    property.setOwner(card.id, player2.name)
    board.setCellColor(card.id, player2.color)
    logs.add('log_trade_property', player1.colorname, player2.colorname, card)
  end

  for _, card in pairs(tradeData.right.cards) do
    property.setOwner(card.id, player1.name)
    board.setCellColor(card.id, player1.color)
    logs.add('log_trade_property', player2.colorname, player1.colorname, card)
  end

  players.update()
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
  
    whoseTurn = player
    eventStartMoving()
    board.moveToken(player.tokenid, cellId, false, true, not doAnim)
  end,
  desc = "move players' token",
  argc_min = 1, argc_max = 2, arg_types = {"number", "boolean"}
}

command_list["roll"] = {
  perms = "admins",
  func = function(name, dice1, dice2)
    if gameState ~= states.WAITING then
      return
    end

    dice1 = dice1 or 6
    dice2 = dice2 or dice1
    setGameState(states.ROLLING)
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

    players.update(player.name, "jailcard", true)
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

    jailPlayer(player, 'jail_in')
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

    unjail(player, 'jail_out_card')
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

    setGameState(states.PLAYING)
    nextTurn()
  end,
  desc = "skip turn",
}

command_list["state"] = {
  perms = "admins",
  func = function(name, state)
    if state then
      setGameState(state)
    else
      tfm.exec.chatMessage("<ROSE>Game State: <V>" .. gameState, name)
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
  desc = "give money",
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
    setTimer(time or 5)
  end,
  desc = "set game time",
  argc_min = 0, argc_max = 1, arg_types = {"number"}
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

command_list["own"] = {
  perms = "admins",
  func = function(name, id, target)
    local player = players.get(target or name)
  
    if not player or not player.color then
      return
    end

    property.setOwner(id, player.name)
    board.setCellColor(id, player.color)
  end,
  desc = "Own specified property",
  argc_min = 1, argc_max = 2, arg_types = {"number", "player"}
}

command_list["disown"] = {
  perms = "admins",
  func = function(name, id)
    property.setOwner(id, nil)
    board.setCellColor(id, nil)
    property.showHouses(id)
    property.showMortgage(id)
  end,
  desc = "Disown specified property",
  argc_min = 1, argc_max = 1, arg_types = {"number"}
}

command_list["kick"] = {
  perms = "admins",
  func = function(name, target)
    players.remove(target)
  end,
  desc = "Kick a player out of the game",
  argc_min = 1, argc_max = 1, arg_types = {"player"}
}

command_list["house"] = {
  perms = "admins",
  func = function(name, cellId, count)
    if cellId < 1 or cellId > 40 then
      return
    end

    count = count or 5

    if count < 0 or count > 5 then
      return
    end

    local current = property.getHouses(cellId)

    if current == count then
      return
    end

    local increase = count > current
    local total = math.abs(current - count)


    for i=1, total do
      if increase then
        property.addHouse(cellId)
      else
        property.removeHouse(cellId)
      end
    end

    property.showHouses(cellId)
  end,
  desc = "Set number of houses on a property",
  argc_min = 1, argc_max = 2, arg_types = {"number", "number"}
}

command_list["startgame"] = {
  perms = "admins",
  func = function(name)
    startGame()
  end,
  desc = "force start the game",
}

command_list["join"] = {
  perms = "admins",
  func = function(name, target)
    if not target then
      for target in pairs(tfm.get.room.playerList) do
        for i=1, #config.images.tokens do
          eventTokenClicked(target, i)
        end

        for i=1, #config.tokenColors do
          eventTextAreaCallback(0, target, "color" .. i)
        end
      end

      return
    end

    for i=1, #config.images.tokens do
      eventTokenClicked(target, i)
    end

    for i=1, #config.tokenColors do
      eventTextAreaCallback(0, target, "color" .. i)
    end
  end,
  desc = "force join people",
  argc_min = 0, argc_max = 1, arg_types = {"player"}
}

command_list["trade"] = {
  perms = "admins",
  func = function(name, target)
    eventActionUIClick(target, "Trade")
    eventTradeRequest(name, target)
  end,
  desc = "force trade with people",
  argc_min = 1, argc_max = 1, arg_types = {"player"}
}

command_list["logs"] = {
  perms = "everyone",
  func = function(name)
    logs.showPage(1, name)
  end,
  desc = "browse logs",
}
