-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------
function DayZ:StartActivity()
	--Remove the starting GO banner
	for i = 0, 3 do
		local banner = self:GetBanner(GUIBanner.YELLOW, i):HideText(-1,-1);
	end

	--------------------
	--GLOBAL VARIABLES--
	--------------------
	--Global DayZ Human Wound Table, reset/created on mission start just in case
	DayZHumanWoundTable = {};
	--Global reference to the currently running modular activity, for use in module scripts
	ModularActivity = self;
	
	---------
	--AREAS--
	---------
	local DayZUniqueArea = SceneMan.Scene:GetArea("DayZ Unique Area");
	
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
	--Gold is not allowed or applicable
	self:SetTeamFunds(0 , 0);
	--The rte to spawn things from, set as a variable for easy modification
	self.RTE = "DayZ.rte";
	--Tracker for zombies killed
	self.ZombiesKilled = 0;
	--Tracker for nights survived
	self.NightsSurvived = -1; --Note: This count will be 1 less than it should if the game begins during night instead of day. This can be fixed if we keep these counters forever
	
	--Teams
	self.PlayerTeam = Activity.TEAM_1;
	self.NPCTeam = Activity.TEAM_2;
   	self.ZombieTeam = -1;
	
	--Lag Timers
	self.GeneralLagTimer = Timer();
	
	--------------------
	--MODULE INCLUSION--
	--------------------
	self.ModulePath = "DayZ.rte/Activities/Module Scripts/"; --The path for all modules
	self.ModulesInitialized = false;
	--Note: These determine whether a module can be included at all, the actual inclusions are scene specific but can be overwritten in the relevant function
	self.LootIncludable = true;
	self.SustenanceIncludable = true;
	self.SpawnsIncludable = true;
	self.DayNightIncludable = true;
	self.FlashlightIncludable = true; --Note: Flashlight requires DayNight, this is enforced automatically
	self.IconsIncludable = true;
	self.BehavioursIncludable = true; --Note: Behaviours requires Spawns, this is enforced automatically
	self.AudioIncludable = true;
	self.AlertsIncludable = true;
	
	--v DO NOT TOUCH FOR MODULE CHANGES v--
	self:DoModuleOverwrites();
	self:DoModuleEnforcement();
	self:DoModuleInclusion();
	
	--TODO right now a scene must be loaded before module initialization, replace this call with a proper version
	self:StartNewGame();
	
	
	self:DoModuleInitialization();
	self.ModulesInitialized = true;
	self:AddStartingPlayerActors();
	--^ DO NOT TOUCH FOR MODULE CHANGES ^--
end
-----------------------------------------------------------------------------------------
-- Module Stuff
-----------------------------------------------------------------------------------------
--Overwrite scene specific module inclusions as desired here, still constrained by whether or not the module's includable
function DayZ:DoModuleOverwrites()
	--Example:
	--self.IncludeAlerts = false; -- Don't include alerts regardless of the scene
end
--Enforce any module constraints
function DayZ:DoModuleEnforcement()
	self.IncludeBehaviours = self.IncludeSpawns and self.IncludeBehaviours;
	self.IncludeFlashlight = self.IncludeDayNight and self.IncludeFlashlight;
	
	--Make sure to only include modules that are marked as includable
	self.IncludeLoot = self.LootIncludable and self.IncludeLoot;
	self.IncludeSustenance = self.SustenanceIncludable and self.IncludeSustenance;
	self.IncludeSpawns = self.SpawnsIncludable and self.IncludeSpawns;
	self.IncludeDayNight = self.DayNightIncludable and self.IncludeDayNight;
	self.IncludeFlashlight = self.FlashlightIncludable and self.IncludeFlashlight;
	self.IncludeIcons = self.IconsIncludable and self.IncludeIcons;
	self.IncludeBehaviours = self.BehavioursIncludable and self.IncludeBehaviours;
	self.IncludeAudio = self.AudioIncludable and self.IncludeAudio;
	self.IncludeAlerts = self.AlertsIncludable and self.IncludeAlerts;
end
--Include modules we want
function DayZ:DoModuleInclusion()
	--Required Modules
	dofile(self.ModulePath.."Communication Module.lua"); --Communication always included
	dofile(self.ModulePath.."Util Module.lua"); --Util always included
	dofile(self.ModulePath.."Scene Loading and Transitions Module.lua"); --Scene Loading and Transitions always included
	self:StartSceneLoading();
	dofile(self.ModulePath.."Save Load Module.lua"); --Game Saving and Loading always included
	self:StartSaveLoad();
	
	--Non-Required Modules
	if self.LootIncludable then
		dofile(self.ModulePath.."Loot Spawn Module.lua");
	end
	if self.SustenanceIncludable then
		dofile(self.ModulePath.."Sustenance Module.lua");
	end
	if self.SpawnsIncludable then
		dofile(self.ModulePath.."Spawns Module.lua");
	end
	if self.DayNightIncludable then
		dofile(self.ModulePath.."DayNight Module.lua");
	end
	if self.FlashlightIncludable then
		dofile(self.ModulePath.."Flashlight Module.lua");
	end
	if self.IconsIncludable then
		dofile(self.ModulePath.."Icons Module.lua");
	end
	if self.BehavioursIncludable then
		dofile(self.ModulePath.."Behaviours Module.lua");
	end
	if self.AudioIncludable then
		dofile(self.ModulePath.."Audio Module.lua");
	end
	if self.AlertsIncludable then
		dofile(self.ModulePath.."Alerts Module.lua");
	end
end
--Initialize the included modules
function DayZ:DoModuleInitialization()
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
		self:DayNightNotifyMany_DayNightCycle(); --Notify so everything knows the time of day
	end
	if self.IncludeFlashlight then
		self:StartFlashlight(); --Doesn't actually do anything, placed here for ease
	end
	if self.IncludeIcons then
		self:StartIcons();
	end
	if self.IncludeBehaviours then
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
	end
end
-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------
-- This function is called when mission is paused
function DayZ:PauseActivity(pause)
	print("PAUSE! -- Chernarus:PauseActivity()!");
end
-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------
-- This function is called after mission has ended
function DayZ:EndActivity()
	DayZHumanWoundTable = nil;
	if self.IncludeAudio then
		AudioMan.MusicVolume = self.AudioGlobalMaxVolume;
	end
	print("END! -- Chernarus:EndActivity()!");
end
-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------
function DayZ:UpdateActivity()
	self:ClearObjectivePoints();
	---------------------
	--TODO TESTING KEYS--
	---------------------
	if true then
	if UInputMan:KeyPressed(3) then --Reset all
		SceneMan:LoadScene("DayZ Loader", true);
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
	
	--Run transitions to other scenes
	self:RunTransitions();
	
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
function DayZ:DoActorChecksAndCleanup()
	for _, humantable in pairs(self.HumanTable) do
		for k, v in pairs(humantable) do
			if v.actor.Health <= 0 or not MovableMan:IsActor(v.actor) or v.actor.ToDelete == true then
				print ("Removing dead "..k.." from table in Main Script");
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
			self.ZombiesKilled = self.ZombiesKilled + 1;
		end
	end
end