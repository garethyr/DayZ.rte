-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------
function DayZ:StartActivity()
	--Remove the starting GO banner
	for i = 0, 3 do
		self:GetBanner(GUIBanner.YELLOW, i):HideText(-1,-1);
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
	--actor, player - the human player controlling the actor; -1 for NPCs, lightOn - whether their flashlight is on or off,
	--alert - false if they have no alert on them, or the alert they have on them, rounds - the number of rounds left in their gun if they have one (USED FOR ALERTS),
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
	self.MOIDLimit = 300;
	--Gold is not allowed or applicable
	self:SetTeamFunds(0 , 0);
	--The rte to spawn things from, set as a variable for easy modification
	self.RTE = "DayZ.rte";
	--Whether or not to check for wrapping when calling ShortestDistance, changes based on the current scene
	self.Wrap = nil;
	--Tracker for zombies killed
	self.ZombiesKilled = 0;
	--Tracker for nights survived
	self.NightsSurvived = -1; --Note: This count will be 1 less than it should if the game begins during night instead of day. This can be fixed if we keep these counters forever
	
	--Values for transitioning requirements --TODO probably move this somewhere in future
	self.HasBoat = false;
	self.InHelicopter = false;
	
	--Screentext for all players
	self.ScreenText = {};
	
	--Teams
	self.PlayerTeam = Activity.TEAM_1;
	self.BanditTeam = Activity.TEAM_2;
	self.MilitaryTeam = Activity.TEAM_3;
	self.UnknownTeam = Activity.TEAM_4;
   	self.ZombieTeam = -1;
	
	--Lag Timer
	self.GeneralLagTimer = Timer();
	
	--Weapon Lists
	self.WeaponList = {
		--Melee weapons
		Melee = {{weapon = "Hunting Knife", ammo = nil}, {weapon = "Crowbar", ammo = nil}, {weapon = "Hatchet", ammo = nil}},
		--Civilian weapons
		Civilian = {{weapon = "[DZ] Makarov PM", ammo = "Makarov PM Magazine"}, {weapon = "[DZ] .45 Revolver", ammo = ".45 ACP Speedloader"}, {weapon = "[DZ] M1911A1", ammo = "M1911A1 Magazine"}, {weapon = "[DZ] Compound Crossbow", ammo = "Metal Bolts"}, {weapon = "[DZ] MR43", ammo = "12 Gauge Buckshot (2)"}, {weapon = "[DZ] Winchester 1866", ammo = ".44 Henry Rounds"}, {weapon = "[DZ] Lee Enfield", ammo = "Lee Enfield Stripper Clip"}, {weapon = "[DZ] CZ 550", ammo = "9.3x62 Mauser Rounds"}},
		--Military weapons
		Military = {{weapon = "[DZ] G17", ammo = "G17 Magazine"}, {weapon = "[DZ] AKM", ammo = "AKM Magazine"}, {weapon = "[DZ] M16A2", ammo = "STANAG Magazine"}, {weapon = "[DZ] M4A1 CCO SD", ammo =  "STANAG SD Magazine"}, {weapon = "[DZ] MP5SD6", ammo = "MP5SD6 Magazine"}, {weapon = "[DZ] Mk 48 Mod 0", ammo = "M240 Belt"}, {weapon = "[DZ] M14 AIM", ammo = "DMR Magazine"}, {weapon = "[DZ] M107", ammo = "M107 Magazine"}}
	};
	
	--------------------
	--MODULE INCLUSION--
	--------------------
	self.ModulePath = "DayZ.rte/Activities/Module Scripts/"; --The path for all modules
	
	--Note: These determine whether a module can be included at all
	--		The actual inclusions are scene specific but can be overwritten in the Scene Loading and Transitions Module DoModuleOverwrites() function
	self.LootIncludable = true;
	self.SustenanceIncludable = true;
	self.SpawnsIncludable = true;
	self.DayNightIncludable = true;
	self.FlashlightIncludable = true; --Note: Flashlight requires DayNight, this is enforced automatically
	self.IconsIncludable = true;
	self.BehavioursIncludable = true; --Note: Behaviours requires Spawns, this is enforced automatically
	self.AudioIncludable = true;
	self.AlertsIncludable = true;
	self.D = 0;
	
	self:DoCoreModuleInclusionAndInitialization();
	
	
	--TODO this starts a new game right away, replace this with player selection for restarting or loading
	self:StartNewGame();
end
-----------------------------------------------------------------------------------------
-- Module Stuff
-----------------------------------------------------------------------------------------
--Include and initialize the modules we need
function DayZ:DoCoreModuleInclusionAndInitialization()
	--Required Modules
	dofile(self.ModulePath.."Communication Module.lua"); --Communication always included
	dofile(self.ModulePath.."Util Module.lua"); --Util always included
	dofile(self.ModulePath.."Save Load Module.lua"); --Game Saving and Loading always included
	self:StartSaveLoad();
	dofile(self.ModulePath.."Player Management Module.lua"); --Player Management always included
	self:StartPlayerManagement();
	dofile(self.ModulePath.."Scene Loading and Transitions Module.lua"); --Scene Loading and Transitions always included
	self:StartSceneLoading();
end
--Include the non-required modules we want
function DayZ:DoExtraModuleInclusion()
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
--Overwrite scene specific module inclusions as desired here, still constrained by whether or not the module's includable
function DayZ:DoExtraModuleOverwrites()
	--Example:
	--self.IncludeAlerts = false; -- Don't include alerts regardless of the scene
end
--Enforce any module constraints
function DayZ:DoExtraModuleEnforcement()
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
	
	--Make sure modules that require other modules have their requirements enforced
	self.IncludeBehaviours = self.IncludeSpawns and self.IncludeBehaviours;
	self.IncludeFlashlight = self.IncludeDayNight and self.IncludeFlashlight;
end
--Initialize the included modules
function DayZ:DoExtraModuleInitialization()
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
		self:StartFlashlight(); --Does nothing, just to fill space so the order stays the same
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
	--Do any necessary initial notifications
	self:DayNightNotifyMany_DayNightCycle(); --Notify so everything that needs to knows the time of day
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
	ModularActivity = nil;
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
			self:RemoveFromZombieTable(v.actor)
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
		for k, v in pairs(self.HumanTable.Players) do
			--v.actor.Pos.X = math.min(v.actor.Pos.X + 600, SceneMan.SceneWidth-50);
			v.actor.Pos = SceneMan:MovePointToGround(Vector(v.actor.Pos.X + (v.actor.HFlipped and -600 or 600), 0), 10, 5);
			v.actor.Pos.X = math.min(v.actor.Pos.X, self.RightMostSpawn);
			v.actor.Pos.X = math.max(v.actor.Pos.X, self.LeftMostSpawn);
		end
	end
	if UInputMan:KeyPressed(26) then --Print some stuff
		local count = 0;
		for k, v in pairs (self.HumanTable.Players) do
			count = count + 1;
		end
		print ("Players: "..tostring(count));
		count = 0;
		for k, v in pairs (self.HumanTable.NPCs) do
			count = count + 1;
		end
		print ("NPCs: "..tostring(count));
		count = 0;
		for k, v in pairs (self.ZombieTable) do
			count = count + 1;
		end
		print ("Zombies: "..tostring(count));
		count = 0;
		if self.IncludeLoot then
			for k, v in pairs (self.LootTable) do
				for k2, v2 in pairs(v) do
					count = count + 1;
				end
			end
			print ("Loot: "..tostring(count));
		end
		print("Waiting Respawns: "..tostring(#self.PlayerRespawnTable));
		if (DayZHumanWoundTable) then
			count = 0;
			for k, v in pairs (DayZHumanWoundTable) do
				for k2, v2 in pairs(v.wounds) do
					count = count + 1;
				end
			end
			print ("Wounds: "..tostring(count));
		else
			print ("Wounds: No Wound Table");
		end
		if self.IncludeAlerts then
			count = 0;
			for k, v in pairs(self.AlertTable) do
				count = count + 1;
			end
			print ("Alerts: "..tostring(count));
			count = 0;
			for k, v in pairs(self.AlertItemTable) do
				count = count + 1;
			end
			print ("Alert Items: "..tostring(count));
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
	if UInputMan:KeyPressed(14) then --Print everything in the console to a file called "output" then clear it
		ConsoleMan:SaveAllText("output");
		ConsoleMan:Clear();
	end
	end
	---------------------
	--TODO TESTING KEYS--
	---------------------
	
	--Clean tables, must be done first as it's important to prevent crashes
	self:DoActorChecksAndCleanup();
	
	self:DoPlayerManagement();
	
	--Deal with sustenance, called every frame for dynamic decreasing by actions
	if self.IncludeSustenance then
		self:DoSustenance();
	end
	
	--Deal with the day/night cycle and alerts for it
	if self.IncludeDayNight then
		self:DoDayNight();
	end
	
	--Deal with flashlights
	if self.IncludeFlashlight then
		self:DoFlashlights();
	end
	
	--Deal with icons, called every frame so they don't lag behind in their position
	if self.IncludeIcons then
		self:DoIcons();
	end
	
	--Deal with ambient audio 
	if self.IncludeAudio then
		self:DoAudio();
	end
	
	--Deal with alert stuff, delays for delagging are done internally
	if self.IncludeAlerts then
		self:DoAlerts();
	end
	
	if self.GeneralLagTimer:IsPastSimMS(100) then
		
		--Deal with loot actions
		if self.IncludeLoot then
			self:DoLoot();
		end
		
		--Deal with zombie and NPC spawns
		if self.IncludeSpawns then
			self:DoSpawns();
		end
		
		--Deal with zombie and NPC behaviours
		if self.IncludeBehaviours then
			self:DoBehaviours();
		end
			
		self.GeneralLagTimer:Reset();
	end
	
	--Run transitions to other scenes
	self:RunTransitions();
	
	--Display text for all players
	for i = 0, self.PlayerCount do
		if self.ScreenText[i+1] ~= nil then
			FrameMan:SetScreenText(tostring(self.ScreenText[i+1]), i, 0, 0, false);
			self.ScreenText[i+1] = nil;
		end
	end
		
	self:YSortObjectivePoints();
end
-----------------------------------------------------------------------------------------
-- Check through all tables for things to remove. Done first
-----------------------------------------------------------------------------------------
function DayZ:DoActorChecksAndCleanup()
	for humantype, humantable in pairs(self.HumanTable) do
		for ID, v in pairs(humantable) do
			if v.actor.Health <= 0 or not MovableMan:IsActor(v.actor) or v.actor.ToDelete == true then
				print ("Removing dead "..humantype.." from table in Main Script");
				self:NotifyMany_DeadHuman(humantype, v.player, ID, v.alert);
				humantable[ID] = nil;
			else
				--Make sure the player is switched to the actor
				if not v.actor:IsPlayerControlled() then
					SceneMan:SetScrollTarget(v.actor.Pos, 1, true, v.player);
				end
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
			self:RemoveFromZombieTable(v.actor);
			self.ZombiesKilled = self.ZombiesKilled + 1;
		end
	end
end