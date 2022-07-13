--- monopoly
--
-- @author TFM:Pshy#3752
-- @author TFM:Nnaaaz#0000
-- @author TFM:Lays#1146

pshy.require("lays.ui")

pshy.require("pshy.essentials")
pshy.require("pshy.perms")
pshy.require("pshy.bases.version")

pshy.require("monopoly.game")


--local loadersync = pshy.require("pshy.anticheats.loadersync")
--loadersync.enabled = true										-- Enable to force the sync player (this can cause problems with some scrips).
--local mapinfo = pshy.require("pshy.rotations.mapinfo")
--mapinfo.max_grounds = 50										-- Set the maximum amount of grounds parsed by `pshy_mapinfo`.
--local newgame = pshy.require("pshy.rotations.newgame")
--newgame.update_map_name_on_new_player = true					-- Enable or disable updating UI informations for new players.
local perms = pshy.require("pshy.perms")
perms.authors[5419276] = "Lays#1146"
perms.authors[70224600] = "Nnaaaz#0000"
perms.authors[105766424] = "Pshy#3752"
perms.auto_admin_authors = false								-- Allow the use of `!adminme` for authors in funcorp rooms.

local version = pshy.require("pshy.bases.version")
version.days_before_update_suggested = 14						-- How old the script should be before suggesting an update (`nil` to disable).
version.days_before_update_advised = 30							-- How old the script should be before requesting an update (`nil` to disable).
version.days_before_update_required = nil						-- How old the script should be before refusing to start (`nil` to disable).



function eventInit()
	print("This is the pshy_merge template example.")
	--pshy.newgame_SetRotation("#17")
	--tfm.exec.newGame()
end
