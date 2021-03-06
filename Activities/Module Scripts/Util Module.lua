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
-- Add to screentext for all players OR optional player(s)
-----------------------------------------------------------------------------------------
function ModularActivity:AddScreenText(text, ...)
	local arg = {...};
	if #arg == 0 then
		for i = 0, self.PlayerCount do
			if self.ScreenText[i+1] == nil or self.ScreenText[i+1] == "" then
				self.ScreenText[i+1] = text;
			else
				self.ScreenText[i+1] = self.ScreenText[i+1].."\n"..text;
			end
		end
	else
		for i = 1, #arg do
			if self.ScreenText[arg[i]+1] == nil or self.ScreenText[arg[i]+1] == "" then
				self.ScreenText[arg[i]+1] = text;
			else
				self.ScreenText[arg[i]+1] = self.ScreenText[arg[i]+1].."\n"..text;
			end
		end
	end
end
-----------------------------------------------------------------------------------------
-- Sort maxdist and mindist inputs so they parse correctly even if the order is mixed up
-----------------------------------------------------------------------------------------
function ModularActivity:SortMaxAndMinArguments(dists)
	local mindist = dists[1];
	local maxdist = dists[2];
	--If we have both max and min dists, make sure they're set right
	if maxdist ~= nil and mindist ~= nil then
		mindist = math.min(dists[1], dists[2]);
		maxdist = math.max(dists[1], dists[2]);
	--Otherwise, the mindist is already set so set the maxdist to a large number
	elseif maxdist == nil then
		maxdist = SceneMan.SceneWidth*10;
	end
	--If we enter no minimum distance, set it to 0
	if mindist == nil then
		mindist = 0;
	end
	return mindist, maxdist;
end
-----------------------------------------------------------------------------------------
-- Return true if there is a human more than mindist and less than maxdist away from the passed in pos
-----------------------------------------------------------------------------------------
function ModularActivity:CheckForNearbyHumans(pos, humantype, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist;
	for htype, humantable in pairs(self.HumanTable) do
		if (humantype == nil or humantype == htype) then
			for _, v in pairs(humantable) do
				dist = SceneMan:ShortestDistance(pos, v.actor.Pos, self.Wrap).Magnitude;
				if dist >= mindist and dist <= maxdist then
					return true;
				end
			end
		end
	end
	return false;
end
-----------------------------------------------------------------------------------------
-- Find the nearest human, more than mindist and less than maxdist to a point. Returns nil if none found
-----------------------------------------------------------------------------------------
function ModularActivity:NearestHuman(pos, humantype, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, target;
	for htype, humantable in pairs(self.HumanTable) do
		if (humantype == nil or humantype == htype) then
			for _, v in pairs(humantable) do
				dist = SceneMan:ShortestDistance(pos, v.actor.Pos, self.Wrap).Magnitude;
				if dist >= mindist and dist <= maxdist then
					maxdist = dist;
					target = v.actor;
				end
			end
		end
	end
	return target;
end
-----------------------------------------------------------------------------------------
-- Return true if there is a zombie more than mindist and less than maxdist away from the passed in pos
-----------------------------------------------------------------------------------------
function ModularActivity:CheckForNearbyZombies(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist;
	for _, v in pairs(self.ZombieTable) do
		dist = SceneMan:ShortestDistance(pos, v.actor.Pos, self.Wrap).Magnitude;
		if dist >= mindist and dist <= maxdist then
			return true;
		end
	end
	return false;
end
-----------------------------------------------------------------------------------------
-- Find the nearest zombie, more than mindist and less than maxdist to a point. Returns nil if none found
-----------------------------------------------------------------------------------------
function ModularActivity:NearestZombie(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, target;
	for _, v in pairs(self.ZombieTable) do
		dist = SceneMan:ShortestDistance(pos, v.actor.Pos, self.Wrap).Magnitude;
		if dist >= mindist and dist <= maxdist then
			maxdist = dist;
			target = v.actor;
		end
	end
	return target;
end
-----------------------------------------------------------------------------------------
-- Get the inputted position constrained inside the inputted box/area
-----------------------------------------------------------------------------------------
function ModularActivity:GetPositionConstrainedInArea(areacentre, pos, areawidth, areaheight)
	local box = Box(Vector(areacentre.X - areawidth/2, areacentre.Y - areaheight/2), Vector(areacentre.X + areawidth/2, areacentre.Y + areaheight/2));
	return self:GetPositionConstrainedInBox(pos, box);
end
function ModularActivity:GetPositionConstrainedInBox(pos, box)
	return box:GetWithinBox(pos);
end
-----------------------------------------------------------------------------------------
-- Functions for adding actors to all active mission tables, for convenient updating
-----------------------------------------------------------------------------------------
-- Add a player
function ModularActivity:AddToPlayerTable(actor, player)
	self.HumanTable.Players[actor.UniqueID] = {
		actor = actor, player = player, lightOn = false, alert = false, rounds = 0,
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
		actor = actor, player = -1, lightOn = false, alert = false, rounds = 0,
		activity = {
			sound = {current = 0, total = 0, timer = Timer()},
			light = {current = 0, total = 0, timer = Timer()},
		}
	};
	self:RequestSustenance_AddToSustenanceTable(actor);
end
-- Add a zombie
function ModularActivity:AddToZombieTable(actor, targetval, targettype, spawner, startdist)
	self.ZombieTable[actor.UniqueID] = {
		actor = actor, spawner = spawner,
		target = {val = targetval, ttype = targettype, startdist = startdist}
	};
end
-- Remove a zombie and, if it's spawned by an alert, remove it from the alert's zombie table
function ModularActivity:RemoveFromZombieTable(actor)
	if type(self.ZombieTable[actor.UniqueID].spawner) == "table" then --If the zombie was spawned by an alert, remove it from the alert's list of zombies
		self.ZombieTable[actor.UniqueID].spawner.zombie.actors[actor.UniqueID] = nil;
	end
	self.ZombieTable[actor.UniqueID] = nil;
end