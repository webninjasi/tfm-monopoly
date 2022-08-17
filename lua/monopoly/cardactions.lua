--- monopoly.cardactions

local board = pshy.require('monopoly.board')
local players = pshy.require('monopoly.players')

local community = {
  function(name, player)
    board.moveToken(player.tokenid, 1, false, true)
  end,

  function(name, player)
    board.moveToken(player.tokenid, 2, false, true, true)
  end,

  function(name, player)
    players.add(name, 'money', 200)
  end,

  function(name, player)
    players.add(name, 'money', 50)
  end,

  function(name, player)
    players.add(name, 'money', 20)
  end,

  function(name, player)
    players.add(name, 'money', 100)
  end,

  function(name, player)
    players.add(name, 'money', 10)
  end,

  function(name, player)
    local total = 0

    for player in players.iter do
      if player.name ~= name then
        total = total + 10
        players.add(player.name, 'money', -10)
      end
    end

    players.add(name, 'money', total)
  end,

  function(name, player)
    players.add(name, 'money', -50)
  end,

  function(name, player)
    players.add(name, 'money', -50)
  end,

  function(name, player)
    players.add(name, 'money', -150)
  end,

  function(name, player)
    player.jail = 0
  end,

  function(name, player)
    player.jailcard = true
  end,
}

local chance = {
  function(name, player)
    board.moveToken(player.tokenid, 1, false, true)
  end,

  function(name, player)
    board.moveToken(player.tokenid, 40, false)
  end,

  function(name, player)
    board.moveToken(player.tokenid, -3, true, true, true)
  end,

  function(name, player)
    board.moveToken(player.tokenid, 12, false)
  end,

  function(name, player)
    board.moveToken(player.tokenid, 16, false)
  end,

  function(name, player)
    board.moveToken(player.tokenid, 25, false)
  end,

  function(name, player)
    players.add(name, 'money', -150)
  end,

  function(name, player)
    players.add(name, 'money', -15)
  end,

  function(name, player)
    local houses = 0
    local hotels = 0

    -- TODO fetch house/hotel count

    players.add(name, 'money', - 25 * houses - 100 * hotels)
  end,

  function(name, player)
    local houses = 0
    local hotels = 0

    -- TODO fetch house/hotel count

    players.add(name, 'money', - 40 * houses - 115 * hotels)
  end,

  function(name, player)
    players.add(name, 'money', 50)
  end,

  function(name, player)
    players.add(name, 'money', 100)
  end,

  function(name, player)
    players.add(name, 'money', 150)
  end,

  function(name, player)
    player.jail = 0
  end,

  function(name, player)
    player.jailcard = true
    -- TODO allow jail card to be used
  end,
}

return {
  chance = chance,
  community = community,
}
