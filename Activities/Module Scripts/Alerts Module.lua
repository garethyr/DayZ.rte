-----------------------------------------------------------------------------------------
-- Stuff for alerting zombies and NPCs
-----------------------------------------------------------------------------------------
function Chernarus:StartAlerts()
	-------------------
	--ALERT CONSTANTS--
	-------------------
	--The alert value at which to change activity to alerts
	self.AlertValue = 5000; -- default 10000
	--The base value for alert lifetimes, in MS, only applies to alerts that aren't being renewed
	self.AlertBaseLifetime = 5000;
	--The base value for alert strengths, technically an arbitrary number but a lot is balanced to it
	self.AlertBaseStrength = 10000;
	--The limit for the strength of alerts (based on the base strength), to avoid ridiculous noise alerts and such
	self.AlertStrengthLimit = 50000;
	--The number of MS to wait after an actor shoots to start lowering his total activity
	self.ActorActivityRemoveTime = 5000; -- default 5000
	--The rate at which activity is removed from actors, removed every MS
	self.ActorActivityRemoveSpeed = 10;
	--The number to divide the alert strength by when determining if actors are close enough to react. Greater number means less reactive.
	self.AlertAwareness = 10;
	--Not a very intuitive number, the vector magnitude difference at which actors will target alerts over other actors for spawning, etc. So a bigger number will mean they give more priority to alerts.
	--	If the number is big enough, they'll care more about alerts than actors, etc.
	self.AlertPriorityFactor = 50;
	--The amount of time it takes for alert zombies to respawn.
	self.AlertZombieSpawnInterval = self:AlertsRequestSpawns_GetZombieSpawnInterval()/3;
	--The default alert value for junk items when they hit the ground, each item can have a different value
	self.JunkNoise = self.AlertValue*0.5;
	--The alert value for flashlights, not relevant if they're not included
	self.FlashlightAlertStrength = self.AlertValue*.1; -- default NOT *.1
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
	self.LightAlertTable = {["Red Chemlight"] = self.AlertValue, ["Green Chemlight"] = self.AlertValue, ["Blue Chemlight"] = self.AlertValue, ["Flare"] = self.AlertValue*1.5};
	
	--This table stores all types of alerts and is used around the script for ease. If any alert types are added they should be updated here as well
	self.AlertTypes = {"sound", "light"};
	
	--Weapon sound values ordered from lowest (None) to highest (Very Very High), hunting knife with 0 sound is outside of this table
	self.WeaponAlertValues = {N=100, VVL=250, VL=500, L=1000, LM=1650, M=2250, MH=3250, H=4500, VH=6000, VVH=10000}; -- default 10, 25, 50, 100, 150, 200, 250, 300, 350, 500
	self.WeaponAlertTable = { --Note: weapons aren't separated by civilian/military for alerts since there's no need for that distinction here
		--Civilian weapon alert values (crowbar & hatchet default = self.WeaponAlertValues.N)
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
	--alertZombie = {actor = the alert zombie on it if there is one, timer = the timer for respawning the alert zombie, counts down from when it dies}
	self.AlertTable = {};
	
	--A table of all thrown items that create alert. Key is item.UniqueID. Cuts down on lag
	--Items will turn into alerts if their sharpness is 1.
	--Keys - Values
	--item = the item, ismobile = a flag for whether or not this will be a mobile alert (i.e. one with a target),
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
function Chernarus:AddAlert(pos, target, light, sound)
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
		zombie = {actor = false, timer = Timer()}
	};
	--Set the target's alert in the human table
	if target ~= nil then
		for _, humantable in pairs(self.HumanTable) do
			if humantable[target.UniqueID] ~= nil then
				humantable[target.UniqueID].alert = alert;
				break;
			end
		end
	end
end
--Add a thrown item based on parameter values
function Chernarus:AddAlertItem(item, ismobile, light, sound)
	print ("ADD "..(ismobile and "MOBILE" or "").." THROWN ITEM (Key: "..tostring(item.UniqueID)..") - "..item.PresetName..", light: "..tostring(light.strength)..", sound: "..tostring(sound.strength));
	self.AlertItemTable[item.UniqueID] = {item = item, ismobile = ismobile, light = light, sound = sound};
end
---------------------
--UTILITY FUNCTIONS--
---------------------
--Merge two alerts and remove the second (fromalert), does not check if the alerts are be mergeable
function Chernarus:MergeAlerts(toalert, fromalert, fromindex)
	print ("MERGING ALERT AT "..tostring(fromalert.pos).." INTO ALERT AT "..tostring(toalert.pos));
	--Do light merging, only necessary if the alert we merge from has light
	if fromalert.light.strength > 0 then
		toalert.light.parent = fromalert.light.parent --If both alerts are nil this will stay nil, otherwise the alert's parent will be the current light item
		toalert.light.timer:Reset();
		--If the alert has no target, make its strength the maximum of the strengths, otherwise strength will change over time from DoAlertCreations function
		if toalert.target == nil then
			toalert.light.strength = math.max(toalert.light.strength, fromalert.light.strength);
		end
	end
	--Do sound merging, only necessary if the alert we merge from has sound
	if fromalert.sound.strength > 0 then
		toalert.sound.parent = fromalert.sound.parent --If both alerts are nil this will stay nil, otherwise the alert's parent will be the current sound item
		toalert.sound.timer:Reset();
		--If the alert has no target, make its strength the maximum of the strengths, otherwise strength will change over time from DoAlertCreations function
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
function Chernarus:AlertsHaveSameTarget(alert1, alert2)
	return (alert1.target == nil and alert2.target == nil) or (alert1.target ~= nil and alert2.target ~= nil and alert1.target.UniqueID == alert2.target.UniqueID)
end
--Safely update the total strength of an alert
function Chernarus:SetAlertStrength(alert)
	alert.strength = self:GetAlertStrength(alert.light.strength, alert.sound.strength);
end
--Return the safe total strength given input light and sound strength
function Chernarus:GetAlertStrength(lstr, sstr)
	return math.max(lstr, sstr);
end
--Return the safe strength for a weapon alert given the weapon's sound level
function Chernarus:GetWeaponAlertStrength(soundlevel)
	return math.min(self.AlertStrengthLimit, self.AlertValue*soundlevel/self.WeaponAlertValues[self.WeaponAlertStrengthComparator]);
end

function Chernarus:AlertVisibilityDistance(alertstrength)
	return alertstrength/self.AlertAwareness;
end
--TODO make this also take a maxdist so alerts can trigger things like zombie spawns by being visible within the max spawndist???
--Return true if there are any visible alerts more than mindist away from the visible position, based on awarenessmod*self:AlertDistance
function Chernarus:CheckForVisibleAlerts(pos, awarenessmod, mindist)
	local dist, maxdist, visdist;
	mindist, maxdist = self:SortMaxAndMinArguments({mindist, maxdist});
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, true).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			return true;
		end
	end
	return false;
end
function Chernarus:NearestVisibleAlert(pos, awarenessmod, mindist)
	local dist, maxdist, visdist, target = nil;
	mindist, maxdist = self:SortMaxAndMinArguments({mindist, maxdist});
	
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
function Chernarus:VisibleAlerts(pos, awarenessmod, mindist)
	local dist, maxdist, visdist, alerts = {};
	mindist, maxdist = self:SortMaxAndMinArguments({mindist, maxdist});
	
	for _, alert in pairs(self.AlertTable) do
		dist = SceneMan:ShortestDistance(pos, alert.pos, true).Magnitude;
		visdist = self:AlertVisibilityDistance(alert.strength)*awarenessmod; --The maximum visibility distance for the alert
		if dist >= mindist and dist <= maxdist and dist <= visdist then
			alerts[#alerts+1] = alert;
		end
	end
	return alerts;
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Main alert function, increases sound upon firing, transfers alert to locations, runs everything else
function Chernarus:DoAlerts()
	--Clean the table before doing any alert stuff
	self:DoAlertCleanup();
	
	--Update mobile alert positions
	for _, alert in pairs(self.AlertTable) do
		if alert.target ~= nil and MovableMan:ValidMO(alert.target) then
			alert.pos = Vector(alert.target.Pos.X, alert.target.Pos.Y);
		end
	end
	
	--Add weapon sounds on firing
	self:DoAlertHumanAddActivity();
	
	--Run the general alert making often
	self:DoAlertCreations();
	
	--Deal with converting any thrown items to alerts
	self:ManageAlertItems();
	
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
function Chernarus:DoAlertCleanup()
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
			if v.target ~= nil then
				--Check Players and NPCs
				for _, humantable in pairs(self.HumanTable) do
					if humantable[v.target.UniqueID] ~= nil then
						humantable[v.target.UniqueID].alert = false;
					end
				end
				for _, zombie in pairs(self.ZombieTable) do
					if zombie.targettype == "alert" and zombie.target.val == v then
						zombie.targettype = "pos";
						zombie.target.val = v.pos;
					end
				end
			end
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
function Chernarus:MoveAlertFromDeadActor(alert)
	alert.target = nil;
	print("MOVE ALERT FROM DEAD ACTOR");
end
--Set alerts for actors whose activity timers have reset to be static and, if necessary, switch their type
function Chernarus:RemoveNonActiveActorAlert(alert, atype, actorID, actortype)
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
function Chernarus:RemoveDeadHeldAlertItem(item, atype, actor)
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
function Chernarus:DoAlertHumanAddActivity()
	for humankey, tab in pairs(self.HumanTable) do
		for __, v in pairs(tab) do
			local acttype = self:DoAlertHumanCheckCurrentActivity(v); --Check and update the actor's current activity levels
			if acttype ~= false then
				local item = ToHeldDevice(v.actor.EquippedItem);
				--Add to the relevant activity type's total value (as long as it's not at the limit) and reset its calm down timer
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
function Chernarus:DoAlertHumanCheckCurrentActivity(tab)
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
function Chernarus:DoAlertCreations()
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
--Do all management for thrown items to turn them into alerts
function Chernarus:ManageAlertItems()
	for k, v in pairs(self.AlertItemTable) do
		--If the item is turned on and should add an alert(set in the item's script)
		if v.item.Sharpness > 0 then
		print (v.ismobile);
			self:AddAlert(v.item.Pos, (v.ismobile and v.item or nil), (v.ismobile and v.light or {strength = v.light.strength, parent = nil}), (v.ismobile and v.sound or {strength = v.sound.strength, parent = nil}));
			--Notify day/night about the item if it's got light strength
			if v.light.strength > 0 then
				self:AlertsNotifyDayNight_LightEmittingItemAdded(v.item);
			end
			self.AlertItemTable[k] = nil;
		end
	end
end
--Count down all alerts, merge alerts that are close to each other
function Chernarus:ManageAlertPoints()
	--General update loop
	for k, v in pairs(self.AlertTable) do
		--Reset lifetimer on emitting items
		for _, atype in pairs(self.AlertTypes) do
			if MovableMan:ValidMO(v[atype].parent) then
				v[atype].timer:Reset();
				--print ("Resetting "..tostring(atype).." timer on alert "..tostring(k).." at pos "..tostring(v.pos).." because parent is still alive");
			end
		end
	
		--Merge nearby alerts
		for k2, v2 in pairs(self.AlertTable) do --TODO alert merge range should depend on the number of alerts in total, more alerts means bigger range
			if k ~= k2 and self:AlertsHaveSameTarget(v, v2) and SceneMan:ShortestDistance(v.pos, v2.pos, false).Magnitude < 100 then
				self:MergeAlerts(v, v2, k2);
			end
		end
		
		--If the alert doesn't have a zombie, add one if the alert's zombie timer's ready and there are no humans too nearby
		if self.IncludeSpawns and v.zombie.actor == nil and v.zombie.timer:IsPastSimMS(self.AlertZombieSpawnInterval) then
			if self:CheckForNearbyHumans(v.pos, 100) == false then --TODO remove the magic number
				v.zombie.actor = self:AlertsRequestSpawns_SpawnAlertZombie(v.pos);
				--Note, if spawns isn't included, the request will return false and the alert will never try to add more zombies
			end
		--If the alert has a zombie but it's dead, remove it and reset the alert's spawn timer
		elseif type(v.zombie.actor) == "userdata" and not MovableMan:IsActor(v.zombie.actor) then
			v.zombie.timer:Reset();
			v.zombie.actor = nil
		end
	end			
end				
				
--Add objective points for alert positions
function Chernarus:MakeAlertArrows()
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