--- monopoly.votes

monopoly = monopoly or {}

if monopoly.votes then
  return
end


-- Votes Variables
local votes = {}


-- Functions
monopoly.votes = {}

monopoly.votes.reset = function(voteName)
  if voteName then
    votes[voteName] = {}
  else
    votes = {}
  end
end

monopoly.votes.vote = function(voteName, name)
  if not voteName or not name then
    return
  end

  if not votes[voteName] then
    votes[voteName] = {
      players = {},
      count = 0,
    }
  end

  if votes[voteName].players[name] then
    return
  end

  votes[voteName].players[name] = true
  votes[voteName].count = 1 + votes[voteName].count

  return votes[voteName].count
end

monopoly.votes.unvote = function(voteName, name)
  if not voteName or not name then
    return
  end

  if not votes[voteName] then
    return
  end

  if not votes[voteName].players[name] then
    return
  end

  votes[voteName].players[name] = nil
  votes[voteName].count = -1 + votes[voteName].count

  return votes[voteName].count
end
