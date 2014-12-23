-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------
function Chernarus:StartActivity()
	--Remove the starting GO banner
	for i = 0, 3 do
		local banner = self:GetBanner(GUIBanner.YELLOW, i):HideText(-1,-1);
	end

	--------------------
	--GLOBAL VARIABLES--
	--------------------
	--Global DayZ Human Wound Table, reset/created on mission start just in case
	DayZHumanWoundTable = {};
	
	----------------------
	--START OF CONSTANTS--
	----------------------
	self.NumberOfLootAreas = 58; --The number of loot areas, must be updated to match the number of such areas defined in the scene
	self.NumberOfLootZombieSpawnAreas = 26; --The number of spawn areas for loot zombies, must be updated to match the number of such areas defined in the scene
	self.ZombieAlertDistance = 300; --The distance a target needs to be within of a zombie for it to stop wandering and move at the target
	self.NumberOfShelterAreas = 20; --The number of shelter areas, places players and NPCs can use to avoid getting sickness due to bad weather
	self.NumberOfAudioCivilizationAreas = 5; --The number of civilization areas where civilization localized audio will play instead of nature audio
	self.NumberOfAudioBeachAreas = 2; --The number of beach areas where beach localized audio will play instead of generic nature audio

	---------
	--AREAS--
	---------
	self.ChernarusUniqueArea = SceneMan.Scene:GetArea("Chernarus Unique Area");
	
	------------------
	--DYNAMIC TABLES--
	------------------
	--A table of humans, key is actor.UniqueId
	--Keys - Values 
	--actor, alert - whether or not they have an alert on them and if so the alert, lightOn - whether their flashlight is on or off,
	--rounds - the number of rounds left in their gun if they have one (USED FOR ALERTS),
	--activity - {sound - {current - current sound addition value, total - total sound level, timer - a timer for lowering their sound level}
	--			  light - {current - current light addition value, total - total light level, timer - a timer for lowering their light level}}
	self.HumanTable = {
		Players = {},
		NPCs = {}
	};
	--A table of all zombies, key is actor.UniqueId
	--Keys-Values
	--actor,
	--target - {val - the zombie's actor or position target, ttype - the target type (actor or alert or pos),
	--			startdist - the starting dist to the target, dynamically decreased and used to determine when to remove the zombie's actor target}
	self.ZombieTable = {};
	
	---------------
	--OTHER STUFF--
	---------------
	--Limit of MOIDs allowed in the activity
	self.MOIDLimit = 175;

	self:SetTeamFunds(0 , 0);

	--Teams
	self.PlayerTeam = Activity.TEAM_1;
	self.NPCTeam = Activity.TEAM_2;
   	self.ZombieTeam = -1;
	
	--Lag Timers
	self.GeneralLagTimer = Timer();
	
	--------------------
	--MODULE INCLUSION--
	--------------------
	self.IncludeLoot = true;
	self.IncludeSustenance = true;
	self.IncludeSpawns = true;
	self.IncludeDayNight = true;
	self.IncludeFlashlight = true;
	self.IncludeIcons = true;
	self.IncludeBehaviours = true; --Note: Behaviours requires spawns, this is enforced automatically
	self.IncludeAudio = true;
	self.IncludeAlerts = true;
	--v DO NOT TOUCH FOR MODULE CHANGES v--
	self:DoModuleEnforcement();
	self:DoModuleInclusion();
	--^ DO NOT TOUCH FOR MODULE CHANGES ^--
	
	-------------------
	--STARTING ACTORS--
	-------------------
	--Add starting actors
	self:AddStartingActors();
end
-----------------------------------------------------------------------------------------
-- Module Stuff
-----------------------------------------------------------------------------------------
--Enforce any module constraints
function Chernarus:DoModuleEnforcement()
	self.IncludeBehaviours = self.IncludeSpawns and self.IncludeBehaviours;
end
--Include modules we want
function Chernarus:DoModuleInclusion()
	dofile("DayZ.rte/Activities/Module Scripts/Communication Module.lua"); --Communication always included
	if self.IncludeLoot then
		dofile("DayZ.rte/Activities/Module Scripts/Loot Spawn Module.lua");
	end
	if self.IncludeSustenance then
		dofile("DayZ.rte/Activities/Module Scripts/Sustenance Module.lua");
	end
	if self.IncludeSpawns then
		dofile("DayZ.rte/Activities/Module Scripts/Spawns Module.lua");
	end
	if self.IncludeDayNight then
		dofile("DayZ.rte/Activities/Module Scripts/DayNight Module.lua");
	end
	if self.IncludeFlashlight then
		dofile("DayZ.rte/Activities/Module Scripts/Flashlight Module.lua");
	end
	if self.IncludeIcons then
		dofile("DayZ.rte/Activities/Module Scripts/Icons Module.lua");
	end
	if self.IncludeBehaviours and self.IncludeSpawns then --Behaviours requires spawns
		dofile("DayZ.rte/Activities/Module Scripts/Behaviours Module.lua");
	end
	if self.IncludeAudio then
		dofile("DayZ.rte/Activities/Module Scripts/Audio Module.lua");
	end
	if self.IncludeAlerts then
		dofile("DayZ.rte/Activities/Module Scripts/Alerts Module.lua");
	end
	self:DoModuleInitialization();
end
--Initialize the included modules
function Chernarus:DoModuleInitialization()
	if self.IncludeLoot then
		self:StartLoot();
	end
	if self.IncludeSustenance then
		self:StartSustenance();
	end
	if self.IncludeSpawns then
		self:StartSpawns();
	end
	if self.IncludeDayNight then
		self:StartDayNight();
	end
	if self.IncludeFlashlight then
		self:StartFlashlight(); --Doesn't actually do anything
	end
	if self.IncludeIcons then
		self:StartIcons();
	end
	if self.IncludeBehaviours and self.IncludeSpawns then --Behaviours requires spawns
		self:StartBehaviours();
	end
	if self.IncludeAudio then
		self:StartAudio();
	end
	if self.IncludeFlashlight then
		self:StartFlashlight();
	end
	if self.IncludeAlerts then
		self:StartAlerts();
		self:DayNightNotifyMany_DayNightCycle(); --Notify alerts so they know the time of day
	end
end
-----------------------------------------------------------------------------------------
-- Add Starting Actors
-----------------------------------------------------------------------------------------
function Chernarus:AddStartingActors()
	--The player actors
	for i = 0 , self.PlayerCount do
		if self:PlayerHuman(i) then
			local player = CreateAHuman("Survivor Black Reticle Actor" , "DayZ.rte");
			player:AddInventoryItem(CreateHDFirearm("[DZ] .45 Revolver" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , "DayZ.rte"));
			player:AddInventoryItem(CreateHDFirearm("Baked Beans" , "DayZ.rte"));
			player:AddInventoryItem(CreateHDFirearm("Coke" , "DayZ.rte"));
			if self.IncludeFlashlight then
				player:AddInventoryItem(CreateHDFirearm("Flashlight" , "DayZ.rte"));
			end
			player:AddInventoryItem(CreateTDExplosive("Flare" , "DayZ.rte"));
			player.Sharpness = 0;
			player.Pos = Vector(2250, 300)--(350, 550);
			player.Team = self.PlayerTeam;
			player.AIMode = Actor.AIMODE_SENTRY;
			player.HUDVisible = false
			MovableMan:AddActor(player);
			--self:SetPlayerBrain(player, self.PlayerTeam);
			self:AddToPlayerTable(player);
		end
	end
	--TODO Test NPC, Remove Me!
	--[[self.TestNPC = CreateAHuman("Survivor Black" , "DayZ.rte");
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Hatchet" , "DayZ.rte"));
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Baked Beans" , "DayZ.rte"));
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Coke" , "DayZ.rte"));
	self.TestNPC:AddInventoryItem(CreateTDExplosive("M67" , "DayZ.rte"));
	self.TestNPC.Pos = Vector(1250, 400);
	self.TestNPC.Team = self.PlayerTeam;
	self.TestNPC.AIMode = Actor.AIMODE_SENTRY;
	MovableMan:AddActor(self.TestNPC);
	self.NPCTable[#self.NPCTable+1] = {self.TestNPC, 0, 0}--]]
end
-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------
-- This function is called when mission is paused
function Chernarus:PauseActivity(pause)
	print("PAUSE! -- Chernarus:PauseActivity()!");
end
-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------
-- This function is called after mission has ended
function Chernarus:EndActivity()
	DayZHumanWoundTable = nil;
	if self.IncludeAudio then
		AudioMan.MusicVolume = self.AudioGlobalMaxVolume;
	end
	print("END! -- Chernarus:EndActivity()!");
end
-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------
function Chernarus:UpdateActivity()
	self:ClearObjectivePoints();
	---------------------
	--TODO TESTING KEYS--
	---------------------
	if true then
	if UInputMan:KeyPressed(3) then --Reset all
		for k, v in pairs (self.ZombieTable) do
			v.actor.ToDelete = true;
		end
		for k, v in pairs(self.HumanTable) do
			for k2, v2 in pairs(v) do
				v2.actor.ToDelete = true;
			end
		end
		for item in MovableMan.Items do
			item.ToDelete = true;
		end
		for actor in MovableMan.Actors do
			actor.ToDelete = true;
		end
		for particle in MovableMan.Particles do
			particle.ToDelete = true;
		end
		PresetMan:ReloadAllScripts();
		print ("SCRIPTS RELOADED");
		self:StartActivity();
	end
	if UInputMan:KeyPressed(2) then
		for k, v in pairs (self.HumanTable.Players) do
			ToHeldDevice(v.actor.EquippedItem):Activate();
		end
	end
	if UInputMan:KeyPressed(26) then --Print some stuff
		local count = 0;
		for k, v in pairs (self.ZombieTable) do
			count = count + #v;
		end
		print ("Zombies: "..tostring(count));
		for k, v in pairs (self.LootTable) do
			count = count + #v;
		end
		print ("Loot: "..tostring(count));
		print ("Wounds: "..tostring(#DayZHumanWoundTable));
		if self.IncludeAlerts then
			count = 0;
			for k, v in pairs(self.AlertTable) do
				count = count + 1;
			end
			print ("Alerts: "..tostring(count));
		end
	end
	if UInputMan:KeyPressed(24) then --Turn on and off flashlight
		for k, v in pairs (self.HumanTable.Players) do
			if v.actor.Sharpness == 0 then
				v.actor.Sharpness = 1;
			else
				v.actor.Sharpness = 0;
			end
		end
	end
	end
	---------------------
	--TODO TESTING KEYS--
	---------------------
	
	--Clean tables, must be done first as it's important to prevent crashes
	self:DoActorChecksAndCleanup();
	
	--Deal with food and drink, called every frame for dynamic decreasing by actions
	if self.IncludeSustenance then
		self:DoSustenance();
	end
	
	--Deal with icons, called every frame so they don't lag behind in their position
	if self.IncludeIcons then
		self:DoIcons();
	end
	
	--Deal with the day/night cycle and alerts for it
	if self.IncludeDayNight then
		self:DoDayNight();
	end
	
	--Deal with ambient audio 
	if self.IncludeAudio then
		self:DoAudio();
	end
	
	--Deal with flashlights
	if self.IncludeFlashlight then
		self:DoFlashlights();
	end
	
	--Deal with alert stuff, delays for delagging are done internally
	if self.IncludeAlerts then
		self:DoAlerts();
	end
	
	if self.GeneralLagTimer:IsPastSimMS(100) then
		
		--Deal with zombie and NPC spawns
		if self.IncludeSpawns then
			self:DoSpawns();
		end
		
		--Deal with zombie and NPC behaviours
		if self.IncludeBehaviours then
			self:DoBehaviours();
		end
		
		--Deal with loot actions
		if self.IncludeLoot then
			self:DoLoot();
		end
			
		self.GeneralLagTimer:Reset();
	end
		
	self:YSortObjectivePoints();
end
-----------------------------------------------------------------------------------------
-- Check through all tables for things to remove. Done first
-----------------------------------------------------------------------------------------
function Chernarus:DoActorChecksAndCleanup()
	for _, humantable in pairs(self.HumanTable) do
		for k, v in pairs(humantable) do
			if v.actor.Health <= 0 or not MovableMan:IsActor(v.actor) or v.actor.ToDelete == true then
				self:NotifySust_DeadPlayer(k);
				self:NotifyIcons_DeadPlayer(k);
				self:NotifyAlerts_DeadHuman(v.alert);
				humantable[k] = nil;
			else
				--Reset the actor's round count if he changes weapons in any way
				local c = v.actor:GetController();
				if c:IsState(Controller.WEAPON_DROP) or c:IsState(Controller.WEAPON_PICKUP) or c:IsState(Controller.WEAPON_CHANGE_PREV) or c:IsState(Controller.WEAPON_CHANGE_NEXT) then
					v.rounds = 0;
				end
			end
		end
	end
	for k, v in pairs(self.ZombieTable) do
		if not MovableMan:IsActor(v.actor) then
			print ("Removing dead zombie from table in Main Script");
			self.ZombieTable[k] = nil;
		end
	end
end
-----------------------------------------------------------------------------------------
-- Sort maxdist and mindist inputs so they parse correctly even if the order is mixed up
-----------------------------------------------------------------------------------------
function Chernarus:SortMaxAndMinArguments(dists)
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
-- Find the nearest human to a point TODO move this to spawn??? Make human and zombie management modules???
-----------------------------------------------------------------------------------------
function Chernarus:NearestHuman(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
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
function Chernarus:CheckForNearbyHumans(pos, ...) --Optional args: [1] - Minimum distance, [2] - Maximum distance
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
-- Functions for adding actors to mission tables, for convenient updating
-----------------------------------------------------------------------------------------
function Chernarus:AddToPlayerTable(actor)
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
function Chernarus:AddToNPCTable(actor)
	self.HumanTable.NPCs[actor.UniqueID] = {
		actor = actor, lightOn = false, alert = false, rounds = 0,
		activity = {
			sound = {current = 0, total = 0, timer = Timer()},
			light = {current = 0, total = 0, timer = Timer()},
		}
	};
	self:RequestSustenance_AddToSustenanceTable(actor);
end
function Chernarus:AddToZombieTable(actor, target, targettype, startdist)
	self.ZombieTable[actor.UniqueID] = {actor = actor, target = {val = target, ttype = targettype, startdist = startdist}};
end