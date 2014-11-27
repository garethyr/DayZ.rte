-----------------------------------------------------------------------------------------
-- Stuff for alerting zombies and NPCs
-----------------------------------------------------------------------------------------
function Chernarus:StartAlerts()
	-------------------
	--ALERT CONSTANTS--
	-------------------
	--The alert value at which to change activity to alerts
	self.AlertValue = 10000;
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
	--Not a very intuitive number, the vector magnitude difference at which actors will target alerts over other actors for spawning, etc. So a bigger number will mean they give more priority to alerts.
	--	If the number is big enough, they'll care more about alerts than actors, etc.
	self.AlertPriorityFactor = 50;
	--The amount of time it takes for alert zombies to respawn.
	self.AlertZombieSpawnInterval = self.ZombieSpawnInterval/3;
	--The default alert value for junk items when they hit the ground, each item can have a different value
	self.JunkNoise = self.AlertValue*0.5;
	--The alert value for flashlights, not relevant if they're not included
	self.FlashlightAlertStrength = self.AlertValue;
	--A modifier for the light activity increase speed on light use, so they get slowed by some amount for balance. The actual speed is also based on the light's strength
	self.LightActivityGainModifier = 0.02;

	-----------------------
	--STATIC ALERT TABLES--
	-----------------------
	--This table stores all junk items
	self.JunkAlertTable = {["Empty Tin Can"] = self.JunkNoise, ["Empty Whiskey Bottle"] = self.JunkNoise, ["Empty Coke"] = self.JunkNoise, ["Empty Pepsi"] = self.JunkNoise, ["Empty Mountain Dew"] = self.JunkNoise};
	
	--This table stores all light making throwables and their alert values
	self.LightAlertTable = {["Red Chemlight"] = self.AlertValue, ["Green Chemlight"] = self.AlertValue, ["Blue Chemlight"] = self.AlertValue, ["Flare"] = self.AlertValue*1.5};
	
	--Sound Table, for convenience. Ordered from lowest (none) to highest (very very high), hunting knife with 0 sound is outside of this table
	local s = {N=10, VVL=25, VL=50, L=100, LM=150, M=200, MH=250, H=300, VH=350, VVH=400};
	
	--TODO fix balance for weapon sound values, change these tables to be alert specific and use the weapon name as their keys then add loot specific tables like junktable
	
	--Weapons aren't separated by civilian/military for alerts since there's no need for that distinction here
	self.WeaponAlertTable = {
		--Civilian weapon alert values
		["Hunting Knife"] = 0, ["Crowbar"] = s.N, ["Hatchet"] = s.N, ["[DZ] Makarov PM"] = s.LM, ["[DZ] .45 Revolver"] = s.M, ["[DZ] M1911A1"] = s.M, ["[DZ] Compound Crossbow"] = s.N, ["[DZ] MR43"] = s.M, ["[DZ] Winchester 1866"] = s.L, ["[DZ] Lee Enfield"] = s.VH, ["[DZ] CZ 550"] = s.VH,
		--Military weapons and their alert values
		["[DZ] G17"] = s.L, ["[DZ] AKM"] = s.H, ["[DZ] M16A2"] = s.M, ["[DZ] MP5SD6"] = s.N, ["[DZ] M4A1 CCO SD"] = s.VVL, ["[DZ] Mk 48 Mod 0"] = s.H, ["[DZ] M14 AIM"] = s.H, ["[DZ] M107"] = s.VH
	};
	
	--A table for all the display names for alert items
	self.AlertNameTable = {["Red Chemlight"] = "Chemlight", ["Green Chemlight"] = "Chemlight", ["Blue Chemlight"] = "Chemlight", ["Flare"] = "Flare Light"};
	
	------------------------
	--DYNAMIC ALERT TABLES--
	------------------------ --TODO make alert table use the item's unique id as keys???
	--A table of all alerts positions. Used for ai actions and gives objective arrows for the player
	--Keys - Values
	--pos - the position, atype - type; sound or light or mixed or flashlight, name = the display name for the alert,
	--lightstrength, soundstrength - light/sound strength, unused type is set to 0, totalstrength - the alert's total strength (light + sound)
	--target - the actor the alert's on if there is one,
	--alertZombie = {actor - the alert zombie on it if there is one, timer - the timer for respawning the alert zombie, counts down from when it dies}
	self.AlertTable = {};
	
	--A table of all thrown items that create alert, key is item.UniqueID. Cuts down on lag
	--Keys - Values
	--item - the item, atype - type; sound or light or mixed or flashlight, strength - its alert-to-be strength/duration,
	self.ThrownTable = {};
	
	------------------------------------
	--VARIABLES USED FOR NOTIFICATIONS--
	------------------------------------
	self.AlertIsDay = nil;
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an alert based on parameter values or merge with any alerts on this target.
function Chernarus:AddAlert(pos, alerttype, alertname, strength, alerttarget)
	--Get the inputted alert's light and sound strengths for merging or adding
	local lstr = alerttype:find("light") ~= nil and strength*self.AlertBaseStrength/self.AlertValue or 0;
	local sstr = alerttype:find("sound") ~= nil and strength*self.AlertBaseStrength/self.AlertValue or 0;
	
	--If we have any alerts with this actor target, merge this into it
	if alerttarget ~= nil then
		for _, v in pairs(self.AlertTable) do
			if v.target ~= nil and v.target.UniqueID == alerttarget.UniqueID then
				--Trick self:MergeAlert by making a temporary table with correctly named variables and merge it
				local fromalerttable = {atype = alerttype, name=alertname, lightstrength = lstr, soundstrength = sstr}; 
				self:MergeAlerts(v, fromalerttable, nil);
				print ("MERGING TARGETED ALERTS FROM ADD, NEW ALERT IS "..tostring(v.totalstrength)..", "..tostring(v.atype)..", "..tostring(v.name)..", "..tostring(v.target.PresetName));
				return;
			end
		end
	end

	--TODO alert strength is based on inputted strength * base alert strength / value required for an alert to occur... why???
	
	print ("ADD ALERT (KEY: "..tostring(#self.AlertTable+1)..") - "..tostring(pos)..", "..tostring(alerttype)..", "..tostring(self:GetSafeTotalStrength(lstr, sstr)));
	--Add the alert to the table
	self.AlertTable[#self.AlertTable+1] = {
		pos = Vector(pos.X, pos.Y), atype = alerttype, name = alertname, lightstrength = lstr, soundstrength = sstr,
		totalstrength = self:GetSafeTotalStrength(lstr, sstr), target = alerttarget, zombie = {actor = false, timer = Timer()}
	};
	--Set the target's alert in the human table
	if alerttarget ~= nil then
		self:AlertNotifyMain_HumanTargetAlertAdded(self.AlertTable[#self.AlertTable]);
	end
end
--Add a thrown item based on parameter values
function Chernarus:AddThrownItem(thrownitem, alerttype, alertname, strength)
	print ("ADD THROWN ITEM (KEY: "..tostring(thrownitem.UniqueID)..") - "..thrownitem.PresetName..", "..tostring(alerttype)..", "..tostring(strength));
	self.ThrownTable[thrownitem.UniqueID] = {item = thrownitem, atype = alerttype, name = alertname, strength = strength};
end
---------------------
--UTILITY FUNCTIONS--
---------------------
--Return the light alert strength of a light item based on its remaining life
function Chernarus:LightStrength(item)
	return self.LightAlertTable[item.PresetName]*self:LightStrengthModifier(item);
end
--Return the light item lifetime modifier for light alert strength
function Chernarus:LightStrengthModifier(item)
	return (item.Lifetime - item.Age)/item.Lifetime;
end
--Merge two alerts and remove the second (fromalert), does not check if the alerts are be mergeable
function Chernarus:MergeAlerts(toalert, fromalert, fromindex)
	print ("MERGING ALERT AT "..tostring(fromalert.pos).." INTO ALERT AT "..tostring(toalert.pos));
	toalert.atype = (toalert.atype == fromalert.atype) and toalert.atype or "mixed";
	toalert.name = (toalert.name == fromalert.name) and toalert.name.."s" or toalert.name.." and "..fromalert.name;
	toalert.lightstrength = math.min(toalert.lightstrength + fromalert.lightstrength, self.AlertStrengthLimit);
	toalert.soundstrength = math.min(toalert.soundstrength + fromalert.soundstrength, self.AlertStrengthLimit);
	self:SetAlertTotalStrength(toalert);
	
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
function Chernarus:SetAlertTotalStrength(alert)
	alert.totalstrength = self:GetSafeTotalStrength(alert.lightstrength, alert.soundstrength);
end
--Return the safe total strength given input light and sound strength
function Chernarus:GetSafeTotalStrength(lstr, sstr)
	return math.min(lstr + sstr, self.AlertStrengthLimit);
end
-------------------
--UPDATE FUNCTION--
-------------------
--Main alert function, increases sound upon firing, transfers alert to locations, runs everything else
function Chernarus:DoAlerts()
	--Clean the table before doing any alert stuff
	self:DoAlertCleanup();
	
	--Update mobile alert positions -- TODO consider making splitting alert table into target and notarget to quicken this
	for _, alert in pairs(self.AlertTable) do
		if alert.target ~= nil then
			alert.pos = alert.target.Pos;
		end
	end
	
	--Add weapon sounds on firing
	self:DoAlertHumanAddActivity();
	
	--Run the general alert making often
	self:DoAlertCreations();
	
	--Deal with converting any thrown items to alerts
	self:ManageThrownItems();
	
	--Run management functions
	if self.AlertLagTimer:IsPastSimMS(100) then
		self:ManageAlertPoints();
		self.AlertLagTimer:Reset();
	end
	
	--Objective arrows are cleared every frame so this must always be run
	self:MakeAlertArrows();
end

--Clean up the alert table for a variety of reasons
function Chernarus:DoAlertCleanup()
	for i, v in pairs(self.AlertTable) do
		local canremove = true;
		
		--Remove alert because no strength left
		if v.lightstrength <= 0 and v.soundstrength <= 0 then
			--If the alert is on an actor, set him to no longer have an alert
			if v.target ~= nil then
				--Check Players and NPCs
				for _, humantable in pairs(self.HumanTable) do
					if humantable[v.target.UniqueID] ~= nil then
						humantable[v.target.UniqueID].hasAlert = false;
					end
				end
			end
			canremove = false;
			--Remove the alert
			self.AlertTable[i] = nil;
			print ("REMOVED ALERT "..tostring(i).." FROM POS "..tostring(v.pos).."; "..tostring(#self.AlertTable).." alerts remain");
		end
		
		--Handle changes in target, dead target, target picked up or dropped
		if canremove and v.target ~= nil then
			if v.target.ClassName == "TDExplosive" then
			
				--Remove alerts for thrown light objects that are picked up, new ones get added to their holder
				if MovableMan:ValidMO(v.target) then
					if v.target.RootID ~= v.target.ID and v.target:IsAttached() then
						print ("ALERT "..tostring(i).." AT POS "..tostring(v.pos).." REMOVED BECAUSE PICKED UP");
						canremove = false;
						self.AlertTable[i] = nil;
					end
				--If the light item is dead, set its alert to nonmobile
				elseif not MovableMan:ValidMO(v.target) or target.ID == 255 then
					canremove = false;
					v.target = nil;
					print ("ALERT "..tostring(i).." AT POS "..tostring(v.pos).." SET TO NON MOBILE");
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
function Chernarus:RemoveNonActiveActorAlert(alert, atype)
	if alert.atype == atype then
		alert.target = nil;
	elseif alert.atype == "mixed" then
		--The only sound alert that can be on actors is gunfire, so if it's mixed just remove that value from it and make a new static sound one there
		alert.atype = (atype == "light") and "sound" or "light";
		
		local name = alert.name; --TODO change this to work properly, if string.find('and'), split on and by checking if left or right contains type, otherwise remove the s from the end of each alert
		
		local str = atype.."strength";
		alert[atype.."strength"] = 0;
		--Add a static alert at the position with the removed strength and type
		self:AddAlert(alert.pos, atype, name, str, nil);
	end
end
--Deal with adding to humans' activity levels
function Chernarus:DoAlertHumanAddActivity()
	for _, tab in pairs(self.HumanTable) do
		for __, v in pairs(tab) do
			--Check the actor's 
			local acttype = self:DoAlertHumanCheckCurrentActivity(v);
			if acttype ~= false then
				local item = ToHeldDevice(v.actor.EquippedItem);
				--Add to the relevant activity type's total value (as long as it's not at the limit) and reset its calm down timer
				if (acttype == "sound" and item:IsActivated() and v.actor:GetController():IsState(Controller.WEAPON_FIRE) and not item:IsReloading()) or acttype == "light" then
					v.activity[acttype].total = math.min(v.activity[acttype].total + v.activity[acttype].current, self.AlertValue);--/(ToHDFirearm(item).FullAuto and ToHDFirearm(item).RateOfFire/1000 or 1), self.AlertValue);
					v.activity[acttype].timer:Reset();
				end
			end
			
			--Lower activity levels rapidly a little while after a period of no relevant activity increase
			for _, activity in pairs(v.activity) do
				if activity.total > 0 and activity.timer:IsPastSimMS(self.ActorAlertRemoveTime) then
					activity.total = math.max(activity.total - self.ActorAlertRemoveSpeed, 0);
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
			tab.activity.light.current = self.LightAlertTable[item.PresetName]*self.LightActivityGainModifier;
			return "light";
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
				--If we have a light item that's not already in the thrown table and the actor's firing, add it to the thrown table
				if self.LightAlertTable[item.PresetName] ~= nil and self.ThrownTable[item.UniqueID] == nil and v.actor:GetController():IsState(Controller.WEAPON_FIRE) then
					self:AddThrownItem(item, "light", self.AlertNameTable[item.PresetName], self:LightStrength(item));
				--If we have a junk item that's not already in the thrown table and the actor's firing, add it to the thrown table
				elseif self.JunkAlertTable[item.PresetName] ~= nil and self.ThrownTable[item.UniqueID] == nil and v.actor:GetController():IsState(Controller.WEAPON_FIRE) then
					self:AddThrownItem(item, "sound", "Clatter", self.JunkAlertTable[item.PresetName]);
				end
			
				--Make new alerts, by definition only one can happen at a time since each requires a different item
				--NOISE ALERT - the actor's activity.sound.total is too high; these alerts are NOT mobile
				if v.activity.sound.total > self.AlertValue and v.activity.sound.current > 0 then
					self:AddAlert(v.actor.Pos, "sound", "Gunfire", v.activity.sound.total, nil);
					v.activity.sound.total = math.floor(v.activity.sound.total*0.5); --Halve the actor's totalAlert level
				--LIGHT ALERT - the actor's activity.light.total is too high, light is being made and it's not daytime; these alerts ARE mobile
		
				elseif v.activity.light.total >= self.AlertValue and self.AlertIsDay == false and v.activity.light.current > 0 then
					local lightstrength = v.lightOn and self.FlashlightAlertStrength or self:LightStrength(item);
					--If the actor doesn't have an alert, make one
					if v.hasAlert == false then
						local lighttypestring = v.lightOn and "Flashlight" or self.AlertNameTable[item.PresetName];
						self:AddAlert(v.actor.Pos, "light", lighttypestring, lightstrength, v.actor);
						print ("adding "..lighttypestring.." alert to actor "..v.actor.PresetName);
					--Otherwise, increase or decrease the alert's lightstrength until it equals lightstrength (doable because sound alerts are always stationary)
					else
						local lighttypestring = v.lightOn and "flashlight" or "light";
						if v.hasAlert.lightstrength > lightstrength + 2*self.AlertWeakenSpeed then
							v.hasAlert.lightstrength = v.hasAlert.lightstrength - self.AlertWeakenSpeed;
						elseif v.hasAlert.lightstrength < lightstrength - 2*self.AlertWeakenSpeed then
							v.hasAlert.lightstrength = v.hasAlert.lightstrength + self.AlertWeakenSpeed;
						elseif v.hasAlert.lightstrength <= lightstrength + 2*self.AlertWeakenSpeed and v.hasAlert.lightstrength >= lightstrength - 2*self.AlertWeakenSpeed and v.hasAlert.lightstrength ~= lightstrength then
							v.hasAlert.lightstrength = lightstrength
						end
						self:SetAlertTotalStrength(v.hasAlert);
					end
					v.activity.light.total = v.activity.light.total - 1; --Lower the actor's total light activity by 1 so it doesn't cause false flags
				end
			end
		end
	end
end
--Do all management for thrown items to turn them into alerts
function Chernarus:ManageThrownItems()
	for k, v in pairs(self.ThrownTable) do
		--JUNK ITEMS - ONLY SOUND
		--If it's a junk item (only junk items only make sound), it'll be stationary
		if v.atype == "sound" then
			--If it's low enough or dead, remove and add it to the alert table
			if v.item.Sharpness == 1 then--or not MovableMan:ValidMO(v.item) then
				self:AddAlert(v.item.Pos, v.atype, v.name, v.strength, nil);
				self.ThrownTable[k] = nil;
			end
		--NOT JUNK ITEMS - NOT ONLY SOUND
		--If it's not junk, it'll make light or mixed and won't be stationary
		elseif v.atype == "light" or v.atype == "mixed" then
			--If the item is turned on (i.e. thrown)
			if v.item.Sharpness == 1 then
				self:AlertNotifyDayNight_LightEmittingItemAdded(v.item);
				--If it's not light during daytime remove and add it to the alert table
				if self.AlertIsDay ~= true or v.atype ~= "light" then
					self:AddAlert(v.item.Pos, v.atype, v.name, v.strength, v.item);
					self.ThrownTable[k] = nil;
				else
					print (tostring(self.AlertIsDay).." Annnddd "..tostring(v.atype));
				end
			end
		end
	end
end
--Count down all alerts, merge alerts that are close to each other
function Chernarus:ManageAlertPoints()
	--General update loop
	for k, v in pairs(self.AlertTable) do
		--Merge nearby alerts
		for k2, v2 in pairs(self.AlertTable) do --TODO alert merge range should depend on the number of alerts in total, more alerts means bigger range
			if k ~= k2 and self:AlertsHaveSameTarget(v, v2) and SceneMan:ShortestDistance(v.pos, v2.pos, false).Magnitude < 100 then
				self:MergeAlerts(v, v2, k2);
			end
		end
		
		--Lower the strength values for all alerts, done after merging
		if v.totalstrength > 0 then
			v.lightstrength = math.max(v.lightstrength - self.AlertWeakenSpeed, 0);
			v.soundstrength = math.max(v.soundstrength - self.AlertWeakenSpeed, 0);
			self:SetAlertTotalStrength(v);
		end
		
		--If the alert doesn't have a zombie, add one if the alert's zombie timer's ready and there are no humans too nearby
		if v.zombie.actor == nil and v.zombie.timer:IsPastSimMS(self.AlertZombieSpawnInterval) then
			if self:AlertRequestMain_AnyNearbyHumans(v.pos) == false then
				v.zombie.actor = self:AlertRequestSpawnsAndBehaviours_SpawnAlertZombie(v.pos);
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
			if SceneMan:ShortestDistance(alert.pos, players.actor.Pos, false).Magnitude < alert.totalstrength/(self.AlertAwareness) then
				--Modify alert's location and change the displayed text if it's mobile
				local pos = alert.pos;
				local st = "";
				if alert.target ~= nil then
					pos = alert.target.AboveHUDPos - Vector(0, 100);
					st = "Mobile ";
				end
				--Set the displayed objective 
				local strings = {sound = "Sound ", light = "Light ", mixed = "Light And Sound ", flashlight = "Flashlight "};
				local str = strings[alert.atype];
				--Add the objective point
				self:AddObjectivePoint(st..str.."Alert\nStrength: "..math.ceil(alert.totalstrength/1000), pos, self.PlayerTeam, GameActivity.ARROWDOWN);
			end
		end
	end
end