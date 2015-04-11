-----------------------------------------------------------------------------------------
-- Stuff for alerting players, NPCs and zombies
-----------------------------------------------------------------------------------------
function ModularActivity:StartAlerts()
	-------------------
	--ALERT CONSTANTS--
	-------------------
	--The alert value at which to change activity to alerts
	self.AlertValue = 5000; -- default 5000
	--The base value for alert lifetimes, in MS, only applies to alerts that aren't being renewed
	self.AlertBaseLifetime = 5000;
	--The base value for alert strengths, technically an arbitrary number but a lot is balanced to it
	self.AlertBaseStrength = 10000;
	--The limit for the strength of alerts (based on the base strength), to avoid ridiculous noise alerts and such
	self.AlertStrengthLimit = 50000;
	--The number of MS to wait after an actor shoots to start lowering his total activity
	self.ActorActivityRemoveTime = 5000;
	--The rate at which activity is removed from actors, removed every MS
	self.ActorActivityRemoveSpeed = 10;
	
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
	self.JunkNoise = self.AlertValue*0.5;
	--The alert value for flashlights, not relevant if they're not included
	self.FlashlightAlertStrength = self.AlertValue*.1;
	--A modifier for the light activity increase speed on light use, so they get slowed by some amount for balance. The actual speed is also based on the light's strength
	self.LightActivityGainModifier = 0.02;
	--The weapon alert value to compare strength with when making alerts (i.e. a weapon with 4 times this alert value will make an alert 4 times self.AlertValue)
	self.WeaponAlertStrengthComparator = "L"; --Ranges from N to VVH, see self.WeaponAlertTable for keys
	--The factor to reduce the actor's activity by after a weapon alert is made (between 0 and 1)
	self.WeaponAlertActivityReductionFactor = 0.5;

	-----------------------
	--STATIC ALERT TABLES--
	-----------------------
	--This table stores all junk items
	self.JunkAlertTable = {["Empty Tin Can"] = self.JunkNoise, ["Empty Whiskey Bottle"] = self.JunkNoise, ["Empty Coke"] = self.JunkNoise, ["Empty Pepsi"] = self.JunkNoise, ["Empty Mountain Dew"] = self.JunkNoise};
	
	--This table stores all light making throwables and their alert values
	self.LightAlertTable = {["Red Chemlight"] = self.AlertBaseStrength, ["Green Chemlight"] = self.AlertBaseStrength, ["Blue Chemlight"] = self.AlertBaseStrength, ["Flare"] = self.AlertBaseStrength*1.5};
	
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
	self.AlertTableCounter = 0;
	--A table of all alerts positions. Key is target.UniqueID when there's a target, or parent.UniqueID when there's exactly one parent and "ground"..self.AlertTableCounter+1 when there's not
	--Keys - Values
	--pos = the position, strength = the maximum of the alert's light and sound strengths, target = the actor the alert's on if there is one,
	--light, sound = {strength = light/sound alert strength, savedstrength = stores for the alert type when it's deactivated by map effects,
	--					timer = light/sound killtimer, parent = the creator of this alert type}
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
--Add an alert based on parameter values or merge with any alerts on this target.
function ModularActivity:AddAlert(pos, target, light, sound)
	--If we have an alert with this target, merge this into it
	if target ~= nil and self.AlertTable[target.UniqueID] ~= nil then
		--Trick self:MergeAlert by making a temporary table with correctly named variables and merge it
		local tempalert = {light = light, sound = sound}; 
		self:MergeAlerts(self.AlertTable[target.UniqueID], tempalert, nil);
		
		local v = self.AlertTable[target.UniqueID];
		print ("MERGE TARGETED ALERTS FROM ADD: New alert has strength "..tostring(v.strength).."("..tostring(v.light.strength).." light, "..tostring(v.sound.strength).." sound) on target "..tostring(v.target.PresetName));
		return;
	end

	--Get the key for the new alert, based on its target.UniqueID, its parent.UniqueID or ground..self.AlertTableCounter+1
	local key;
	if target ~= nil then
		key = target.UniqueID;
	elseif light.parent ~= nil then
		key = light.parent.UniqueID;
	elseif sound.parent ~= nil then
		key = sound.parent.UniqueID;
	else
		key = "Ground"..tostring(self.AlertTableCounter + 1);
		self.AlertTableCounter = self.AlertTableCounter + 1;
	end
		
	print ("ADD ALERT (Key: "..tostring(key)..") - Pos: "..tostring(pos)..", Type: "..(light.strength > 0 and "light" or "sound")..(target == nil and ", No Target" or ", "..target.PresetName)..", Strength: "..tostring(self:GetAlertStrength(light.strength, sound.strength)));
	--Add the alert to the table
	self.AlertTable[key] = {
		pos = Vector(pos.X, pos.Y), strength = self:GetAlertStrength(light.strength, sound.strength), target = target,
		light = {strength = light.strength, savedstrength = 0, timer = Timer(), parent = light.parent},
		sound = {strength = sound.strength, savedstrength = 0, timer = Timer(), parent = sound.parent},
		zombie = {actors = {}, timer = Timer()}
	};
	self.AlertTable[key].zombie.timer.ElapsedSimTimeMS = self:GetZombieRespawnIntervalForAlert(self.AlertTable[key]) - 500; --Set the alert's zombie timer so it spawns zombies soon
	--Set the target's alert in the human table
	self:AlertsNotifyMany_NewAlertAdded(self.AlertTable[key]);
end
--Add a thrown item based on parameter values
function ModularActivity:AddAlertItem(item, ismobile, light, sound)
	print ("ADD "..(ismobile and "MOBILE" or "").." THROWN ITEM (Key: "..tostring(item.UniqueID)..") - "..item.PresetName..", light: "..tostring(light.strength)..", sound: "..tostring(sound.strength));
	self.AlertItemTable[item.UniqueID] = {ismobile = ismobile, light = light, sound = sound};
end
--Make an alert from a thrown alert item, note that this is called from the item's script automatically when it's ready to become an alert
function ModularActivity:AddAlertFromAlertItem(item)
	local tab = self.AlertItemTable[item.UniqueID];
	self:AddAlert(item.Pos, tab.ismobile and item or nil, tab.light, tab.sound);
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
--Merge two alerts and remove the second (fromalert), does not check if the alerts are be mergeable
function ModularActivity:MergeAlerts(toalert, fromalert, fromindex)
	print ("MERGING ALERT AT "..tostring(fromalert.pos).." INTO ALERT AT "..tostring(toalert.pos));
	--Do light merging, only necessary if the alert we merge from has light
	if fromalert.light.strength > 0 then
		toalert.light.parent = fromalert.light.parent --If both alerts are nil this will stay nil, otherwise the alert's parent will be the current light item
		toalert.light.timer:Reset();
		--If the alert has no target, make its strength the maximum of the strengths, otherwise strength will change over time from DoAlertCreations
		if toalert.target == nil then
			toalert.light.strength = math.max(toalert.light.strength, fromalert.light.strength);
		end
	end
	--Do sound merging, only necessary if the alert we merge from has sound
	if fromalert.sound.strength > 0 then
		toalert.sound.parent = fromalert.sound.parent --If both alerts are nil this will stay nil, otherwise the alert's parent will be the current sound item
		toalert.sound.timer:Reset();
		--If the alert has no target, make its strength the maximum of the strengths, otherwise strength will change over time from DoAlertCreations
		if toalert.target == nil then
			toalert.sound.strength = math.max(toalert.sound.strength, fromalert.sound.strength);
		end
	end
	self:SetAlertStrength(toalert);
	
	--Remove the fromalert from self.AlertTable if we've given an index
	if fromindex ~= nil then
		self.AlertTable[fromindex] = nil;
	end
end
--Check if two alerts have the same target (or no target)
function ModularActivity:AlertsHaveSameTarget(alert1, alert2)
	return (alert1.target == nil and alert2.target == nil) or (alert1.target ~= nil and alert2.target ~= nil and alert1.target.UniqueID == alert2.target.UniqueID)
end
--Safely update the total strength of an alert
function ModularActivity:SetAlertStrength(alert)
	print ("updating alert strength, previous alert strength = "..tostring(alert.strength))
	alert.strength = self:GetAlertStrength(alert.light.strength, alert.sound.strength);
	print("updated alert strength, new strength is "..tostring(alert.strength));
end
--Return the safe total strength given input light and sound strength
function ModularActivity:GetAlertStrength(lightstrength, soundstrength)
	return math.max(lightstrength, soundstrength);
end
--Return the safe strength for a weapon alert given the weapon's sound level
function ModularActivity:GetWeaponAlertStrength(soundlevel)
	return math.min(self.AlertStrengthLimit, self.AlertValue*soundlevel/self.WeaponAlertValues[self.WeaponAlertStrengthComparator]);
end
--Return the max distance at which an alert of certain strength can be seen
function ModularActivity:AlertVisibilityDistance(alertstrength)
	return alertstrength/self.AlertAwareness;
end
--VISIBLE ALERT UTILITY FUNCTIONS--
--Return true if there are any visible alerts more than mindist and less than maxdist away from pos
--Visibility is affected by awarenessmod, where > 1 means alerts can be found from greater distance
function ModularActivity:CheckForVisibleAlerts(pos, awarenessmod, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
	local mindist, maxdist = self:SortMaxAndMinArguments({...});
	local dist, visdist;
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, true).Magnitude;
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
		dist = SceneMan:ShortestDistance(pos, alert.pos, true).Magnitude;
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
		dist = SceneMan:ShortestDistance(pos, alert.pos, true).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			alerts[#alerts+1] = alert;
		end
	end
	return alerts;
end
--ALERT ZOMBIE UTILITY FUNCTIONS--
--Returns true if the alert has 0 zombies or less zombies than it should for its strength
function ModularActivity:AlertIsMissingZombies(alert)
	if alert.zombie ~= false then
		--Check for an empty table
		if next(alert.zombie.actors) == nil then
			return true;
		--Check for full complement of zombies
		else
			local n = 0;
			for _, zombie in pairs(alert.zombie.actors) do
				n = n+1;
			end
			if n < self:GetNumberOfZombiesForAlert(alert) then
				return true;
			end
		end
	end
	return false;
end
--Returns the number of zombies an alert should spawn based on its strength
function ModularActivity:GetNumberOfZombiesForAlert(alert)
	local alertstrength = self:GetAlertStrength(alert.light.strength, alert.sound.strength);
	if (alertstrength <= self.WeaponAlertValues.M) then
		return 1;
	end
	return math.floor(self.VeryHighAlertNumberOfZombies*alertstrength/(self.WeaponAlertValues.VH - self.WeaponAlertValues.VL)); --Subtract VL alert value from denominator to give leeway
end
--Returns a distance used to determine roughly where to spawn the zombie, which is then safety checked in spawns
function ModularActivity:GetZombieSpawnDistanceOffsetForAlert(alert)
	local alertstrength = self:GetAlertStrength(alert.light.strength, alert.sound.strength);
	local i = 0;
	if alertstrength >= self.WeaponAlertValues.M then
		i = 2;
	elseif alertstrength >= self.WeaponAlertValues.L then
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
	
	--Update all alert strengths and mobile alert positions
	for _, alert in pairs(self.AlertTable) do
		SetAlertStrength(alert);
		if alert.target ~= nil and MovableMan:ValidMO(alert.target) then
			alert.pos = Vector(alert.target.Pos.X, alert.target.Pos.Y);
		end
	end
	
	--Add weapon sounds on firing
	self:DoAlertHumanAddActivity();
	
	--Run the general alert making often
	self:DoAlertCreations();
	
	--Run management functions
	if self.AlertLagTimer:IsPastSimMS(100) then
		self:ManageAlertPoints();
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
	for k, v in pairs(self.AlertTable) do
		local canremove = true;
		
		--Check if the alert is over its lifetime
		for _, atype in pairs(self.AlertTypes) do
			if (v[atype].strength > 0 or v[atype].savedstrength > 0) and v[atype].timer:IsPastSimMS(self.AlertBaseLifetime) then
				v[atype].strength = 0;
				v[atype].savedstrength = 0;
			end
		end
		
		--Remove alert because no strength left
		if v.light.strength <= 0 and v.light.savedstrength <= 0 and v.sound.strength <= 0 and v.sound.savedstrength <= 0 then
			--If the alert is on an actor, set him to no longer have an alert
			self:AlertsNotifyMany_DeadAlert(v);
			canremove = false;
			--Remove the alert
			self.AlertTable[k] = nil;
			
			
			--TODO PRINTING DELETE
			local num = 0;
			for kk, vv in pairs(self.AlertTable) do
				num = num + 1;
			end
			print ("REMOVED ALERT "..tostring(k).." WITH TARGET "..tostring(v.target).." FROM POS "..tostring(v.pos).."; "..tostring(num).." alerts remain");
		end
		
		--Handle changes in target for explosives (emitting items), dead target, target picked up or dropped
		if canremove and v.target ~= nil and (v.target.ClassName == "TDExplosive" or v.target.ClassName == "Entity") and not MovableMan:ValidMO(v.target) then
			--Remove alerts for thrown alert items that are picked up, new ones get added to their holder
			if v.target.RootID ~= v.target.ID and v.target.ID ~= 255 and ToAttachable(v.target):IsAttached() and v.target.Sharpness < 3 then
				print ("ALERT "..tostring(k).." AT POS "..tostring(v.pos).." REMOVED BECAUSE PICKED UP - ID: "..tostring(v.target.ID)..", ROOTID: "..tostring(v.target.RootID)..", ROOTACTOR: "..tostring(MovableMan:GetMOFromID(v.target.RootID)));
				if self.AlertTable[MovableMan:GetMOFromID(v.target.RootID).UniqueID] ~= nil then
					print ("Alert with same parent is at "..tostring(self.AlertTable[MovableMan:GetMOFromID(v.target.RootID).UniqueID].pos));
				end
				canremove = false;
				self.AlertTable[k] = nil;
			--Otherwise the alert parent is dead so set its alert to nonmobile
			elseif v.target.ID == 255 then
				print ("ALERT "..tostring(k).." AT POS "..tostring(v.pos).." SET TO NON MOBILE - ID: "..tostring(v.target.ID)..", ROOT: "..tostring(v.target.RootID));
				canremove = false;
				v.target = nil;
				for _, atype in pairs(self.AlertTypes) do
					v[atype].parent = nil;
				end
			end
		end
	end
end
--Set the alert to be static if its actor is dead
function ModularActivity:MoveAlertFromDeadActor(alert)
	alert.target = nil;
	print("MOVE ALERT FROM DEAD ACTOR");
end
--Set alerts for actors whose activity timers have reset to be static and, if necessary, switch their type
function ModularActivity:RemoveNonActiveActorAlert(alert, atype, actorID, actortype)
	print ("REMOVE NON ACTIVE ALERT FROM TARGET "..(tostring(alert.target)..", PARENT "..tostring(alert[atype].parent)));
	local removealert = alert;
	--If the alert has both sound and light, it has to be split
	local activetypes = 0;
	for k, atype in pairs(self.AlertTypes) do
		if alert[atype].strength > 0 or alert[atype].savedstrength > 0 then
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
	alert[atype].savedstrength = 0; --TODO Fix this removing the alert from a rethrown light item when it's dropped to ground from an actor
	alert[atype].parent = nil;
	self:AddAlert(SceneMan:MovePointToGround(alert.pos, 10, 5), nil, types.light, types.sound);
	
	--Remove the alert from the actor in the humantable if it only had one type
	if activetypes <= 1 then
		self.HumanTable[actortype][actorID].alert = false;
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
function ModularActivity:DoAlertHumanAddActivity()
	for humankey, tab in pairs(self.HumanTable) do
		for __, v in pairs(tab) do
			local acttype = self:DoAlertHumanCheckCurrentActivity(v); --Check and update the actor's current activity levels
			--If the human has an activity causing item, add to his activity value (as long as it's not at the limit) and reset its calm down timer
			if acttype ~= false then
				local item = ToHeldDevice(v.actor.EquippedItem);
				if (acttype == "sound" and item:IsActivated() and v.rounds ~= ToHDFirearm(item).RoundInMagCount and not item:IsReloading()) or acttype == "light" then
					v.activity[acttype].total = math.min(v.activity[acttype].total + v.activity[acttype].current, self.AlertValue);
					v.activity[acttype].timer:Reset();
					v.rounds = acttype == "sound" and ToHDFirearm(item).RoundInMagCount or v.rounds;
				end
			end
			
			--Lower activity levels rapidly a little while after a period of no relevant activity increase
			for atype, activity in pairs(v.activity) do
				if activity.total > 0 and activity.timer:IsPastSimMS(self.ActorActivityRemoveTime) then
					activity.total = math.max(activity.total - self.ActorActivityRemoveSpeed, 0);
					
					--If the actor has an alert of this type, remove that type from the alert (if it's only got one type it will be removed soon)
					if v.alert ~= false and v.alert[atype].strength > 0 then
						self:RemoveNonActiveActorAlert(v.alert, atype, v.actor.UniqueID, humankey);
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
		elseif self.LightAlertTable[item.PresetName] ~= nil and item.Sharpness > 0 then
			--Make sure the light isn't past its lifetime but still being held, if it is it will be killed
			if not self:RemoveDeadHeldAlertItem(item, "light", tab.actor) then
				tab.activity.light.current = self.LightAlertTable[item.PresetName]*self.LightActivityGainModifier;
				--Add the item to the light table if it's not in it already (i.e. it was previously not equipped but was swapped to)
				if self:AlertsRequestDayNight_LightItemNotInTable(item) then
					self:AlertsNotifyDayNight_LightEmittingItemAdded(item);
				end
				return "light";
			end
		--Set the light activity level for the actor if applicable
		elseif tab.lightOn then
			tab.activity.light.current = self.FlashlightAlertStrength*self.LightActivityGainModifier;
			return "light";
		end
	end
	return false;
end

--Make alerts for actor alerts and thrown entries for thrown alerting items
function ModularActivity:DoAlertCreations()
	--Do various alert creation things 
	for _, tab in pairs(self.HumanTable) do
		for __, v in pairs(tab) do
			local item = v.actor.EquippedItem;
			--Check for throwables
			if item ~= nil then
				--If we have a junk item that's not already in the thrown table and the actor's firing, add it to the thrown table
				if self.JunkAlertTable[item.PresetName] ~= nil and self.AlertItemTable[item.UniqueID] == nil and v.actor:GetController():IsState(Controller.WEAPON_FIRE) then
					self:AddAlertItem(item, false, {strength = 0, parent = nil},  {strength = self.JunkAlertTable[item.PresetName], parent = item});
					
				--If we have a light item that's not already in the thrown table and the actor's firing, add it to the thrown table
				elseif self.LightAlertTable[item.PresetName] ~= nil and self.AlertItemTable[item.UniqueID] == nil and self.AlertTable[item.UniqueID] == nil and (v.actor:GetController():IsState(Controller.WEAPON_FIRE) or (item.Sharpness == 2 and v.actor:GetController():IsState(Controller.WEAPON_DROP))) then
					self:AddAlertItem(item, true, {strength = self.LightAlertTable[item.PresetName], parent = item}, {strength = 0, parent = nil});
					item.Sharpness = 3;
					--ToAttachable(item):Detach();
				
				--If the actor's activity.sound.total is too high, make new noise alert; these alerts are NOT mobile
				elseif v.activity.sound.total >= self.AlertValue and v.activity.sound.current > 0 then
					self:AddAlert(v.actor.Pos, nil, {strength = 0, parent = nil}, {strength = self:GetWeaponAlertStrength(v.activity.sound.current), parent = nil});
					v.activity.sound.total = math.floor(v.activity.sound.total*self.WeaponAlertActivityReductionFactor); --Reduce the actor's sound activity total so we don't keep making alerts
			
				--If the actor's activity.light.total is too high and light is being made and it's not daytime, make new light alert; these alerts ARE mobile
				elseif v.activity.light.total >= self.AlertValue and self.AlertIsDay == false and v.activity.light.current > 0 then
					local lightstrength = v.lightOn and self.FlashlightAlertStrength or self.LightAlertTable[item.PresetName];
					--If the actor doesn't have an alert, make one
					if v.alert == false then
						self:AddAlert(v.actor.Pos, v.actor, {strength = lightstrength, parent = item}, {strength = 0, parent = nil});
						v.alert = self.AlertTable[v.actor.UniqueID];
					--Otherwise, increase or decrease the alert's light.strength until it equals lightstrength
					elseif v.alert ~= false and v.alert.light.strength ~= lightstrength then
						local speed = 100;
						if v.alert.light.strength > lightstrength + 2*speed then
							v.alert.light.strength = v.alert.light.strength - speed;
						elseif v.alert.light.strength < lightstrength - 2*speed then
							v.alert.light.strength = v.alert.light.strength + speed;
						elseif v.alert.light.strength <= lightstrength + 2*speed and v.alert.light.strength >= lightstrength - 2*speed then
							v.alert.lightstrength = lightstrength
						end
						self:SetAlertStrength(v.alert);
					end
					v.activity.light.total = v.activity.light.total - 1; --Lower the actor's total light activity by 1 so it doesn't cause false flags
				end
			end
		end
	end
end
--Count down all alerts, merge alerts that are close to each other
function ModularActivity:ManageAlertPoints()
	--General update loop
	for k, v in pairs(self.AlertTable) do
		--Reset lifetimer on emitting items so the alert won't expire and have its strength set to 0
		for _, atype in pairs(self.AlertTypes) do
			if MovableMan:ValidMO(v[atype].parent) then
				v[atype].timer:Reset();
				--print ("Resetting "..tostring(atype).." timer on alert "..tostring(k).." at pos "..tostring(v.pos).." because parent is still alive");
			end
		end
	
		--Merge nearby alerts
		--[[for k2, v2 in pairs(self.AlertTable) do --TODO alert merge range should depend on the number of alerts in total, more alerts means bigger range
			if k ~= k2 and self:AlertsHaveSameTarget(v, v2) and SceneMan:ShortestDistance(v.pos, v2.pos, false).Magnitude < 100 then
				self:MergeAlerts(v, v2, k2);
			end
		end--]]
		
		--If the alert doesn't have zombies and its alert's zombie respawn timer is ready, add them until 
		--Note that cleaning the alert's zombie table is done in utilities, as it is handled when the zombie dies and is removed from the table
		if self.IncludeSpawns and self:AlertIsMissingZombies(v) and v.zombie.timer:IsPastSimMS(self:GetZombieRespawnIntervalForAlert(alert)) then
			local curzombienum = 0; --Used to hold the current number of zombies this alert has
			for _, __ in pairs(v.zombie.actors) do
				curzombienum = curzombienum+1;
			end
			print ("check for alert spawning zombies, alert currently has "..tostring(curzombienum).." out of "..tostring(self:GetNumberOfZombiesForAlert(v)).." zombies");
			--If the alert doesn't have its full set of zombies, add them in
			if self:GetNumberOfZombiesForAlert(v) - curzombienum > 0 then
				for i = 1, self:GetNumberOfZombiesForAlert(v) - curzombienum do
					local zombieactor = self:AlertsRequestSpawns_SpawnAlertZombie(v, self:GetZombieSpawnDistanceOffsetForAlert(v));
					if zombieactor == false then
						v.zombie = false;
					else
						v.zombie.actors[zombieactor.UniqueID] = zombieactor;
					end
				end
			end
			if v.zombie ~= false then
				v.zombie.timer:Reset();
			end
		--If there are no missing zombies for the alert, keep the timer at 0
		elseif self.IncludeSpawns and not self:AlertIsMissingZombies(v) and v.zombie ~= false then
			v.zombie.timer:Reset();
		end
	end
end
--Add objective points for alert positions
function ModularActivity:MakeAlertArrows()
	for _, players in pairs(self.HumanTable.Players) do
		for __, alert in pairs(self.AlertTable) do
			--Only add the points if the player is closer than the alert's strength divided by the awareness constant
			if SceneMan:ShortestDistance(alert.pos, players.actor.Pos, false).Magnitude <  self:AlertVisibilityDistance(alert.strength) then
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
				self:AddObjectivePoint(st.." Alert", pos, self.PlayerTeam, GameActivity.ARROWDOWN);
				--self:AddObjectivePoint(st.." Alert\nStrength: "..tostring(math.ceil(alert.strength/1000)).."\nPos: "..tostring(alert.pos).."\nBase Pull Distance: "..tostring(self:AlertVisibilityDistance(alert.strength)).."\nTarget: "..tostring(alert.target)..(alert.light.parent == nil and "" or ("\nLight Parent: "..tostring(alert.light.parent)))..(alert.sound.parent == nil and "" or ("\nSound Parent: "..tostring(alert.sound.parent))), pos, self.PlayerTeam, GameActivity.ARROWDOWN);
			end
		end
	end
end