--- monopoly.cellactions

monopoly = monopoly or {}

if monopoly.__cellactions then
  return
end

monopoly.__cellactions = true


-- Dependencies
pshy.require("monopoly.board")
pshy.require("monopoly.property")

local players = pshy.require("monopoly.players")


-- Events
function eventInit()
  monopoly.board.registerCellAction("win", function(cell)
    return function(name)
      players.add(name, 'money', cell.price)
    end
  end)

  monopoly.board.registerCellAction("lose", function(cell)
    return function(name)
      players.add(name, 'money', -cell.price)
    end
  end)

  monopoly.board.registerCellAction("chance", function(cell)
    return function(name)
    end
  end)

  monopoly.board.registerCellAction("chest", function(cell)
    return function(name)
    end
  end)

  local function propertyCallback(cell)
    return function(name, diceSum)
      local owner = monopoly.property.getOwner(cell.id)

      if owner then
        if owner ~= name then
          local rent = monopoly.property.calculateRent(cell, diceSum)
          players.add(name, 'money', -rent)
        end
      else
        monopoly.property.showCard(cell, name, true)
      end
    end
  end

  monopoly.board.registerCellAction("property", propertyCallback)
  monopoly.board.registerCellAction("utility", propertyCallback)
  monopoly.board.registerCellAction("station", propertyCallback)
end
