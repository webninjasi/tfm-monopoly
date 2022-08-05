local _concat = table.concat
return {
  ["en"] = {
    ["pass go"] = function(player) return _concat({ "<J>player ", player, " passed GO, and he collected $200" }) end,
    ["rolling dice once"] = function(player, dice1, dice2, dicesum) return _concat({ "<J>player ", player, " rolled a ", dice1, " and ", dice2, " for ", dicesum, "" }) end,
    ["rolling dice double"] = function(player, dice1, dice2, dicesum) return _concat({ "<J>player ", player, " rolled double ", dice1, " and ", dice2, " for ", dicesum, "" }) end,
    ["rolling dice doube jail"] = function(player) return _concat({ "<J>player ", player, " rolled double 3 times, now he go to jail." }) end,
    ["move"] = function(player, movedtoproperty) return _concat({ "<J>player ", player, " moved to ", movedtoproperty, "" }) end,
    ["purchase"] = function(player, purchaseproperty) return _concat({ "<J>player ", player, " purchased ", purchaseproperty, "" }) end,
    ["auction"] = function(player, auctionproperty) return _concat({ "<J>player ", player, " purchased ", auctionproperty, "" }) end,
    ["pay rent"] = function(player, money, playerowner) return _concat({ "<J>player ", player, " payed ", money, " in rent to ", playerowner, "" }) end,
    ["jail in"] = function(player) return _concat({ "<J>player ", player, " Go to jail move directly to jail do not pass \"GO\" do not collect $200" }) end,
    ["jail out"] = function(player) return _concat({ "<J>player ", player, " is out of jail" }) end,
  },
}