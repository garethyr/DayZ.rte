-----------------------------------------------------------------------------------------
-- Stuff for alerting players, NPCs and zombies
-----------------------------------------------------------------------------------------
function ModularActivity:StartAlerts()
	-------------------
	--ALERT CONSTANTS--
	-------------------
	--The base value for alert strengths, technically an arbitrary number but a lot is balanced to it
	self.AlertBaseStrength = 10000;
	--The limit for the strength of alerts (based on the base strength), to avoid ridiculous noise alerts and such
	self.AlertStrengthLimit = 50000;
	--The rate at which strength is removed from alerts that have missing parents, removed every frame and individually for each type
	self.AlertBaseStrengthRemoveSpeed = self.AlertBaseStrength/1000;
	
	--The alert value at which to change activity to alerts
	self.ActorActvivityToAlertValue = 5000; -- default 5000
	--The number of MS to wait after an actor shoots to start lowering his total activity
	self.ActorActivityRemoveTime = 5000;
	--The rate at which activity is removed from actors, removed every frame
	self.ActorActivityRemoveSpeed = self.ActorActvivityToAlertValue/1000;
	
	--The base merge distance for alerts with the same (or no) target
	self.AlertBaseMergeDistance = 100;
	--The number of alerts after which the alert merge distance increases, to prevent an excessive number of alerts showing up
	self.AlertBaseMergeNumber = 5; --Every alert after this number would make the merge distance be basemergedistance*numberofalerts/basemergenumber
	--The maximum value for merge distance, so we don't have alerts merging together from all across the map
	self.AlertMaxMergeDistance = self.AlertBaseMergeDistance*5;
	
	--The number to divide the alert strength by when determining if actors are close enough to react. Greater number means less reactive.
	self.AlertAwareness = 10;
	--Not a very intuitive number, the vector magnitude difference at which actors will target alerts over other actors for spawning, etc.
	--A bigger number will mean more priority given to alerts, if the number is big enough, they'll care more about alerts than actors, etc.
	self.AlertPriorityFactor = 50; --TODO review the need and use of this, should probably be in behaviours???
	
	--The amount of time it takes for alert zombies to respawn.
	self.AlertZombieSpawnInterval = self:AlertsRequestSpawns_GetZombieSpawnInterval()/3;
	--The number of alert zombies a very high alert will spawn, used as a base for calculation of other strength alerts
	self.VeryHighAlertNumberOfZombies = 3;
	--The approximate distance at which to spawn very zombies for very low strength alerts, used as a base for calculation of other distances
	self.VeryLowAlertZombieSpawnDistance = self:AlertsRequestSpawns_GetZombieMinSpawnDistance();
	
	--The default alert value for junk items when they hit the ground, each item can have a different value
	self.JunkNoise = self.AlertBaseStrength*0.25;
	--The alert value for flashlights, not relevant if they're not included
	self.FlashlightAlertStrength = self.ActorActvivityToAlertValue;
	--A modifier for the light activity increase speed on light use, so they get slowed by some amount for balance. The actual speed is also based on the light's strength
	self.LightActivityGainModifier = 0.02;
	--The weapon alert value to compare strength with when making alerts (i.e. a weapon with 4 times this alert value will make an alert 4 times self.ActorActvivityToAlertValue)
	self.WeaponAlertStrengthComparator = "L"; --Ranges from N to VVH, see self.WeaponAlertTable for keys
	--The factor to reduce the actor's activity by after a weapon alert is made (between 0 and 1)
	self.WeaponAlertActivityReductionFactor = 0.5;

	-----------------------
	--STATIC ALERT TABLES--
	-----------------------
	--This table stores all alert making throwables and their values
	self.ThrowableAlertValues = {
		sound = {
			["Empty Tin Can"] = {strength = self.JunkNoise, ismobile = false},
			["Empty Whiskey Bottle"] = {strength = self.JunkNoise, ismobile = false},
			["Empty Coke"] = {strength = self.JunkNoise, ismobile = false},
			["Empty Pepsi"] = {strength = self.JunkNoise, ismobile = false},
			["Empty Mountain Dew"] = {strength = self.JunkNoise, ismobile = false}
		},
	
		light = {
			["Red Chemlight"] = {strength = self.AlertBaseStrength, ismobile = true},
			["Green Chemlight"] = {strength = self.AlertBaseStrength, ismobile = true},
			["Blue Chemlight"] = {strength = self.AlertBaseStrength, ismobile = true},
			["Flare"] = {strength = self.AlertBaseStrength*1.5, ismobile = true}
		}
	}
	
	--This table stores all types of alerts and is used around the script for ease. If any alert types are added they should be updated here as well
	self.AlertTypes = {"sound", "light"};
	
	--Weapon sound values (i.e. how much shooting adds) ordered from lowest (None) to highest (Very Very High), hunting knife with 0 sound is outside of this table
	self.WeaponAlertValues = {N=100, VVL=250, VL=500, L=1000, LM=1650, M=2250, MH=3250, H=4500, VH=6000, VVH=10000}; -- default 10, 25, 50, 100, 150, 200, 250, 300, 350, 500
	self.WeaponAlertTable = { --Note: weapons aren't separated by civilian/military for alerts since there's no need for that distinction here
		--Civilian weapon alert values
		["Hunting Knife"] = 0, ["Crowbar"] = 0, ["Hatchet"] = 0, ["[DZ] Makarov PM"] = self.WeaponAlertValues.L, ["[DZ] .45 Revolver"] = self.WeaponAlertValues.LM, ["[DZ] M1911A1"] = self.WeaponAlertValues.LM, ["[DZ] Compound Crossbow"] = self.WeaponAlertValues.N, ["[DZ] MR43"] = self.WeaponAlertValues.M, ["[DZ] Winchester 1866"] = self.WeaponAlertValues.LM, ["[DZ] Lee Enfield"] = self.WeaponAlertValues.VH, ["[DZ] CZ 550"] = self.WeaponAlertValues.VH,
		--Military weapons and their alert values
		["[DZ] G17"] = self.WeaponAlertValues.L, ["[DZ] AKM"] = self.WeaponAlertValues.M, ["[DZ] M16A2"] = self.WeaponAlertValues.M, ["[DZ] MP5SD6"] = self.WeaponAlertValues.VVL, ["[DZ] M4A1 CCO SD"] = self.WeaponAlertValues.VL, ["[DZ] Mk 48 Mod 0"] = self.WeaponAlertValues.H, ["[DZ] M14 AIM"] = self.WeaponAlertValues.H, ["[DZ] M107"] = self.WeaponAlertValues.VH
	};
	
	------------------------
	--DYNAMIC ALERT TABLES--
	------------------------
	--A counter for the alert table, increments each time an alert with 0 or many parents and no target is added. Not the size of the table!
	self.AlertTableCounter = 1; --Starts at 1 for nicer names, so we don't have GroundAlert0
	--A table of all alerts positions. Key is target.UniqueID when there's a target, or parent.UniqueID when there's exactly one parent and "ground"..self.AlertTableCounter+1 when there's not
	--Keys - Values
	--pos = the position, strength = the maximum of the alert's light and sound strengths, target = the actor the alert's on if there is one,
	--strengthremovespeed = the amount of strength removed from all alert types above 0 every frame, slightly greater for stronger alerts,
	--light, sound = {strength = light/sound alert strength, savedstrength = stores for the alert type when it's deactivated by map effects, parent = the creator of this alert type}
	--zombie = {actors = {table of the alert zombie(s) on it if there are any}, timer = the timer for respawning the alert zombies, counts down from when any are dead}
	self.AlertTable = {};
	
	--A table of all thrown items that create alert. Key is item.UniqueID. Cuts down on lag
	--Items will turn into alerts if their sharpness is 1.
	--Keys - Values
	--ismobile = a flag for whether or not this will be a mobile alert (i.e. one with a target),
	--light, sound = {strength = light/sound alert to be strength, parent = the creator of this alert to be type (almost certainly the item)}
	self.AlertItemTable = {};
	
	------------------------------------
	--VARIABLES USED FOR NOTIFICATIONS--
	------------------------------------
	self.AlertIsDay = nil;
	self.AlertIsStorming = false; --TODO this should be nil, change if weather is implemented
	
	--Lag Timer
	self.AlertLagTimer = Timer();
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Sets the key as the target's UniqueID if it's not nil, otherwise generates a name as the key
function ModularActivity:GenerateKeyForNewAlert(target, alertvalues)
	local key = nil;
	--Alerts with targets use their target's UniqueID
	if target ~= nil then
		key = target.UniqueID;
	--Alerts without targets use either their parent's UniqueID or a ground number
	else
		for _, atype in pairs(self.AlertTypes) do
			if key == nil and alertvalues[atype].parent ~= nil then
				key = alertvalues[atype].parent.UniqueID;
			end
		end
		if key == nil then
			key = "Ground"..tostring(self.AlertTableCounter);
			self.AlertTableCounter = self.AlertTableCounter + 1;
		end
	end
	return key;
end
--Add an alert based on parameter values or merge with any alerts on this target.
function ModularActivity:AddAlert(pos, target, alertvalues)
	--If we have an alert with this target, merge this into it
	if target ~= nil and self.AlertTable[target.UniqueID] ~= nil then
		self:MergeAlerts(self.AlertTable[target.UniqueID], alertvalues, target.UniqueID, nil);
		
		local alert = self.AlertTable[target.UniqueID];
		print ("MERGE TARGETED ALERTS FROM ADD: New alert has strength "..tostring(alert.strength).."("..tostring(alert.light.strength).." light, "..tostring(alert.sound.strength).." sound) on target "..tostring(alert.target.PresetName));
		return alert;
	end

	--Get the key for the new alert, based on its target.UniqueID, its parent.UniqueID or ground..self.AlertTableCounter
	local key = self:GenerateKeyForNewAlert(target, alertvalues);
		
	print ("ADD ALERT (Key: "..tostring(key)..") - Pos: "..tostring(pos)..", Type: "..(alertvalues.light.strength > 0 and "light" or "sound")..", Target: "..(target == nil and "None" or target.PresetName)..", Strength: "..tostring(self:GetAlertStrength(alertvalues)));
	--Add the alert to the table
	self.AlertTable[key] = {
		pos = Vector(pos.X, pos.Y), strength = self:GetAlertStrength(alertvalues), target = target,
		strengthremovespeed = self:GetInitialStrengthRemovalSpeedForAlert(alertvalues),
		zombie = {actors = {}, timer = Timer()}
	};
	self.AlertTable[key].zombie.timer.ElapsedSimTimeMS = self:GetZombieRespawnIntervalForAlert(self.AlertTable[key]) - 500; --Set the alert's zombie timer so it spawns zombies soon
	--Add the alert's strength(s) to the table
	local s = ""
	for _, atype in pairs(self.AlertTypes) do
		self.AlertTable[key][atype] = {strength = alertvalues[atype].strength, savedstrength = 0, timer = Timer(), parent = alertvalues[atype].parent};
		s = s..atype.." - ("..tostring(self.AlertTable[key][atype].strength)..","..tostring(self.AlertTable[key][atype].savedstrength).."); ";
	end
	--Set the target's alert in the human table
	self:AlertsNotifyMany_NewAlertAdded(self.AlertTable[key]);
	return self.AlertTable[key];
end
--Add a thrown item based on parameter values
function ModularActivity:AddAlertItem(item, ismobile, alertvalues)
	print ("ADD "..(ismobile and "MOBILE" or "").." THROWN ITEM (Key: "..tostring(item.UniqueID)..") - "..item.PresetName..", light: "..tostring(alertvalues.light.strength)..", sound: "..tostring(alertvalues.sound.strength));
	self.AlertItemTable[item.UniqueID] = {ismobile = ismobile};
	for _, atype in pairs(self.AlertTypes) do
		self.AlertItemTable[item.UniqueID][atype] = alertvalues[atype];
	end
end
--Make an alert from a thrown alert item, note that this is called from the item's script automatically when it's ready to become an alert
function ModularActivity:AddAlertFromAlertItem(item)
	local tab = self.AlertItemTable[item.UniqueID];
	local strengthstable = {};
	local keepparent = (not item.ToDelete) and true or false; --Set a flag to change all parents to nil if the item is dead
	for _, atype in pairs(self.AlertTypes) do
		tab[atype].parent = keepparent and tab[atype].parent or nil;
		strengthstable[atype] = tab[atype];
	end
	self:AddAlert(item.Pos, tab.ismobile and item or nil, strengthstable);
	--Notify day/night about the item if it's got light strength
	if tab.light.strength > 0 then
		self:AlertsNotifyDayNight_LightEmittingItemAdded(item);
	end
	--Remove the item from the alert item table
	self.AlertItemTable[item.UniqueID] = nil;
end
---------------------
--UTILITY FUNCTIONS--
---------------------
--GENERAL UTILITY FUNCTIONS--
function ModularActivity:NumberOfCurrentAlerts()
	local count = 0;
	for _, __ in pairs(self.AlertTable) do
		count = count + 1;
	end
	return count;
end
function ModularActivity:GetAlertMaxMergeDistance()
	local numalerts = self:NumberOfCurrentAlerts();
	if numalerts > self.AlertBaseMergeNumber then
		return math.min(self.AlertBaseMergeDistance*self:NumberOfCurrentAlerts()/self.AlertBaseMergeNumber, self.AlertMaxMergeDistance);
	end
	return self.AlertBaseMergeDistance;
end
--Merge two alerts and remove the weaker one, does not check if the alerts should be merged, that must be done elsewhere
function ModularActivity:MergeAlerts(alert1, alert2, key1, key2)
	--We always merge the weaker alert into the stronger one, unless one has no key because it is newly created, in which case the keyless one merges into the other
	local toalert, tokey = alert1, key1;
	local fromalert, fromkey = alert2, key2;
	if self:GetAlertStrength(alert2) > self:GetAlertStrength(alert1) or (key1 == nil and key2 ~= nil) then
		toalert, tokey = alert2, key2;
		fromalert, fromkey = alert1, key1;
	end

	print ("MERGING ALERT AT "..tostring(fromalert.pos).." INTO ALERT AT "..tostring(toalert.pos));
	--Do strength merging for each type, only necessary if the alert we merge from has strength in that type
	for _, atype in pairs(self.AlertTypes) do
		if fromalert[atype].strength > 0 then
			print ("changing "..atype.." parent for toalert from "..tostring(toalert[atype].parent).." to "..atype.." parent for fromalert: "..tostring(fromalert[atype].parent))
			--Set toalert's parent as fromalert's parent, if both alerts have nil as parent this will stay nil, otherwise the alert's parent will be the current light item
			toalert[atype].parent = fromalert[atype].parent; --TODO think about if this makes sense?
			toalert[atype].timer:Reset();
			--If the alerts have no target, make toalert's strength the maximum of the strengths, otherwise strength will change over time in DoAlertCreations
			if toalert.target == nil then
				print("toalert has no target, so its "..atype.." strength is max of "..tostring(toalert[atype].strength).." and "..tostring(fromalert[atype].strength).." which is "..tostring(math.max(toalert[atype].strength, fromalert[atype].strength)))
				toalert[atype].strength = math.max(toalert[atype].strength, fromalert[atype].strength);
			end
		end
	end
	self:UpdateAlertStrength(toalert);
	toalert.strengthremovespeed = self:GetInitialStrengthRemovalSpeedForAlert(toalert);
	
	self:MoveZombiesFromOneAlertToAnother(fromalert, toalert);
	
	--Remove the fromalert from self.AlertTable if we've given an index
	if fromkey ~= nil then --NOTE: Must remove manually rather than in cleanup so it doesn't send out unwanted notifications, since merged alerts shouldn't be viewed as actually being removed
		print("fromalert has a key so removing from alert table, alert with key "..tostring(fromkey));
		self.AlertTable[fromkey] = nil;
	end
end
--Check if two alerts have the same target (or no target)
function ModularActivity:AlertsHaveSameTarget(alert1, alert2)
	return (alert1.target == nil and alert2.target == nil) or (alert1.target ~= nil and alert2.target ~= nil and alert1.target.UniqueID == alert2.target.UniqueID)
end
--Return a table of all non-nil parents from the alert
function ModularActivity:GetAlertParents(alert)
	local parenttable = {};
	for _, atype in pairs(self.AlertTypes) do
		if alert[atype].parent ~= nil then
			parenttable[atype] = alert[atype].parent;
		end
	end
	return parenttable;
end
--Safely update the total strength of an alert
function ModularActivity:UpdateAlertStrength(alert)
	alert.strength = math.min(self:GetAlertStrength(alert), self.AlertStrengthLimit);
end
--Return the safe total strength given input light and sound strength
function ModularActivity:GetAlertStrength(alert)
	local strength = 0;
	for _, atype in pairs(self.AlertTypes) do
		if alert[atype].strength > strength then
			strength = alert[atype].strength;
		end
	end
	return strength;
end
--Return the calculated speed at which strength should be removed from an alert, slightly higher for 
function ModularActivity:GetInitialStrengthRemovalSpeedForAlert(alert)
	local strength = self:GetAlertStrength(alert);
	return self.AlertBaseStrengthRemoveSpeed*math.sqrt(strength/self.AlertBaseStrength);
end
--Remove strength for all alert types with more than 0 for the alert 
function ModularActivity:LowerAlertStrength(alert)
	for _, atype in pairs(self.AlertTypes) do
		if alert[atype].parent == nil then
			alert[atype].strength = math.max(0, alert[atype].strength - alert.strengthremovespeed);
		end
	end
	self:UpdateAlertStrength(alert);
end
--Return the safe strength for a weapon alert given the weapon's sound level
function ModularActivity:GetWeaponAlertStrength(soundlevel)
	return math.min(self.AlertStrengthLimit, self.ActorActvivityToAlertValue*soundlevel/self.WeaponAlertValues[self.WeaponAlertStrengthComparator]);
end
--Return a table for use in making new alerts - makes default values for any types that aren't inputted, and uses the input for any that are
function ModularActivity:GenerateAlertCreationTableFromValues(values)
	local strengthstable = {};
	for _, atype in pairs(self.AlertTypes) do
		strengthstable[atype] = {strength = 0, parent = nil};
	end
	for atype, val in pairs(values) do
		strengthstable[atype] = val;
	end
	return strengthstable;
end
--VISIBLE ALERT UTILITY FUNCTIONS--
--Return the max distance at which an alert of certain strength can be seen
function ModularActivity:AlertVisibilityDistance(alertstrength)
	return alertstrength/self.AlertAwareness;
end
--Return true if there are any visible alerts more than mindist and less than maxdist away from pos
--Visibility is affected by awarenessmod, where > 1 means alerts can be found from greater distance
function ModularActivity:CheckForVisibleAlerts(pos, awarenessmod, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, visdist;
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, self.Wrap).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			return true;
		end
	end
	return false;
end
--Return the nearest visible alert more than mindist and less than maxdist away from pos
--Visibility is affected by awarenessmod, where > 1 means alerts can be found from greater distance
function ModularActivity:NearestVisibleAlert(pos, awarenessmod, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, visdist, target = nil;
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, self.Wrap).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			maxdist = dist;
			target = alert;
		end
	end
	return target;
end
--Return all visible alerts more than mindist and less than maxdist away from pos
--Visibility is affected by awarenessmod, where > 1 means alerts can be found from greater distance
function ModularActivity:AllVisibleAlerts(pos, awarenessmod, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, visdist, alerts = {};
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, self.Wrap).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			alerts[#alerts+1] = alert;
		end
	end
	return alerts;
end
--ALERT ZOMBIE UTILITY FUNCTIONS--
--Moves all zombies from fromalert to toalert, updating their zombie table entries accordingly
function ModularActivity:MoveZombiesFromOneAlertToAnother(fromalert, toalert)
	if self.IncludeSpawns then
		local added = false; --If any zombies are added to toalert, set a flag so we reset toalert's zombie spawn timer
		--Move any zombies on fromalert to toalert
		for ID, actor in pairs(fromalert.zombie.actors) do
			local zombie = self.ZombieTable[ID];
			--Make sure we only do stuff and set flags if we actually have a table entry and it has a valid zombie
			if zombie ~= nil and MovableMan:IsActor(zombie.actor) then
				added = true;
				toalert.zombie.actors[ID] = actor; --Set the alert table value
				--If the zombie's target is still the alert, use the set target function
				if zombie.target == fromalert then
					self:SetZombieTarget(zombie.actor, toalert, "alert", toalert);
				--If the zombie's target is not the alert, just change the zombie's parent to the new alert but leave its target untouched
				else
					self.ZombieTable[ID].spawner = toalert;
				end
			end
		end
		--Reset toalert's zombie spawn timer if it's gained any zombies
		if added then
			toalert.zombie.timer:Reset();
		end
	end
end
--Returns true if an alert has zombies, does not check if the zombies exist
function ModularActivity:AlertHasZombies(alert)
	if alert.zombie == false then
		return false;
	end
	return next(alert.zombie.actors) ~= nil;
end
--Returns true if the alert has 0 zombies or less zombies than it should for its strength
function ModularActivity:AlertIsMissingZombies(alert)
	if alert.zombie ~= false then
		--Check for an empty table
		if not self:AlertHasZombies(alert) then
			return true;
		--Check for full complement of zombies
		else
			local n = 0;
			for _, zombie in pairs(alert.zombie.actors) do
				n = n+1;
			end
			if n < self:GetDesiredNumberOfZombiesForAlert(alert) then
				return true;
			end
		end
	end
	return false;
end
--Returns the number of zombies an alert has, does not check if the zombies exist
function ModularActivity:GetCurrentNumberOfZombiesForAlert(alert)
	if alert.zombie == false then
		return 0;
	end
	local n = 0;
	for _, __ in pairs(alert.zombie.actors) do
		n = n+1;
	end
	return n;
end;
--Returns the number of zombies an alert should spawn based on its strength
function ModularActivity:GetDesiredNumberOfZombiesForAlert(alert)
	if (alert.strength <= self.WeaponAlertValues.M) then
		return 1;
	end
	return math.floor(self.VeryHighAlertNumberOfZombies*alert.strength/(self.WeaponAlertValues.VH - self.WeaponAlertValues.VL)); --Subtract VL alert value from denominator to give leeway
end
--Returns a distance used to determine roughly where to spawn the zombie, which is then safety checked in spawns
function ModularActivity:GetZombieSpawnDistanceOffsetForAlert(alert)
	local i = 0;
	if alert.strength >= self.WeaponAlertValues.M then
		i = 2;
	elseif alert.strength >= self.WeaponAlertValues.L then
		i = 1;
	end
	return self.VeryLowAlertZombieSpawnDistance + self.VeryLowAlertZombieSpawnDistance*0.5*i;
end
--Return the respawn interval for the given alert
function ModularActivity:GetZombieRespawnIntervalForAlert(alert)
	--TODO flesh this stuff out through discussion with uber, 
	--	nicer to use a mathematical formula than arbitrary numbers found in Notes.txt
	return self.AlertZombieSpawnInterval;
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Main alert function, increases sound upon firing, transfers alert to locations, runs everything else
function ModularActivity:DoAlerts()
	--Clean the table before doing any alert stuff
	self:DoAlertCleanup();
	
	--Add weapon sounds on firing
	self:DoAlertHumanManageActivity();
	
	--Run the general alert making often
	self:DoAlertCreations();
	
	--Run management functions
	if self.AlertLagTimer:IsPastSimMS(100) then
		self:ManageAlerts();
		self.AlertLagTimer:Reset();
	end
	
	--Objective arrows are cleared every frame so this must always be run
	self:MakeAlertArrows();
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Clean up the alert table for a variety of reasons
function ModularActivity:DoAlertCleanup()
	for key, alert in pairs(self.AlertTable) do
		--Remove dead targets and parents from alerts
		self:RemoveDeadTargetOrParentsFromAlert(alert);
		
		--Do alert strength removal
		self:LowerAlertStrength(alert);
		
		--Update alert positions so they match their targets
		if alert.target ~= nil and alert.target.ID ~= 255 and MovableMan:ValidMO(alert.target) then
			alert.pos = Vector(alert.target.Pos.X, alert.target.Pos.Y);
		end
		
		local notremoved = true;
		
		--Remove alert because no strength left, can't just use the updated strength value because we have to account for saved strength too
		local hasstrength = #self.AlertTypes; --Iterate through all alert types and decrement for any that have no strength
		for _, atype in pairs(self.AlertTypes) do
			if alert[atype].strength <= 0 and alert[atype].savedstrength <= 0 then
				hasstrength = hasstrength - 1;
			end
		end
		if hasstrength == 0 then
			--If the alert is on an actor, set him to no longer have an alert
			self:AlertsNotifyMany_DeadAlert(alert);
			notremoved = false;
			--Remove the alert
			self.AlertTable[key] = nil;
			
			
			print ("REMOVED ALERT "..tostring(key).." WITH TARGET "..tostring(alert.target).." FROM POS "..tostring(alert.pos).."; "..tostring(self:NumberOfCurrentAlerts()).." alerts remain");
		end
		
		--Removing alerts for thrown items that are picked up, new ones get added through activity to their holder
		if notremoved and alert.target ~= nil and next(self:GetAlertParents(alert)) ~= nil then
			if alert.target.ClassName == "TDExplosive" and not MovableMan:ValidMO(alert.target) then
				if alert.target.RootID ~= alert.target.ID and alert.target.ID ~= 255 and ToAttachable(alert.target):IsAttached() and alert.target.Sharpness < 3 then
					notremoved = false;
					self.AlertTable[key] = nil;
					
					
					
					print ("ALERT "..tostring(key).." AT POS "..tostring(alert.pos).." REMOVED BECAUSE PICKED UP - ID: "..tostring(alert.target.ID)..", ROOTID: "..tostring(alert.target.RootID)..", ROOTACTOR: "..tostring(MovableMan:GetMOFromID(alert.target.RootID)));
					if self.AlertTable[MovableMan:GetMOFromID(alert.target.RootID).UniqueID] ~= nil then
						print ("Alert with same parent is at "..tostring(self.AlertTable[MovableMan:GetMOFromID(alert.target.RootID).UniqueID].pos));
					end
				end
			end
		end
	end
end
--Check if the target or any parents of the alert are dead, and if so, remove them
function ModularActivity:RemoveDeadTargetOrParentsFromAlert(alert)
	if alert.target ~= nil and (alert.target.ID == 255 or alert.target.ClassName == "Entity") then
		alert.target = nil;
	end
	for _, atype in pairs(self.AlertTypes) do
		if alert[atype].parent ~= nil and (alert[atype].parent.ID == 255 or alert[atype].parent.ClassName == "Entity") then
			alert[atype].parent = nil;
		end
	end
end
--Set the alert to be static if its actor is dead and it has no living parents, or set its target as its parent
function ModularActivity:MoveAlertFromDeadActor(alert)
	local foundparent = nil; --The living parent if there is one, otherwise nil
	for _, atype in pairs(self.AlertTypes) do
		foundparent = (alert[atype].parent.ID ~= 255 and alert[atype].parent.ClassName ~= "Entity" and MovableMan:ValidMO(alert[atype].parent)) and alert[atype].parent or nil;
		alert[atype].parent = foundparent;
		print(atype.." parent is "..tostring(foundparent));
	end
	alert.target = foundparent ~= nil and foundparent or nil;
	print("MOVE ALERT FROM DEAD ACTOR, result is "..(foundparent ~= nil and "mobile" or "static"));
end
--Set alerts for actors whose activity timers have reset to be static and, if necessary, switch their type
function ModularActivity:RemoveNonActiveActorAlert(alert, atype, actorID)
	print ("REMOVE NON ACTIVE ALERT FROM TARGET "..(tostring(alert.target)..", PARENT "..tostring(alert[atype].parent))); --TODO review how this works and fix it accordingly so it can work easily with already activated alerts
	--Figure out how many types the alert has, if it has more than one it has to be split
	local activetypes = 0;
	for k, alerttype in pairs(self.AlertTypes) do
		if alert[alerttype].strength > 0 or alert[alerttype].savedstrength > 0 then
			activetypes = activetypes + 1;
		end
	end
	
	--Get the alert strength and parent for this specific type
	local types = {};
	for _, alerttype in pairs (self.AlertTypes) do
		types[alerttype] = (alerttype == atype) and {strength = alert[atype].strength, parent = nil} or {strength = 0, parent = nil};
	end
	count = 0;
	
	--Add the split off alert and remove it from the remained alert
	alert[atype].strength = 0;
	alert[atype].savedstrength = 0;
	alert[atype].parent = nil;
	self:AddAlert(SceneMan:MovePointToGround(alert.pos, 10, 5), nil, types);
	
	--Remove the alert from the actor in the humantable if it only had one type
	if activetypes <= 1 then
		for _, humantable in pairs(self.HumanTable) do
			if humantable[actorID] ~= nil then
				humantable[actorID].alert = false;
				break;
			end
		end
	end
end
--Kill any dead held light items so they can't last forever
function ModularActivity:RemoveDeadHeldAlertItem(item, atype, actor)
	--Remove the light parent for the alert attached to the actor
	if item.Age > item.Lifetime then
		if (self.AlertTable[actor.UniqueID] ~= nil) then
			self.AlertTable[actor.UniqueID][atype].parent = nil;
		end
		item.ToDelete = true;
		return true;
	end
	return false;
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Deal with adding to humans' activity levels
function ModularActivity:DoAlertHumanManageActivity()
	for _, humantype in pairs(self.HumanTable) do
		for __, humantable in pairs(humantype) do
			local acttype = self:DoAlertHumanCheckCurrentActivity(humantable); --Check and update the actor's current activity levels
			--If the human has an activity causing item, add to his activity value (as long as it's not at the limit) and reset its calm down timer
			if acttype ~= false then
				local item = ToHeldDevice(humantable.actor.EquippedItem);
				if (acttype == "sound" and item:IsActivated() and humantable.rounds ~= ToHDFirearm(item).RoundInMagCount and not item:IsReloading()) or acttype == "light" then
					humantable.activity[acttype].total = math.min(humantable.activity[acttype].total + humantable.activity[acttype].current, self.ActorActvivityToAlertValue);
					humantable.activity[acttype].timer:Reset();
					humantable.rounds = acttype == "sound" and ToHDFirearm(item).RoundInMagCount or humantable.rounds;
				end
			end
			
			--Lower activity levels rapidly a little while after a period of no relevant activity increase
			for atype, activity in pairs(humantable.activity) do
                if activity.total > 0 and activity.timer:IsPastSimMS(self.ActorActivityRemoveTime) then
					activity.total = math.max(activity.total - self.ActorActivityRemoveSpeed, 0);
                    
                    --If the actor has an alert of this type, remove that type from the alert (if it's only got one type it will be removed soon)
                    if humantable.alert ~= false and humantable.alert[atype].strength > 0 then
                        self:RemoveNonActiveActorAlert(humantable.alert, atype, humantable.actor.UniqueID);
                    end
                end

			
				if activity.total > 0 then
					--Remove activity if the actor hasn't fired in a while
					if activity.timer:IsPastSimMS(self.ActorActivityRemoveTime) then
						activity.total = math.max(activity.total - self.ActorActivityRemoveSpeed, 0);
					
						--If the actor has an alert of this type, remove that type from the alert (if it's only got one type it will be removed soon)
						if humantable.alert ~= false and removealert and humantable.alert[atype].strength > 0 then
							self:RemoveNonActiveActorAlert(humantable.alert, atype, humantable.actor.UniqueID);
						end
					end
				end
			end
		end
	end
end
--Check for activity causing items/weapons to update activity current value
function ModularActivity:DoAlertHumanCheckCurrentActivity(tab)
	local item = tab.actor.EquippedItem;
	if item ~= nil then
		--Set the sound activity level for the actor if applicable
		if self.WeaponAlertTable[item.PresetName] ~= nil then
			tab.activity.sound.current = self.WeaponAlertTable[item.PresetName];
			return "sound";
		--Set the light activity level for the actor if applicable
		elseif self.LightAlertTable[item.PresetName] ~= nil and ToMOSRotating(item):GetNumberValue("UseState") > 0 then
			tab.activity.light.current = self.LightAlertTable[item.PresetName]*self.LightActivityGainModifier;
			--Add the item to the light table if it's not in it already (i.e. it was previously not equipped but was swapped to)
			if self:AlertsRequestDayNight_LightItemNotInTable(item) then --TODO should this be happening here? The item isn't emitting yet right?
			--	self:AlertsNotifyDayNight_LightEmittingItemAdded(item);
			print ("light up")
			end 
			return "light";
		--Set the light activity level for the actor if applicable
		elseif tab.lightOn then
			tab.activity.light.current = self.FlashlightAlertStrength*self.LightActivityGainModifier;
			return "light";
		end
	end
	return false;
end
--Return the strength of the alert to be made, given an alert type and a humantable entry, can be easily updated to handle more alert types
function ModularActivity:GetDesiredAlertStrengthFromHuman(atype, humantable)
	local item = humantable.actor.EquippedItem;
	if atype == "light" then
		local val = humantable.lightOn and self.FlashlightAlertStrength or 0;
		val = (self.LightAlertTable[item.PresetName] and ToMOSRotating(item):NumberValueExists("UseState") and ToMOSRotating(item):GetNumberValue("UseState") > 0) and self.LightAlertTable[item.PresetName] or val;
		return val ~= nil and val or 0;
	elseif atype == "sound" then
		return self:GetWeaponAlertStrength(humantable.activity.sound.current);
	end
	return 13579; --NOTE: This number is used here to indicate something screwed up in making alerts since putting 0 would be less helpful
end

--Make alerts for actor alerts and thrown entries for thrown alerting items
function ModularActivity:DoAlertCreations()
	--Do alert creation from various means, and management of alerts currently targeting humans
	for _, tables in pairs(self.HumanTable) do
		for ID, humantable in pairs(tables) do
			--Only try to create alerts if the actor has an equipped item
			local item = humantable.actor.EquippedItem;
			if item ~= nil then
				local cancreate = true;
				--Check for throwable items, create new alert items from them and remove old alerts if necessary
				if cancreate then
					for atype, throwabletable in pairs(self.ThrowableAlertValues) do
						if throwabletable[item.PresetName] and self.AlertItemTable[item.UniqueID] == nil and self.AlertTable[item.UniqueID] == nil then
							local usestate = ToMOSRotating(item):NumberValueExists("UseState") and ToMOSRotating(item):GetNumberValue("UseState") or 0;
							if (humantable.actor:GetController():IsState(Controller.WEAPON_FIRE) and (usestate == 0 or usestate == 2)) or (humantable.actor:GetController():IsState(Controller.WEAPON_DROP) and usestate == 2) then
								--Remove any alert on the actor that used the item, if it was already active
								if humantable.alert then
									self:RemoveNonActiveActorAlert(humantable.alert, atype, ID);
								end
								--Add the new alert
								self:AddAlertItem(item, throwabletable[item.PresetName].ismobile, self:GenerateAlertCreationTableFromValues({[atype] = {strength = throwabletable[item.PresetName].strength, parent = item}}));
								cancreate = false;
							end
						end
					end
				end	
				--If we have no thrown items, we're potentially working with activity values - weapon firing or holding activated light items/flashlight
				if cancreate then
					for _, atype in pairs(self.AlertTypes) do
						if humantable.activity[atype].total >= self.ActorActvivityToAlertValue and humantable.activity[atype].current > 0 then
							local alerttargetsactor = atype == "light" and true or false; --TODO this should be changed to be more extensible, allowing for mobile sound alerts
							local makenewalert = (alerttargetsactor == false or humantable.alert == false) and true or false; --Flag for whether we're making a new alert or updating a current one
							
							--Determine the strength for the alert to be made or for the current alert to be updated to
							local alertstrength = self:GetDesiredAlertStrengthFromHuman(atype, humantable);
							
							--If there's no alert or our alert-to-be doesn't target the actor, make a new one
							if makenewalert then
								--Setup alert creation values
								local alertpos = humantable.actor.Pos;
								local alerttarget = alerttargetsactor and humantable.actor or nil;
								local alertparent = alerttargetsactor and item or nil;
								
								--Reduce the actor's activity total for the alert type, so it don't keep making alerts
								humantable.activity[atype].total = atype == "light" and humantable.activity[atype].total - 1 or math.floor(humantable.activity[atype].total*self.WeaponAlertActivityReductionFactor);

								--Generate an alert creation table for the alert-to-be
								local strengthstable = self:GenerateAlertCreationTableFromValues({[atype] = {strength = alertstrength, parent = alertparent}});
								
								--Add the alert and pass it to the humantable if needed
								local alert = self:AddAlert(alertpos, alerttarget, strengthstable);
								humantable.alert = alerttargetsactor and alert or humantable.alert;
								
							--If there's an alert and our alert-to-be targets the actor, update its strength
							else
								local speed = humantable.alert.strengthremovespeed;
								if humantable.alert[atype].strength > alertstrength + 2*speed then
									humantable.alert[atype].strength = humantable.alert[atype].strength - speed;
								elseif humantable.alert[atype].strength < alertstrength - 2*speed then
									humantable.alert[atype].strength = humantable.alert[atype].strength + speed;
								elseif humantable.alert[atype].strength <= alertstrength + 2*speed and humantable.alert[atype].strength >= alertstrength - 2*speed then
									humantable.alert[atype].strength = alertstrength;
								end
							end
							cancreate = false;
						end
					end
				end
			end
		end
	end
end
--Count down all alerts, merge alerts that are close to each other
function ModularActivity:ManageAlerts() 
	--General update loop
	for k, alert in pairs(self.AlertTable) do
		--Merge nearby alerts
		for otherkey, otheralert in pairs(self.AlertTable) do --TODO alert merge range should depend on the number of alerts in total, more alerts means bigger range
			if k ~= otherkey and self:AlertsHaveSameTarget(alert, otheralert) and SceneMan:ShortestDistance(alert.pos, otheralert.pos, self.Wrap).Magnitude < self:GetAlertMaxMergeDistance() then
				self:MergeAlerts(alert, otheralert, k, otherkey);
			end
		end
		
		self:ManageAlertZombieSpawns(alert);
	end
end
--Spawn and respawn zombies for alerts that don't have them
--Note that cleaning the alert's zombie table is done in utilities, as it is handled when the zombie dies and is removed from the zombie table
function ModularActivity:ManageAlertZombieSpawns(alert)
	--If the alert doesn't have zombies and its alert's zombie respawn timer is ready, add them until it has all its zombies
	if self.IncludeSpawns and self:AlertIsMissingZombies(alert) and alert.zombie.timer:IsPastSimMS(self:GetZombieRespawnIntervalForAlert(alert)) then
		print ("check for alert spawning zombies, alert currently has "..tostring(self:GetCurrentNumberOfZombiesForAlert(alert)).." out of "..tostring(self:GetDesiredNumberOfZombiesForAlert(alert)).." zombies");
		--If the alert doesn't have its full set of zombies, add them in
		if self:GetCurrentNumberOfZombiesForAlert(alert) < self:GetDesiredNumberOfZombiesForAlert(alert) then
			for i = 1, self:GetDesiredNumberOfZombiesForAlert(alert) - self:GetCurrentNumberOfZombiesForAlert(alert) do
				local zombieactor = self:AlertsRequestSpawns_SpawnAlertZombie(alert, self:GetZombieSpawnDistanceOffsetForAlert(alert));
				if zombieactor == false then
					alert.zombie = false;
				else
					alert.zombie.actors[zombieactor.UniqueID] = zombieactor;
				end
			end
		end
		if alert.zombie ~= false then
			alert.zombie.timer:Reset();
		end
	--If there are no missing zombies for the alert, keep the timer at 0
	elseif self.IncludeSpawns and not self:AlertIsMissingZombies(alert) and alert.zombie ~= false then
		alert.zombie.timer:Reset();
	end
end
--Add objective points for alert positions
function ModularActivity:MakeAlertArrows()
	for _, players in pairs(self.HumanTable.Players) do
		for __, alert in pairs(self.AlertTable) do
			--Only add the points if the player is closer than the alert's strength divided by the awareness constant
			if SceneMan:ShortestDistance(alert.pos, players.actor.Pos, self.Wrap).Magnitude <  self:AlertVisibilityDistance(alert.strength) then
				--Modify alert's location and change the displayed text if it's mobile
				local pos = alert.pos;
				local st = "";
				if alert.target ~= nil then
					pos = alert.target.AboveHUDPos - Vector(0, 100);
					st = "Mobile ";
				end
				--Set the displayed alert type
				if alert.light.strength > 0 and alert.sound.strength > 0 then
					st = st.."Light and Sound";
				else
					st = alert.light.strength > 0 and "Light" or "Sound";
				end
				
				--Add the objective point
				--self:AddObjectivePoint(st.." Alert", pos, self.PlayerTeam, GameActivity.ARROWDOWN);
				self:AddObjectivePoint(st.." Alert\nStrength: "..tostring(math.ceil(alert.strength/1000)).."\nPos: "..tostring(alert.pos).."\nBase Pull Distance: "..tostring(self:AlertVisibilityDistance(alert.strength)).."\nTarget: "..tostring(alert.target)..(alert.light.parent == nil and "" or ("\nLight Parent: "..tostring(alert.light.parent)))..(alert.sound.parent == nil and "" or ("\nSound Parent: "..tostring(alert.sound.parent))), pos, self.PlayerTeam, GameActivity.ARROWDOWN);
			end
		end
	end
end