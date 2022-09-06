--- cellactions

local board = pshy.require("monopoly.board")
local property = pshy.require("monopoly.property")
local players = pshy.require("monopoly.players")
local logs = pshy.require("monopoly.logs")
local randcard = pshy.require("monopoly.randcard")


-- Events
function eventInit()
  board.registerCellAction("win", function(cell)
    return function(name, sum, player)
      if cell.id == 1 then
        logs.add('log_passed_go', player.colorname)
      end

      players.add(name, 'money', cell.price)
    end
  end)

  board.registerCellAction("lose", function(cell)
    return function(name, sum, player)
      players.add(name, 'money', -cell.price)

      if cell.price == 100 then
        logs.add('luxury_tax', player.colorname)
      elseif cell.price == 200 then
        logs.add('income_tax', player.colorname)
      end
    end
  end)

  board.registerCellAction("chance", function(cell)
    return function(name, sum, player)
      logs.add('chance_space', player.colorname)
      randcard.chance(name, player)
    end
  end)

  board.registerCellAction("chest", function(cell)
    return function(name, sum, player)
      logs.add('community_chest', player.colorname)
      randcard.community(name, player)
    end
  end)

  board.registerCellAction("jail", function(cell)
    return function(name, sum, player)
      player.jail = 0
    end
  end)

  local function propertyCallback(cell)
    return function(name, dice_sum, player)
      local owner = property.getOwner(cell.id)

      if owner then
        if owner ~= name then
          local rent = property.calculateRent(cell, dice_sum)

          if rent == 0 then
            logs.add('mortgage_property', player.colorname, cell, players.get(owner, "colorname"))
          else
            players.add(name, 'money', -rent)
            players.add(owner, 'money', rent)
            logs.add('pay_rent', player.colorname, rent, players.get(owner, "colorname"))
          end
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
