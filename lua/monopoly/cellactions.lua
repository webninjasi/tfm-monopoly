--- monopoly.cellactions

monopoly = monopoly or {}

if monopoly.__cellactions then
  return
end

monopoly.__cellactions = true


-- Dependencies
pshy.require("monopoly.board")
pshy.require("monopoly.money")


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

  monopoly.board.registerCellAction("property", function(cell)
    return function(name)
    end
  end)

  monopoly.board.registerCellAction("utility", function(cell)
    return function(name)
    end
  end)
end
