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
	self.ActorActivityToAlertValue = 5000;
	--The number of MS to wait after an actor shoots to start lowering his total activity
	self.ActorActivityRemoveTime = 5000;
	--The rate at which activity is removed from actors, removed every frame
	self.ActorActivityRemoveSpeed = self.ActorActivityToAlertValue/1000;
	
	--The base merge distance for alerts with the same (or no) target
	self.AlertBaseMergeDistance = 100;
	--The number of alerts after which the alert merge distance increases, to prevent an excessive number of alerts showing up
	self.AlertBaseMergeNumber = 5; --Every alert after this number would make the merge distance be basemergedistance*numberofalerts/basemergenumber
	--The maximum value for merge distance, so we don't have alerts merging together from all across the map
	self.AlertMaxMergeDistance = self.AlertBaseMergeDistance*5;
	
	--The number to divide the alert strength by when determining if actors are close enough to react. Greater number means less reactive.
	self.AlertGeneralVisibilityDistanceModifier = 10;
	
	--The number of zombies a base strength alert will spawn, stronger alerts will spawn more zombies based on this while weaker ones will spawn fewer. Note that the number spawned will never be below 1
	self.AlertBaseZombieCount = 1;
	--The amount of deviation to allow when calculating the number of zombies to spawn for an alert
	--E.g. an alert needing 100 strength to spawn 2 zombies but only having 95, could still spawn 2 zombies if the deviation is greater than 5
	self.ZombieSpawnCountStrengthRequirementDeviation = self.AlertBaseStrength*.1;
	--The approximate distance at which to spawn very zombies for weakest alerts, used as a base for calculation of other distances
	self.AlertBaseZombieSpawnDistance = self:AlertsRequestSpawns_GetZombieMinSpawnDistance();
	--The amount of time it takes for alert zombies to respawn.
	self.AlertBaseZombieSpawnInterval = self:AlertsRequestSpawns_GetZombieSpawnInterval()/3;
	
	--The default alert value for junk items when they hit the ground, each item can have a different value
	self.JunkNoise = self.AlertBaseStrength*0.25;
	--The alert value for flashlights, not relevant if they're not included
	self.FlashlightAlertStrength = self.ActorActivityToAlertValue;
	--A modifier for how fast held items add activity to the actor holding them, the actual speed at which they add is also based on their activity strength
	self.ActivatedHeldItemActivityGainModifier = 0.02;
	--The weapon alert value to compare strength with when making alerts (i.e. a weapon with 4 times this alert value will make an alert 4 times self.ActorActivityToAlertValue)
	self.WeaponAlertStrengthComparator = "L"; --Ranges from N to VVH, see self.WeaponActivityValues for keys
	--The factor to reduce the actor's activity by after a weapon alert is made (between 0 and 1)
	self.WeaponAlertActivityReductionFactor = 0.5;
	
	--The radius of an alert with strength of self.AlertBaseStrength, weaker alerts have smaller circles and stronger ones have larger circles
	self.AlertIconBaseRadius = 10;
	--A table of colours for alerts, check the palette to see what the colour each number corresponds to
	self.AlertIconColours = {centrefill = 253, ismobile = 12, onactor = 147, sound = 197, light = 122};
	--The size of any extra circles outside of the alert type displays, the actual size scales with alert radius to a point
	self.AlertIconExtraCircleSize = 3;

	-----------------------
	--STATIC ALERT TABLES--
	-----------------------
	--This table stores all types of alerts and is used around the script for ease. If any alert types are added they should be updated here as well
	self.AlertTypes = {"sound", "light"};
	
	--This table stores specific alert types that aren't directly covered in other tables, note that each entry can have multiple types
	self.SpecificAlertTypes = {
		["Flashlight"] = {"light"},
		["Weapon"] = {"sound"} --TODO integrate this table more deeply, particularly the weapon part
	};
	
	--This table stores all alert making throwables and their values
	self.ThrowableItemAlertValues = { --TODO change throwable table so the atype is contained in the table and just the item is the key, so throwables could have multiple alert types
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
	};
	
	--Weapon sound values (i.e. how much shooting adds) ordered from lowest (None) to highest (Very Very High), hunting knife with 0 sound is outside of this table
	self.WeaponActivityLevels = {N=100, VVL=250, VL=500, L=1000, LM=1650, M=2250, MH=3250, H=4500, VH=6000, VVH=self.AlertStrengthLimit/self.ActorActivityToAlertValue};
	self.WeaponActivityValues = { --Note: weapons aren't separated by civilian/military for alerts since there's no need for that distinction here
		--Civilian weapon alert values
		["Hunting Knife"] = 0, ["Crowbar"] = 0, ["Hatchet"] = 0, ["[DZ] Makarov PM"] = self.WeaponActivityLevels.L, ["[DZ] .45 Revolver"] = self.WeaponActivityLevels.LM, ["[DZ] M1911A1"] = self.WeaponActivityLevels.LM, ["[DZ] Compound Crossbow"] = self.WeaponActivityLevels.N, ["[DZ] MR43"] = self.WeaponActivityLevels.M, ["[DZ] Winchester 1866"] = self.WeaponActivityLevels.LM, ["[DZ] Lee Enfield"] = self.WeaponActivityLevels.VH, ["[DZ] CZ 550"] = self.WeaponActivityLevels.VH,
		--Military weapons and their alert values
		["[DZ] G17"] = self.WeaponActivityLevels.L, ["[DZ] AKM"] = self.WeaponActivityLevels.M, ["[DZ] M16A2"] = self.WeaponActivityLevels.M, ["[DZ] M4A1 CCO SD"] = self.WeaponActivityLevels.VL, ["[DZ] MP5SD6"] = self.WeaponActivityLevels.VVL, ["[DZ] Mk 48 Mod 0"] = self.WeaponActivityLevels.H, ["[DZ] M14 AIM"] = self.WeaponActivityLevels.H, ["[DZ] M107"] = self.WeaponActivityLevels.VH
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
	--zombievalue = either a table of zombie actors to treat as this alert's zombies or the key for an alert to share zombies from so when this item becomes an alert it shares that alert's zombies
	self.AlertItemTable = {};
	
	--A table for whether each type of alert is disabled or enabled
	self.AlertTypesDisabledTable = {};
	
	---------------
	--OTHER STUFF--
	---------------
	--Lag Timer
	self.AlertLagTimer = Timer();
end
----------------------
--CREATION FUNCTIONS--
----------------------
function ModularActivity:____ALERT_CREATION____() end
--Returns a key that is the target's or, failing that, parent's UniqueID if it's not nil, otherwise generates a name as the key
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
--Sets an alert's key in the table to a newly generated key for the target
function ModularActivity:GenerateNewKeyForAlertWithNewTarget(oldkey, target)
	if self.AlertTable[oldkey] ~= nil then
		local alert = self.AlertTable[oldkey];
		local newkey = self:GenerateKeyForNewAlert(target, alert);
		self.AlertTable[newkey] = alert;
		self.AlertTable[oldkey] = nil;
	end
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
		
	print ("ADD ALERT (Key: "..tostring(key)..") - Pos: "..tostring(pos)..", Type: "..(alertvalues.light.strength > 0 and "light" or "sound")..", Target: "..(target == nil and "None" or target.PresetName));
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
		if self.AlertTypesDisabledTable[atype] then
			self.AlertTable[key][atype].strength, self.AlertTable[key][atype].savedstrength = self.AlertTable[key][atype].savedstrength, self.AlertTable[key][atype].strength;
		end
		s = s..atype.." - ("..tostring(self.AlertTable[key][atype].strength)..","..tostring(self.AlertTable[key][atype].savedstrength).."); ";
	end
	print("Newly added alert strengths are: "..s)
	--Set the target's alert in the human table
	self:AlertsNotifyMany_NewAlertAdded(self.AlertTable[key]);
	return self.AlertTable[key];
end
--Add a thrown item based on parameter values
function ModularActivity:AddAlertItem(item, ismobile, alertvalues, zombievalue)
	print ("ADD "..(ismobile and "MOBILE" or "").." THROWN ITEM (Key: "..tostring(item.UniqueID)..") - "..item.PresetName..", light: "..tostring(alertvalues.light.strength)..", sound: "..tostring(alertvalues.sound.strength)..", zombievalue: "..(type(zombievalue) == "table" and "table of zombies" or tostring(zombievalue)));
	self.AlertItemTable[item.UniqueID] = {ismobile = ismobile, zombievalue = zombievalue};
	for _, atype in pairs(self.AlertTypes) do
		self.AlertItemTable[item.UniqueID][atype] = alertvalues[atype];
	end
end
--Make an alert from a thrown alert item, note that this is called from the item's script automatically when it's ready to become an alert
function ModularActivity:AddAlertFromAlertItem(item)
	local itemtable = self.AlertItemTable[item.UniqueID];
	local strengthstable = {};
	local keepparent = (not item.ToDelete) and true or false; --Set a flag to change all parents to nil if the item is dead
	for _, atype in pairs(self.AlertTypes) do
		itemtable[atype].parent = keepparent and itemtable[atype].parent or nil;
		strengthstable[atype] = itemtable[atype];
	end
	local alert = self:AddAlert(item.Pos, itemtable.ismobile and item or nil, strengthstable);
	--Do zombie actions as needed, if zombievalue is a table then set this alert's zombie actors as that table, otherwise share zombies from the alert whose key is zombievalue
	if type(itemtable.zombievalue) == "table" then
		print ("zombievalue is table so setting zombie actors to table")
		alert.zombie.actors = itemtable.zombievalue;
	else
		print ("zombievalue is "..tostring(itemtable.zombievalue)..", so sharing zombies from "..(self.AlertTable[itemtable.zombievalue] == nil and "nil" or "table"))
		self:ShareZombiesBetweenTwoAlerts(self.AlertTable[itemtable.zombievalue], alert);
	end
	--Notify day/night about the item if it's got light strength
	if itemtable.light.strength > 0 and self:AlertsRequestDayNight_LightItemNotInTable(item) then
		self:AlertsNotifyDayNight_LightEmittingItemAdded(item);
	end
	--Remove the item from the alert item table
	self.AlertItemTable[item.UniqueID] = nil;
end
---------------------
--UTILITY FUNCTIONS--
---------------------
function ModularActivity:____ALERT_UTILITY____() end
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
--Return the total strength given input light and sound strength
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
			alert[atype].savedstrength = math.max(0, alert[atype].savedstrength - alert.strengthremovespeed);
		end
	end
	self:UpdateAlertStrength(alert);
end
--Return the safe strength for a weapon alert given the weapon's sound level
function ModularActivity:GetWeaponAlertStrength(soundlevel)
	return math.min(self.AlertStrengthLimit, self.ActorActivityToAlertValue*soundlevel/self.WeaponActivityLevels[self.WeaponAlertStrengthComparator]);
end
--Return whether or not the equipped item is an alert making item as well as its alert type
function ModularActivity:ItemCanMakeAlert(item, lighton)
	if item ~= nil then
		if lighton then
			return true, self.SpecificAlertTypes.Flashlight;
		elseif self.WeaponActivityValues[item.PresetName] ~= nil then
			return true, self.SpecificAlertTypes.Weapon;
		else
			for atype, throwabletable in pairs(self.ThrowableItemAlertValues) do
				if throwabletable[item.PresetName] ~= nil then
					return true, {atype};
				end
			end
		end
	end
	return false;
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
--DISABLING ALERT UTILITY FUNCTIONS--
function ModularActivity:____ALERT_DISABLING____() end
--Update which types of alerts are disabled/enabled so it matches the current state of the environmental factors that affect it
function ModularActivity:UpdateDisabledAlertTypes()
	if self.IncludeDayNight and not self.DayNightIsNight and self.IsOutside then
		self:SetDisabledAlertType("light", true);
	else
		self:SetDisabledAlertType("light", false);
	end
end
--Set whether an alert of a certain type should be disabled or enabled
function ModularActivity:SetDisabledAlertType(atype, isdisabled)
	self.AlertTypesDisabledTable[atype] = isdisabled;
	--Disable any alerts of the inputted type
	if isdisabled then
		for _, alert in pairs(self.AlertTable) do
			alert[atype].savedstrength, alert[atype].strength = alert[atype].strength, 0;
		end
	--Reenable any alerts of the inputted type, set its zombie timer to its interval so it checks whether or not it needs to spawn zombies
	elseif not isdisabled then
		for _, alert in pairs(self.AlertTable) do
			if alert[atype].savedstrength > 0 then
				alert[atype].strength, alert[atype].savedstrength = alert[atype].savedstrength, 0;
				alert.zombie.timer.ElapsedSimTimeMS = self:GetZombieRespawnIntervalForAlert(alert);
			end
		end
	end
end
--Check whether or not any of the entered types are disabled
function ModularActivity:AnyOfAlertTypesDisabled(atypes)
	if type(atypes) ~= "table" then
		atypes = {atypes};
	end
	for _, atype in pairs(atypes) do
		if self.AlertTypesDisabledTable[atype] == true then
			return true;
		end
	end
	return false;
end
--Check whether or not all of the entered types are disabled
function ModularActivity:AllOfAlertTypesDisabled(atypes)
	if type(atypes) ~= "table" then
		atypes = {atypes};
	end
	for _, atype in pairs(atypes) do
		if self.AlertTypesDisabledTable[atype] ~= true then
			return false;
		end
	end
	return true;
end
--VISIBLE ALERT UTILITY FUNCTIONS--
function ModularActivity:____ALERT_VISIBILITY____() end
--Return the max distance at which an alert of certain strength can be seen
function ModularActivity:AlertVisibilityDistance(alertstrength)
	return alertstrength/self.AlertGeneralVisibilityDistanceModifier;
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
	local dist, visdist, target;
	local alerts = {};
	
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
	local dist, visdist;
	local alerts = {};
	
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
function ModularActivity:____ALERT_ZOMBIES____() end
--Moves all zombies from fromalert to toalert, updating their zombie table information accordingly
function ModularActivity:MoveZombiesFromOneAlertToAnother(fromalert, toalert)
	if self.IncludeSpawns and fromalert.zombie ~= false then
		local added = false; --If any zombies are added to toalert, set a flag so we reset toalert's zombie spawn timer
		--Move any zombies on fromalert to toalert
		for ID, actor in pairs(fromalert.zombie.actors) do
			local zombie = self.ZombieTable[ID];
			--Make sure we only do stuff and set flags if we actually have a table entry and it has a valid zombie
			if zombie ~= nil and MovableMan:IsActor(zombie.actor) then
				added = true;
				toalert.zombie.actors[ID] = actor;
				--If the zombie's target is still the alert, use the set target function to set it as the new alert
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
		--Remove the zombies from fromalert
		fromalert.zombie.actors = {};
		fromalert.zombie.timer:Reset();
	end
end
--Shares a table of alert zombies between two alerts, does not update zombie table information at all
function ModularActivity:ShareZombiesBetweenTwoAlerts(fromalert, toalert)
	if self.IncludeSpawns and fromalert ~= nil and fromalert.zombie ~= false and toalert ~= nil then
		toalert.zombie.actors = fromalert.zombie.actors;
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
	if alert.zombie ~= false and alert.strength > 0 then
		--Check for an empty table
		if not self:AlertHasZombies(alert) then
			return true;
		--Check for full complement of zombies
		else
			local n = 0;
			for _, actor in pairs(alert.zombie.actors) do
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
	return math.max(1, math.floor(self.AlertBaseZombieCount*(alert.strength + self.ZombieSpawnCountStrengthRequirementDeviation)/self.AlertBaseStrength));
end
--Returns a distance used to determine roughly where to spawn the zombie, which is then safety checked in spawns
function ModularActivity:GetZombieSpawnDistanceOffsetForAlert(alert)
	local i = 0;
	if alert.strength >= self.AlertBaseStrength then
		i = 2;
	elseif alert.strength >= self.AlertBaseStrength * .5 then --TODO kill off this magic number, talk again with uber about how we should do this. Maybe there should be an overall table of alert strengths aside from weapon strengths
		i = 1;
	end
	return self.AlertBaseZombieSpawnDistance + self.AlertBaseZombieSpawnDistance*0.5*i;
end
--Return the respawn interval for the given alert
function ModularActivity:GetZombieRespawnIntervalForAlert(alert)
	--TODO flesh this stuff out through discussion with uber, 
	--	nicer to use a mathematical formula than arbitrary numbers found in Notes.txt
	return self.AlertBaseZombieSpawnInterval;
end
--------------------
--UPDATE FUNCTIONS--
--------------------
function ModularActivity:____ALERT_UPDATING____() end
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
	
	--Run alert display functions so players get a visual idea of their locations
	self:DoAlertIconDisplay();
end
--------------------
--DELETE FUNCTIONS--
--------------------
function ModularActivity:____ALERT_DELETION____() end
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
					local actorTarget = MovableMan:GetMOFromID(alert.target.RootID);
					for _, humantable in pairs(self.HumanTable) do
						if humantable[actorTarget.UniqueID] ~= nil then
							--If the human has no alert, move this alert to him
							if humantable[actorTarget.UniqueID].alert == false then
								print ("ALERT "..tostring(key).." AT POS "..tostring(alert.pos).." MOVED TO ACTOR BECAUSE PICKED UP - ID: "..tostring(alert.target.ID)..", ROOTID: "..tostring(alert.target.RootID)..", ROOTACTOR: "..tostring(MovableMan:GetMOFromID(alert.target.RootID)));
								alert.target = actorTarget;
								self:GenerateNewKeyForAlertWithNewTarget(key, alert.target);
								humantable[actorTarget.UniqueID].alert = alert;
							--Otherwise, move zombies from this alert to the human's alert and remove delete this alert
							else
								print ("ALERT "..tostring(key).." AT POS "..tostring(alert.pos).." DELETED BECAUSE PICKED UP - ID: "..tostring(alert.target.ID)..", ROOTID: "..tostring(alert.target.RootID)..", ROOTACTOR: "..tostring(MovableMan:GetMOFromID(alert.target.RootID)));
								self:MoveZombiesFromOneAlertToAnother(alert, humantable[actorTarget.UniqueID].alert);
								self.AlertTable[key] = nil;
							end
						end
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
		foundparent = (alert[atype].parent ~= nil and alert[atype].parent.ID ~= 255 and alert[atype].parent.ClassName ~= "Entity" and MovableMan:ValidMO(alert[atype].parent)) and alert[atype].parent or nil;
		alert[atype].parent = foundparent;
		print(atype.." parent is "..tostring(foundparent));
	end
	alert.target = foundparent ~= nil and foundparent or nil;
	print("MOVE ALERT FROM DEAD ACTOR, result is "..(foundparent ~= nil and "mobile" or "static"));
end
--Set alerts for actors whose activity timers have reset to be static and, if necessary, switch their type
function ModularActivity:RemoveNonActiveActorAlert(alert, atype, actorID)
	print ("REMOVE NON ACTIVE ALERT FROM TARGET "..(tostring(alert.target)..", PARENT "..tostring(alert[atype].parent)));
	--Figure out how many types the alert has, if it has more than one it has to be split
	local activetypes = 0;
	for _, alerttype in pairs(self.AlertTypes) do
		if alert[alerttype].strength > 0 or alert[alerttype].savedstrength > 0 then
			activetypes = activetypes + 1;
		end
	end
	
	--Get the alert strength and parent for this specific type
	local types = self:GenerateAlertCreationTableFromValues({[atype] = {strength = math.max(alert[atype].strength, alert[atype].savedstrength), parent = nil}});
	
	--Add the split off alert and remove it from the remained alert
	alert[atype].strength = 0;
	alert[atype].savedstrength = 0;
	alert[atype].parent = nil;
	local newalert = self:AddAlert(SceneMan:MovePointToGround(alert.pos, 10, 5), nil, types);
	
	--Share any zombies between the two alerts, so no random extra zombies spawn
	self:ShareZombiesBetweenTwoAlerts(alert, newalert);
	
	--Remove the alert from the actor in the humantable if it only had one type
	if activetypes <= 1 then
		for _, humantable in pairs(self.HumanTable) do
			if humantable[actorID] ~= nil then
				humantable[actorID].alert = false;
				break;
			end
		end
	end
	print ("Result is old alert with strength "..tostring(alert[atype].strength).." and new alert with strength "..tostring(newalert[atype].strength))
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
function ModularActivity:____ALERT_ACTIONS____() end
--Deal with adding to humans' activity levels
function ModularActivity:DoAlertHumanManageActivity()
	for _, humantype in pairs(self.HumanTable) do
		for __, humantable in pairs(humantype) do
			local acttype = self:DoAlertHumanCheckCurrentActivity(humantable); --Check and update the actor's current activity levels
			--If the human has an activity causing item, add to his activity value (as long as it's not at the limit) and reset its calm down timer
			if acttype ~= false then
				local item = ToHeldDevice(humantable.actor.EquippedItem);
				--If the item is a weapon that is firing or is not a weapon, add to the human's activity total
				if (self.WeaponActivityValues[item.PresetName] ~= nil and item:IsActivated() and humantable.rounds ~= ToHDFirearm(item).RoundInMagCount and not item:IsReloading()) or self.WeaponActivityValues[item.PresetName] == nil then
					humantable.activity[acttype].total = math.min(humantable.activity[acttype].total + humantable.activity[acttype].current, self.ActorActivityToAlertValue);
					humantable.activity[acttype].timer:Reset();
					humantable.rounds = acttype == "sound" and ToHDFirearm(item).RoundInMagCount or humantable.rounds;
				end
			end
			
			--Lower activity levels rapidly a little while after a period of no relevant activity increase
			for atype, activity in pairs(humantable.activity) do
                if activity.total > 0 and activity.timer:IsPastSimMS(self.ActorActivityRemoveTime) then
					activity.total = math.max(activity.total - self.ActorActivityRemoveSpeed, 0);
                    
                    --If the actor has an alert of this type, remove that type from the alert (if it's only got one type it will be removed soon)
                    if humantable.alert ~= false and (humantable.alert[atype].strength > 0 or humantable.alert[atype].savedstrength > 0) then
                        self:RemoveNonActiveActorAlert(humantable.alert, atype, humantable.actor.UniqueID);
                    end
                end
			end
		end
	end
end
--Check for activity causing items/weapons to update activity current value
function ModularActivity:DoAlertHumanCheckCurrentActivity(humantable)
	local item = humantable.actor.EquippedItem;
	if item ~= nil then
		--Set the sound activity level for the actor if applicable
		if self:AnyOfAlertTypesDisabled(self.SpecificAlertTypes.Weapon) == false and self.WeaponActivityValues[item.PresetName] ~= nil then
			humantable.activity.sound.current = self.WeaponActivityValues[item.PresetName];
			return "sound";
		--Set the light activity level for the actor if applicable
		elseif self:AnyOfAlertTypesDisabled(self.SpecificAlertTypes.Flashlight) == false and humantable.lightOn then
			humantable.activity.light.current = self.FlashlightAlertStrength*self.ActivatedHeldItemActivityGainModifier;
			return "light";
		--Set the light activity level for the actor if applicable
		else
			for atype, throwables in pairs(self.ThrowableItemAlertValues) do
				if throwables[item.PresetName] ~= nil and self:AnyOfAlertTypesDisabled(atype) == false and ToMOSRotating(item):NumberValueExists("UseState") and ToMOSRotating(item):GetNumberValue("UseState") > 0 then
					humantable.activity[atype].current = throwables[item.PresetName].strength*self.ActivatedHeldItemActivityGainModifier;
					return atype;
				end
			end
		end
	end
	return false;
end
--Return the strength of the alert to be made, given an alert type and a humantable entry, can be easily updated to handle more alert types
function ModularActivity:GetDesiredAlertStrengthFromHuman(atype, humantable)
	local item = humantable.actor.EquippedItem;
	--If it's a weapon, return the result of the calculation function
	if self.WeaponActivityValues[item.PresetName] ~= nil then
		return self:GetWeaponAlertStrength(humantable.activity.sound.current);
	--Otherwise it's a throwable, return its table value if it's activated, or 0 otherwise
	else
		local val = humantable.lightOn and self.FlashlightAlertStrength or 0;
		if self.ThrowableItemAlertValues[atype][item.PresetName] ~= nil and ToMOSRotating(item):NumberValueExists("UseState") and ToMOSRotating(item):GetNumberValue("UseState") > 0 then
			val = self.ThrowableItemAlertValues[atype][item.PresetName].strength;
		end
		return val ~= nil and val or 0;
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
			local itemcanmakealert, atypes = self:ItemCanMakeAlert(item, humantable.lightOn)
			if itemcanmakealert then
				for __, atype in pairs(atypes) do --TODO think about how this would or wouldn't work with items that actually have multiple atypes (both thrown and not held/fired)
					local usestate = ToMOSRotating(item):NumberValueExists("UseState") and ToMOSRotating(item):GetNumberValue("UseState") or 0;
				
					--Add the item to the light table if it's light emitting and not in it already (i.e. it was previously not equipped but was swapped to)
					if atype == "light" and  usestate == 2 and self:AlertsRequestDayNight_LightItemNotInTable(item) then
						self:AlertsNotifyDayNight_LightEmittingItemAdded(item);
					end
				
					local cancreate = true;
					--Check for throwable items, create new alert items from them and remove old alerts if necessary
					if cancreate then
						local throwabletable = self.ThrowableItemAlertValues[atype];
						if throwabletable[item.PresetName] and self.AlertItemTable[item.UniqueID] == nil and self.AlertTable[item.UniqueID] == nil then
							if (humantable.actor:GetController():IsState(Controller.WEAPON_FIRE) and (usestate == 0 or usestate == 2)) or (humantable.actor:GetController():IsState(Controller.WEAPON_DROP) and usestate == 2) then
								--Add the new alert item
								self:AddAlertItem(item, throwabletable[item.PresetName].ismobile, self:GenerateAlertCreationTableFromValues({[atype] = {strength = throwabletable[item.PresetName].strength, parent = item}}), humantable.actor.UniqueID);
								humantable.activity[atype].total = 0; --Zero the human's total activity for this type so the script doesn't try to make more alerts for him if he's holding another activity generating item
								cancreate = false;
							end
						end
					end	
					--If we have no thrown items, we're potentially working with activity values - weapon firing or holding activated light items/flashlight
					if cancreate then
						if humantable.activity[atype].total >= self.ActorActivityToAlertValue and humantable.activity[atype].current > 0 then							
							local alerttargetsactor = false;
							if humantable.lightOn or (self.ThrowableItemAlertValues[atype][item.PresetName]~= nil and self.ThrowableItemAlertValues[atype][item.PresetName].ismobile) then
								alerttargetsactor = true;
							end
							--Only make a new alert if the human has none or this won't be targeted
							local makenewalert = (alerttargetsactor == false or humantable.alert == false) and true or false;
							
							--Determine the strength for the alert to be made or for the current alert to be updated to
							local alertstrength = self:GetDesiredAlertStrengthFromHuman(atype, humantable);
														
							--If there's no alert or our alert-to-be doesn't target the actor, make a new one
							if makenewalert then
								print (atype.." alert creation, total activity is "..tostring(humantable.activity[atype].total)..", current activity is "..tostring(humantable.activity[atype].current));

								--Setup alert creation values
								local alertpos = humantable.actor.Pos;
								local alerttarget = alerttargetsactor and humantable.actor or nil;
								local alertparent = alerttargetsactor and item or nil;
								
								--Reduce the actor's activity total for the alert type, so it doesn't keep making alerts --TODO maybe only have to do it for weapons?
								humantable.activity[atype].total = atype == "light" and humantable.activity[atype].total - 1 or math.floor(humantable.activity[atype].total*self.WeaponAlertActivityReductionFactor);

								--Generate an alert creation table for the alert-to-be
								local strengthstable = self:GenerateAlertCreationTableFromValues({[atype] = {strength = alertstrength, parent = alertparent}});
								
								--Add the alert and pass it to the humantable if needed
								local alert = self:AddAlert(alertpos, alerttarget, strengthstable);
								humantable.alert = alerttargetsactor and alert or humantable.alert;
								
							--If there's an alert and our alert-to-be targets the actor, and this strength type isn't disabled, simply update its strength and, if necessary, parent
							else
								if self:AnyOfAlertTypesDisabled(atype) == false and alertstrength > 0 then
									local speed = humantable.alert.strengthremovespeed*10;
									if humantable.alert[atype].strength > alertstrength + 2*speed then
										humantable.alert[atype].strength = humantable.alert[atype].strength - speed;
									elseif humantable.alert[atype].strength < alertstrength - 2*speed then
										humantable.alert[atype].strength = humantable.alert[atype].strength + speed;
									--Once the alert's strength is close to what it should be, stabilize it and set its parent to the item
									elseif humantable.alert[atype].strength ~= alertstrength and humantable.alert[atype].strength <= alertstrength + 2*speed and humantable.alert[atype].strength >= alertstrength - 2*speed then
										humantable.alert[atype].strength = alertstrength;
										--If this alert targets the actor and the alert already on the actor's parent is not this item, set the parent to the item
										if alerttargetsactor and humantable.alert[atype].parent.UniqueID ~= item.UniqueID then
											humantable.alert[atype].parent = item;
										end
									end
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
function ModularActivity:DoAlertIconDisplay()
	if self.IncludeIcons then
		local xmult = function(screen) if FrameMan.HSplit and (screen == 1 or screen == 3) then return 1 else return 0 end end --Return a multiplier for screen X positioning, based on the current player
		local ymult = function(screen) if FrameMan.VSplit and (screen == 2 or screen == 3) then return 1 else return 0 end end --Return a multiplier for screen Y positioning, based on the current player
		for _, playertable in pairs(self.HumanTable.Players) do
			for __, alert in pairs(self.AlertTable) do
				--Only add the points if the player is closer than the alert's strength divided by the awareness constant
				if SceneMan:ShortestDistance(alert.pos, playertable.actor.Pos, self.Wrap).Magnitude < self:AlertVisibilityDistance(alert.strength) then
					--Get the alert's information so the icon can change accordingly
					local ismobile = alert.target ~= nil;
					local onactor = ismobile and alert.target.UniqueID == playertable.actor.UniqueID;
					local strength = self:GetAlertStrength(alert);
					local radius = self.AlertIconBaseRadius*math.sqrt(strength/self.AlertBaseStrength);
					local iconpos = ismobile and Vector(alert.pos.X, ToMOSprite(alert.target).BoundingBox.Corner.Y - 25) or Vector(alert.pos.X, alert.pos.Y - 25);
					--Move the icon position so it's constrained within the player's screen
					local areacentre = Vector(FrameMan.PlayerScreenWidth*0.5 + FrameMan.PlayerScreenWidth*xmult(playertable.player) + SceneMan:GetOffset(playertable.player).X, FrameMan.PlayerScreenHeight*0.5 + FrameMan.PlayerScreenHeight*ymult(playertable.player) + SceneMan:GetOffset(playertable.player).Y);
					iconpos = self:GetPositionConstrainedInArea(areacentre, iconpos, FrameMan.PlayerScreenWidth - (radius+5), FrameMan.PlayerScreenHeight - (radius+5));
					
					--Determine the circles that need to be drawn
					local circles = {};
					if ismobile then
						local sizeaddition = math.max(self.AlertIconExtraCircleSize*0.5, math.min(self.AlertIconExtraCircleSize*2, (self.AlertIconExtraCircleSize*radius/self.AlertIconBaseRadius)));
						circles[#circles+1] = onactor and {colourtype = "onactor", radius = radius + sizeaddition} or {colourtype = "ismobile", radius = radius + sizeaddition};
					end
					local outercircles = #circles;
					for i, atype in ipairs(self.AlertTypes) do
						if alert[atype].strength > 0 then
							circles[#circles+1] = {colourtype = atype, radius = radius/(#circles - outercircles + 1)};
						end
					end
					circles[#circles+1] = {colourtype = "centrefill", radius = radius/(#circles - outercircles + 2)}
					
					--Draw the icon circles
					for i, circle in ipairs(circles) do
						local colour = self.AlertIconColours[circle.colourtype] ~= nil and self.AlertIconColours[circle.colourtype] or 0;
						FrameMan:DrawCircleFillPrimitive(iconpos, circle.radius, colour);
					end
					
					--Add the objective point
					--self:AddObjectivePoint(st.." Alert", pos, self.PlayerTeam, GameActivity.ARROWDOWN);
					--self:AddObjectivePoint(st.." Alert\nStrength: "..tostring(math.ceil(alert.strength/1000)).."\nPos: "..tostring(alert.pos).."\nBase Pull Distance: "..tostring(self:AlertVisibilityDistance(alert.strength)).."\nTarget: "..tostring(alert.target)..(alert.light.parent == nil and "" or ("\nLight Parent: "..tostring(alert.light.parent)))..(alert.sound.parent == nil and "" or ("\nSound Parent: "..tostring(alert.sound.parent))), pos, self.PlayerTeam, GameActivity.ARROWDOWN);
				end
			end
		end
	end
end