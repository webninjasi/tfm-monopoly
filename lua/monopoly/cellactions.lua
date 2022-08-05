--- cellactions

local board = pshy.require("monopoly.board")
local property = pshy.require("monopoly.property")
local players = pshy.require("monopoly.players")
local logs = pshy.require("monopoly.logs")


-- Events
function eventInit()
  board.registerCellAction("win", function(cell)
    return function(name)
      if cell.id == 1 then
        logs.add('passed_go', name)
      end

      players.add(name, 'money', cell.price)
    end
  end)

  board.registerCellAction("lose", function(cell)
    return function(name)
      players.add(name, 'money', -cell.price)
    end
  end)

  board.registerCellAction("chance", function(cell)
    return function(name)
    end
  end)

  board.registerCellAction("chest", function(cell)
    return function(name)
    end
  end)

  board.registerCellAction("jail", function(cell)
    return function(name, sum, player)
      player.jail = 0
    end
  end)

  local function propertyCallback(cell)
    return function(name, diceSum)
      local owner = property.getOwner(cell.id)

      if owner then
        if owner ~= name then
          local rent = property.calculateRent(cell, diceSum)
          players.add(name, 'money', -rent)
          logs.add('pay_rent', name, rent, owner)
        end
      else
        property.showCard(cell, name, true)
      end
    end
  end

  board.registerCellAction("property", propertyCallback)
  board.registerCellAction("utility", propertyCallback)
  board.registerCellAction("station", propertyCallback)
end
