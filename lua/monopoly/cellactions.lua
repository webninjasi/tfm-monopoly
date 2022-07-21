--- monopoly.cellactions

monopoly = monopoly or {}

if monopoly.__cellactions then
  return
end

monopoly.__cellactions = true


-- Dependencies
pshy.require("monopoly.board")
pshy.require("monopoly.money")
pshy.require("monopoly.property")


-- Events
function eventInit()
  monopoly.board.registerCellAction("win", function(cell)
    return function(name)
      monopoly.money.give(name, cell.price)
    end
  end)

  monopoly.board.registerCellAction("lose", function(cell)
    return function(name)
      monopoly.money.take(name, cell.price)
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
    return function(name)
      local owner = monopoly.property.getOwner(cell.title)

      if owner then
        if owner ~= name then
          local rent = monopoly.property.calculateRent(cell)
          monopoly.money.take(name, rent)
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
