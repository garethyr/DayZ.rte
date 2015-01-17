-----------------------------------------------------------------------------------------
-- NECESSARY MODULE: A grouping of all the utility functions in the mod
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Split a string into a table, based on the inputted separator
-----------------------------------------------------------------------------------------
function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields;
end
-----------------------------------------------------------------------------------------
-- Trim off whitespace from a string, also returns the trimmed string for convenience
-----------------------------------------------------------------------------------------
function string:trim()
	self = self:gsub("^%s+", ""):gsub("%s+$", "");
	return self;
end
-----------------------------------------------------------------------------------------
-- Trims all the strings in a table, does not throw errors for non-string values
-----------------------------------------------------------------------------------------
function ModularActivity:TrimTable(tab)
	for k, v in pairs(tab) do
		if type(v) == "string" then
			tab[k] = v:trim();
		end
	end
	return tab;
end
-----------------------------------------------------------------------------------------
-- Sort maxdist and mindist inputs so they parse correctly even if the order is mixed up
-----------------------------------------------------------------------------------------
function ModularActivity:SortMaxAndMinArguments(dists)
	local mindist = dists[1];
	local maxdist = dists[2];
	--If we have both max and min dists, make sure they're set right
	if maxdist ~= nil then
		mindist = math.min(dists[1], dists[2]);
		maxdist = math.max(dists[1], dists[2]);
	--Otherwise, the mindist is already set so set the maxdist to a large number
	else
		maxdist = SceneMan.SceneWidth*10;
	end
	return mindist, maxdist;
end
-----------------------------------------------------------------------------------------
-- Find the nearest human to a point
-----------------------------------------------------------------------------------------
function ModularActivity:NearestHuman(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments(arg);
	local dist, target;
	for _, humantable in pairs(self.HumanTable) do
		for __, v in pairs(humantable) do
			dist = SceneMan:ShortestDistance(pos, v.actor.Pos, true).Magnitude;
			if dist >= mindist and dist <= maxdist then
				maxdist = dist;
				target = v.actor;
			end
		end
	end
	return target;
end
-----------------------------------------------------------------------------------------
-- Find whether or not there are humans less than maxdist away from the passed in pos
-----------------------------------------------------------------------------------------
function ModularActivity:CheckForNearbyHumans(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments(arg);
	local dist;
	for _, humantable in pairs(self.HumanTable) do
		for __, v in pairs(humantable) do
			dist = SceneMan:ShortestDistance(pos, v.actor.Pos, true).Magnitude;
			if dist >= mindist and dist <= maxdist then
				return true;
			end
		end
	end
	return false;
end
-----------------------------------------------------------------------------------------
-- Functions for adding actors to all active mission tables, for convenient updating
-----------------------------------------------------------------------------------------
-- Add a player
function ModularActivity:AddToPlayerTable(actor)
	self.HumanTable.Players[actor.UniqueID] = {
		actor = actor, lightOn = false, alert = false, rounds = 0,
		activity = {
			sound = {current = 0, total = 0, timer = Timer()},
			light = {current = 0, total = 0, timer = Timer()}
		}
	};
	self:RequestSustenance_AddToSustenanceTable(actor);
	self:RequestIcons_AddToMeterTable(actor);
end
-- Add an NPC
function ModularActivity:AddToNPCTable(actor)
	self.HumanTable.NPCs[actor.UniqueID] = {
		actor = actor, lightOn = false, alert = false, rounds = 0,
		activity = {
			sound = {current = 0, total = 0, timer = Timer()},
			light = {current = 0, total = 0, timer = Timer()},
		}
	};
	self:RequestSustenance_AddToSustenanceTable(actor);
end
-- Add a zombie
function ModularActivity:AddToZombieTable(actor, target, targettype, startdist)
	self.ZombieTable[actor.UniqueID] = {actor = actor, target = {val = target, ttype = targettype, startdist = startdist}};
end