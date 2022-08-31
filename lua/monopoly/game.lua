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
  JAIL_ANIM = 7,
  GAME_OVER = 10,
}
local lobbyTurn
local whoseTurn
local gameState = states.LOBBY
local currentAuction
local currentTimer


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
  ui.addImage("bg", config.images.background, "?1", 0, 20, target)
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

  if whoseTurn then
    if prev ~= whoseTurn then
      if prev then
        property.hideManageHouses(prev.name)
        actionui.reset(prev.name)
        tokens.circleMode(prev.tokenid, false)
        prev.turn = nil
      end

      logs.add('player_turn', whoseTurn.name)
      players.update(whoseTurn.name, "turn", true)
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
    actionui.update(name, "Dice", true)

    translations.chatMessage('start_roll', name)
  end
end

local function buyProperty(name, color, card, bid)
  players.add(name, 'money', bid and -bid or -card.price)
  property.setOwner(card.id, name)
  board.setCellColor(card.id, color)
  property.hideCard(name)

  -- TODO use translations
  if bid then
    logs.add("auction", name, card.header_color, card.title, bid)
  else
    logs.add("purchase", name, card.header_color, card.title, card.price)
  end
end

local function startGame()
  for player in players.iter do
    players.add(player.name, 'money', 1500)
  end

  whoseTurn = nil
  nextTurn()
end

local function jailPlayer(player, jail_type)
  player.jail = 0

  logs.add(jail_type, player.name)

  if whoseTurn == player then
    setGameState(states.JAIL_ANIM)
  else
    board.moveToken(player.tokenid, 11, nil, nil, true)
  end
end

local function unjail(player, unjail_type)
  player.jail = nil
  logs.add(unjail_type, player.name)

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

  tfm.exec.newGame(mapXML)
end


-- TFM Events
function eventNewGame()
  ui.setBackgroundColor(config.bgcolor)

  for name in pairs(tfm.get.room.playerList) do
    eventInitPlayer(name)
  end

  setGameState(states.LOBBY)

  showBoard()
  property.showButtons()

  currentTimer = nil
  currentAuction = nil
  lobbyTurn = nil
  players.reset()
  board.reset()
  tokens.reset()
  property.reset()
  tokens.showUI("*")
  property.showHouses(nil, "*")
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
  ui.setBackgroundColor(config.bgcolor)
  showBoard(name)
  property.showButtons(name)
  players.showUI()
  tokens.show()
  board.showCellColor(nil, name)
  property.showHouses(nil, name)
  property.showMortgage(nil, name)

  if gameState == states.LOBBY then
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
  if gameState == states.GAME_OVER then
    return
  end

  board.removeToken(player.tokenid)

  if whoseTurn == player then
    player.double = nil
    nextTurn()
  end

  logs.add("player_left", name)

  if players.count() < 2 then
    if whoseTurn then
      logs.add("won", whoseTurn.name)
    end

    setGameState(states.GAME_OVER)
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

  if gameState == states.LOBBY then
    -- play order is already decided or being decided right now
    if player.order or lobbyTurn then
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
          logs.add('jail_out_money', player.name)

          setGameState(states.ROLLING)
          eventDiceRoll(dice1, dice2)

          return
        end

        if dice1 == dice2 then
          player.jail = nil

          logs.add('roll_double', player.name, dice1, dice2, dice1 + dice2)
          logs.add('jail_out_dice', player.name)

          board.moveToken(player.tokenid, player.diceSum, true)
          return
        end

        logs.add('roll_jail_fail', player.name, dice1, dice2)
        nextTurn()

        return
      end

      if dice1 == dice2 then
        if player.double and player.double > 1 then
          player.double = nil
          logs.add('roll_double', player.name, dice1, dice2, dice1 + dice2)
          jailPlayer(player, 'roll_jail')

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
  elseif gameState == states.LOBBY then
    local player = lobbyTurn
    local name = player and player.name

    lobbyTurn = nil

    if player then
      players.update(player.name, 'order', dice1 + dice2)
      logs.add('roll_lobby', player.name, dice1, dice2, dice1 + dice2)

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
      logs.add('passed_go', name)
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

    players.add(player.name, "money", -50)
    unjail(player, 'jail_out_money')
  elseif action == "JailCard" then
    if not player.jail or whoseTurn ~= player then
      return
    end
    if not player.jailcard or gameState ~= states.WAITING then
      return
    end

    player.jailcard = nil
    unjail(player, 'jail_out_card')
  elseif action == "Dice" then
    player.allowMouse = true
  elseif action == "Cards" then
  elseif action == "Build" then
    if whoseTurn ~= player then
      return
    end

    if gameState ~= states.PLAYING and gameState ~= states.PROPERTY and gameState ~= states.WAITING then
      return
    end

    if not player.tokenid then
      return
    end

    local card = board.getTokenCell(player.tokenid)

    if card then
      property.showManageHouses(card, player.name)
    end
  elseif action == "Trade" then
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

    whoseTurn.allowMouse = true
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
      setGameState(states.MOVING)
      board.moveToken(whoseTurn.tokenid, 11, nil, nil, true)
    end

    nextTurn()
  end
end

function eventEmptyProperty(name, cell)
  property.showCard(cell, name, true)
  setGameState(states.PROPERTY)
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

  if not player or player ~= whoseTurn then
    return
  end

  if gameState ~= states.PLAYING then
    return
  end

  board.setCellOverlay(nil, name, nil)

  if property.getOwner(cellId) ~= name then
    return
  end

  local price = property.housePrice(cellId)
  local mortage_price = property.mortgagePrice(cellId) 

  -- TODO add logs for these actions

  if player.overlay_mode == 'sell' then
    if not property.canSellHouse(cellId) then
      return
    end

    players.add(name, 'money', price / 2)
    property.removeHouse(cellId)
    property.showHouses(cellId)
  elseif player.overlay_mode == 'buy' then
    if not property.canBuyHouse(cellId) then
      return
    end

    if player.money < price then
      return
    end

    players.add(name, 'money', -price)
    property.addHouse(cellId)
    property.showHouses(cellId)
  elseif player.overlay_mode == 'mortgage' then
    if not property.canMortgage(cellId) then
      return
    end

    players.add(name, 'money', mortage_price)
    property.mortgage(cellId, true)
    property.showMortgage(cellId, "*")
  elseif player.overlay_mode == 'unmortgage' then
    if not property.canUnmortgage(cellId) then
      return
    end

    if player.money < mortage_price then
      return
    end

    players.add(name, 'money', -mortage_price)
    property.mortgage(cellId, nil)
    property.showMortgage(cellId, "*")
  end
end

function eventGameStateChanged(newState, oldState)
  if whoseTurn then
    actionui.reset(whoseTurn.name)
  end

  if oldState == states.AUCTION then
    currentAuction = nil
    property.hideAuction("*")

  elseif oldState == states.LOBBY then
    tokens.hideUI("*")

  elseif oldState == states.JAIL_ANIM then
    tfm.exec.removePhysicObject(202)
    tfm.exec.removePhysicObject(203)
  end

  if newState == states.LOBBY then
    if newState ~= states.GAME_OVER then
      actionui.hide("*")
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

  elseif newState == states.GAME_OVER then
    if newState ~= states.LOBBY then
      actionui.hide("*")
    end

  end
end

function eventTradeRequest(from_name, to_name)
  local from_player = players.get(from_name)
  local to_player = players.get(to_name)

  if not from_player or not to_player then
    return
  end

  -- TODO show trade request on target player
end

function eventTradeRequestAccepted(from_name, to_name)
  local from_player = players.get(from_name)
  local to_player = players.get(to_name)

  if not from_player or not to_player then
    return
  end

  -- TODO show trade interface
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
  func = function(name, id)
    local player = players.get(name)
  
    if not player or not player.color then
      return
    end

    property.setOwner(id, name)
    board.setCellColor(id, player.color)
  end,
  desc = "Own specified property",
  argc_min = 1, argc_max = 1, arg_types = {"number"}
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
    local total = increase and (count - current) or (current - count)


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

command_list["logs"] = {
  perms = "everyone",
  func = function(name)
    logs.showPage(1, name)
  end,
  desc = "browse logs",
}
