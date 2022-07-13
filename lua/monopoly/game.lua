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
        lobbyTurn == nil and '<ROSE><a href="event:votestart">Roll to start' or
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

local function updateRollButton()
  local name, player

  for i=1, players._len do
    name = players[i]
    player = players[name]
    ui.addTextArea(
      "rollbtn",
      '<p align="center"><b>\n\n' ..
      (whoseTurn == i and '<ROSE><a href="event:rolldice">Roll' or '<G>Roll'),
      name,
      monopoly.config.roll.x, monopoly.config.roll.y,
      monopoly.config.roll.w, monopoly.config.roll.h,
      0, 0, 0,
      false
    )
  end
end

local function hideRollButton(name)
  ui.removeTextArea("rollbtn", name)
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

  lobbyTurn = nil
  players = { _len=0 }
  monopoly.board.reset()
  monopoly.tokens.create()
  monopoly.votes.reset()
  monopoly.money.reset()
end

function eventNewPlayer(name)
  monopoly.tokens.show()
end

function eventPlayerLeft(name)
  if game.state == states.GAME_OVER then
    return
  end

  if players[name] then
    monopoly.board.removeToken(players[name].tokenid)
    players[name] = nil
    removeValue(players, name)
    monopoly.votes.unvote('start', name)

    if players._len == 1 then
      game.state = states.GAME_OVER
      tfm.exec.newGame(mapXML)
    end
  end
end

function eventTextAreaCallback(id, name, callback)
  if callback == 'votestart' then
    local player = players[name]

    if game.state ~= states.LOBBY or not player then
      return
    end

    -- play order is already decided or being decided right now
    if player.indexDice or lobbyTurn then
      return
    end

    -- reached the max number of players
    if players._len == 4 then
      return
    end

    local count = monopoly.votes.vote('start', name)

    if count then
      lobbyTurn = name
      monopoly.dice.roll()
      updateStartButton()
    end
  elseif callback == 'rolldice' then
    if game.state ~= states.WAITING then
      return
    end

    if whoseTurn and players[whoseTurn] == name then
      game.state = states.ROLLING
      monopoly.dice.roll()
    end
  end
end

function eventDiceRoll(dice1, dice2)
  if game.state == states.ROLLING then
    local player = whoseTurn and players[whoseTurn] and players[players[whoseTurn]]

    if player then
      game.state = states.MOVING
      monopoly.board.moveToken(player.tokenid, dice1 + dice2, true)
      updateRollButton()
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
      whoseTurn = 1
      hideStartButton()
      updateRollButton()

      -- give some money
      for i=1, players._len do
        monopoly.money.give(players[i], 1500)
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
    if passedGo then
      monopoly.money.give(name, 200)
    end

    -- TODO card action here
    --monopoly.money.take(name, 100)

    whoseTurn = 1 + (whoseTurn % players._len)
    game.state = states.WAITING
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

    players._len = 1 + players._len
    players[players._len] = name
    players[name] = {
      tokenid = tokenid,
    }
    monopoly.board.addToken(tokenid)
    monopoly.board.moveToken(tokenid, 1)
    updateStartButton()
  end
end