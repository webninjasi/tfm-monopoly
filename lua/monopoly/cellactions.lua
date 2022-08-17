--- cellactions

local board = pshy.require("monopoly.board")
local property = pshy.require("monopoly.property")
local players = pshy.require("monopoly.players")
local logs = pshy.require("monopoly.logs")
local randcard = pshy.require("monopoly.randcard")


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

      if cell.price == 100 then
        logs.add('luxury_tax', name)
      elseif cell.price == 200 then
        logs.add('income_tax', name)
      end
    end
  end)

  board.registerCellAction("chance", function(cell)
    return function(name, sum, player)
      randcard.chance(name, player)
      logs.add('chance_space', name)
    end
  end)

  board.registerCellAction("chest", function(cell)
    return function(name, sum, player)
      randcard.community(name, player)
      logs.add('community_chest', name)
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
          players.add(owner, 'money', rent)
          logs.add('pay_rent', name, rent, owner)
        end
      elseif eventEmptyProperty then
        eventEmptyProperty(name, cell)
      end
    end
  end

  board.registerCellAction("property", propertyCallback)
  board.registerCellAction("utility", propertyCallback)
  board.registerCellAction("station", propertyCallback)
end
