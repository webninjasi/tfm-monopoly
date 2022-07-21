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
pshy.require("monopoly.money")
pshy.require("monopoly.actionui")
pshy.require("monopoly.cellactions")


-- Game Variables
local mapXML = monopoly.config.mapXML:gsub("[%s\r\n]+<", "<"):gsub(">[%s\r\n]+", ">")
local states = {
  LOBBY = 0,
  WAITING = 1,
  ROLLING = 2,
  MOVING = 3,
  GAME_OVER = 4,
}
local lobbyTurn
local whoseTurn = 1
local players = { _len=0 }
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
local function updateStartButton()
  local name, player

  for i=1, players._len do
    name = players[i]
    player = players[name]

    ui.addTextArea(
      "startbtn",
      '<p align="center"><b>\n\n' .. 
      (player and player.indexDice and '<G>Waiting for others...' or (
        lobbyTurn == nil and '<ROSE>Roll to start' or
        (lobbyTurn == name and '<V>You\'re rolling...'
                            or '<V>Rolling...')
      )),
      name,
      monopoly.config.roll.x, monopoly.config.roll.y,
      monopoly.config.roll.w, monopoly.config.roll.h,
      0, 0, 0,
      false
    )
  end
end

local function hideStartButton(name)
  ui.removeTextArea("startbtn", name)
end

local function showBoard(target)
  ui.addImage("bg", monopoly.config.images.background, "?1", 0, 20, target)
end

local function getPlayerByIdx(idx)
  local name = players[idx]
  local player = name and players[name]

  return player
end

local function setWhoseTurn(idx)
  local prev = whoseTurn

  whoseTurn = 1 + ((idx - 1) % players._len)

  -- Add circle around the player's token
  local player = getPlayerByIdx(whoseTurn)

  if player and player.tokenid then
    monopoly.tokens.circleMode(player.tokenid, true)
  end

  -- Remove circle from previous player
  if prev ~= whoseTurn then
    player = getPlayerByIdx(prev)

    if player and player.tokenid then
      monopoly.tokens.circleMode(player.tokenid, false)
    end
  end
end


-- Events
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

function eventNewGame()
  for name in pairs(tfm.get.room.playerList) do
    tfm.exec.killPlayer(name)
  end

  showBoard()

  lobbyTurn = nil
  players = { _len=0 }
  monopoly.board.reset()
  monopoly.tokens.create()
  monopoly.votes.reset()
  monopoly.money.reset()
end

function eventNewPlayer(name)
  showBoard(name)
  monopoly.tokens.show()
end

function eventPlayerLeft(name)
  if game.state == states.GAME_OVER then
    return
  end

  local player = players[name]

  if player then
    monopoly.board.removeToken(player.tokenid)
    players[name] = nil
    removeValue(players, name)
    monopoly.votes.unvote('start', name)

    if whoseTurn == player.index then
      setWhoseTurn(whoseTurn)
    end

    for i=1, players._len do
      players[players[i]].index = i
    end

    if players._len == 1 then
      game.state = states.GAME_OVER
      tfm.exec.newGame(mapXML)
    end
  end
end

function eventDiceRoll(dice1, dice2)
  if game.state == states.ROLLING then
    local player = whoseTurn and players[whoseTurn] and players[players[whoseTurn]]

    if player then
      game.state = states.MOVING
      monopoly.board.moveToken(player.tokenid, dice1 + dice2, true)
    end
  elseif game.state == states.LOBBY then
    local name = lobbyTurn
    local player = players[lobbyTurn]

    lobbyTurn = nil

    if player then
      player.indexDice = dice1 + dice2
      tfm.exec.chatMessage(('<ROSE>You rolled %d + %d = %d'):format(dice1, dice2, dice1 + dice2), name)
      updateStartButton()

      -- only start with 2+ players
      if players._len < 2 then
        return
      end

      local sortedByDice = { _len = 0 }
      local playerIt

      -- stop if there's still people who didn't roll dice
      for i=1, players._len do
        playerIt = players[players[i]]

        if playerIt and not playerIt.indexDice then
          return
        end

        sortedByDice._len = 1 + sortedByDice._len
        sortedByDice[sortedByDice._len] = { players[i], playerIt.indexDice }
      end

      -- reorder player list
      table.sort(sortedByDice, function(a, b) return a[2] > b[2] end)

      for i=1, players._len do
        players[i] = sortedByDice[i][1]
      end

      -- everyone is ready, start the game
      tfm.exec.chatMessage('<ROSE>The game is starting...')

      game.state = states.WAITING
      setWhoseTurn(1)
      hideStartButton()
      monopoly.tokens.hide()

      -- give some money and enable actions
      for i=1, players._len do
        monopoly.money.give(players[i], 1500)
        monopoly.actionui.update(players[i], nil, true)

        if whoseTurn ~= i then
          monopoly.actionui.update(players[i], "Dice", false)
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

  local name = whoseTurn and players[whoseTurn]
  local player = name and players[name]

  if player then
    -- Possible using !move
    if player.tokenid ~= tokenId then
      return
    end

    if passedGo then
      monopoly.money.give(name, 200)
    end

    local action = monopoly.board.cellAction(cellId)

    if action then
      action(name)
    end

    -- TODO wait for a bit before moving on to next turn
    setWhoseTurn(whoseTurn + 1)
    game.state = states.WAITING

    if players[whoseTurn] then
      monopoly.actionui.update(players[whoseTurn], "Dice", true)
    end
  end
end

function eventTokenClicked(name, tokenid)
  if game.state == states.LOBBY then
    if monopoly.board.hasToken(tokenid) then
      return
    end

    if players[name] then
      return
    end
  
    -- reached the max number of players
    if players._len == 6 then
      return
    end

    players._len = 1 + players._len
    players[players._len] = name
    players[name] = {
      tokenid = tokenid,
      index = players._len,
    }

    monopoly.board.addToken(tokenid)
    monopoly.board.moveToken(tokenid, 1)
    monopoly.tokens.keep(tokenid)
    updateStartButton()
    monopoly.actionui.show(name)
  end
end

function eventActionUIClick(name, action)
  if action == "Dice" then
    if game.state == states.LOBBY then
      local player = players[name]

      if not player then
        return
      end
  
      -- play order is already decided or being decided right now
      if player.indexDice or lobbyTurn then
        return
      end
  
      local count = monopoly.votes.vote('start', name)
  
      if count then
        lobbyTurn = name
        monopoly.dice.roll()
        monopoly.actionui.update(name, "Dice", false)
        updateStartButton()
      end
    elseif game.state == states.WAITING then
      if whoseTurn and players[whoseTurn] == name then
        game.state = states.ROLLING
        monopoly.dice.roll()
        monopoly.actionui.update(name, "Dice", false)
      end
    end
  end
end

-- TODO use pshy.commands
function eventChatCommand(name, cmd)
  local args = {}

  for arg in cmd:gmatch('%S+') do
    args[1 + #args] = arg
  end

  local player = players[name]

  if args[1] == 'move' then -- TODO restrict/remove after testing
    if not player or not player.tokenid then
      return
    end

    local cellId = tonumber(args[2])

    if not cellId or cellId < 1 or cellId > 40 then
      return
    end

    local prevState = game.state
    game.state = states.MOVING
    whoseTurn = player.index
    monopoly.board.moveToken(player.tokenid, cellId)
    game.state = prevState
  end
end
