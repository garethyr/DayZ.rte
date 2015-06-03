-----------------------------------------------------------------------------------------
-- NECESSARY MODULE: Load scenes from their datafiles
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartSceneLoading()
	--------------------------
	--SCENELOADING CONSTANTS--
	--------------------------
	self.DataPath = "DayZ.rte/Scenes/Data/"; --The path to all datafiles
	self.DataFileExtension = ".txt"; --The extension for all datafiles
	
	--------------------------------------------
	--SCENELOADING DATAFILE AFFECTED VARIABLES--
	--------------------------------------------
	self.CurrentDataType = "";
	
	--NOTE: Scene specific constants are setup here and loaded from the relevant datafile
	--Module Inclusion - default to false for safety
	self.IncludeLoot = false;
	self.IncludeSustenance  = false;
	self.IncludeSpawns = false;
	self.IncludeDayNight = false;
	self.IncludeFlashlight = false;
	self.IncludeIcons = false;
	self.IncludeBehaviours = false;
	self.IncludeAudio = false;
	self.IncludeAlerts = false;
	
	--General multi-purpose variables
	self.IsOutside = nil; --Used to determine if the current map is outside, i.e. true means daynight, weather, celestial bodies, no BG changes. False means none of those and permanent darkness (though daynight time still passes)
	self.LeftMostSpawn = 0; --Number of pixels away from the left side of the map that zombies or npcs can spawn
	self.RightMostSpawn = SceneMan.SceneWidth; --Number of pixels away from the right side of the map that zombies or npcs can spawn
	
	--Non-Transition Areas
	self.NumberOfCivilianLootAreas = nil; --The number of civilian loot areas
	self.NumberOfHospitalLootAreas = nil; --The number of hospital loot areas
	self.NumberOfMilitaryLootAreas = nil; --The number of military loot areas
	self.NumberOfLootZombieSpawnAreas = nil; --The number of spawn areas for loot zombies
	self.NumberOfShelterAreas = nil; --The number of shelter areas, places players and NPCs can use to avoid getting sickness due to bad weather
	self.NumberOfAudioCivilizationAreas = nil; --The number of areas where civilization localized audio will play instead of nature localized audio
	self.NumberOfAudioBeachAreas = nil; --The number of areas where beach localized audio will play instead of nature localized audio

	--Transition and Spawn Areas
	self.TransitionAreas = {}; --The various scene transition areas in the current scene,
								--Values: area = the actual area, target = the scene to transition to,
								--spawnarea = the area to spawn in after transition, constraints = any constraint functions for transition
	self.PlayerSpawnAreas = {}; --The various player spawn areas in the current scene
	self.NumberOfPlayerSpawnAreas = nil; --The number of predictably named spawn areas in the current scene
	self.DefaultPlayerSpawnAreaNumberNumber = nil; --The number of predictably named spawn areas in the current scene
	
	--DayNight variables - only used if self.DayNightIncludable is true
	if self.DayNightIncludable then
		self.BackgroundChanges = nil;
		self.BackgroundTotalNumber = nil;
		self.CelestialBodies = nil;
		self.CelestialBodySunFrameTotal = nil;
		self.CelestialBodyMoonFrameTotal = nil;
	end
	
	--Audio variables - only used if self.AudioIncludable is true
	if self.AudioIncludable then
		self.AudioDefaultLocalizedAreaName = nil;
	end
	
	------------------------------
	--STATIC SCENELOADING TABLES--
	------------------------------
	--Table for translating datafile text to lua variables
	self.SceneLoadingData = {
	
		["MODULE INCLUSIONS"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["Loot"] = function(self, val) self.IncludeLoot = val end,
			["Sustenance"] = function(self, val) self.IncludeSustenance = val end,
			["Spawns"] = function(self, val) self.IncludeSpawns = val end,
			["DayNight"] = function(self, val) self.IncludeDayNight = val end,
			["Flashlight"] = function(self, val) self.IncludeFlashlight = val end,
			["Behaviours"] = function(self, val) self.IncludeBehaviours = val end,
			["Icons"] = function(self, val) self.IncludeIcons = val end,
			["Audio"] = function(self, val) self.IncludeAudio = val end,
			["Alerts"] = function(self, val) self.IncludeAlerts = val end
		},
		
		["GENERAL"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["IsOutside"] = function(self, val) self.IsOutside = val end,
			["LeftMostSpawn"] = function(self, val) self.LeftMostSpawn = val end,
			["RightMostSpawn"] = function(self, val) self.RightMostSpawn = SceneMan.Scene.Width - val end
		},
		
		["AREA NUMBERS"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["CivilianLootAreas"] = function(self, val) self.NumberOfCivilianLootAreas = val end,
			["HospitalLootAreas"] = function(self, val) self.NumberOfHospitalLootAreas = val end,
			["MilitaryLootAreas"] = function(self, val) self.NumberOfMilitaryLootAreas = val end,
			["LootZombieSpawnAreas"] = function(self, val) self.NumberOfLootZombieSpawnAreas = val end,
			["ShelterAreas"] = function(self, val) self.NumberOfShelterAreas = val end,
			["AudioCivilizationAreas"] = function(self, val) self.NumberOfAudioCivilizationAreas = val end,
			["AudioBeachAreas"] = function(self, val) self.NumberOfAudioBeachAreas = val end
		},
		
		["PLAYER SPAWNS"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["PlayerSpawnAreas"] = function(self, val) self.NumberOfPlayerSpawnAreas = val end,
			["DefaultPlayerSpawnAreaNumber"] = function(self, val) self.DefaultPlayerSpawnAreaNumber = val end
		},
		
		["DAYNIGHT"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["BackgroundChanges"] = function(self, val) self.BackgroundChanges = val end,
			["BackgroundTotal"] = function(self, val) self.BackgroundTotalNumber = val end,
			["CelestialBodies"] = function(self, val) self.CelestialBodies = val end,
			["SunFrameTotal"] = function(self, val) self.CelestialBodySunFrameTotal = val end,
			["MoonFrameTotal"] = function(self, val) self.CelestialBodyMoonFrameTotal = val end
		},
		
		["AUDIO"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["DefaultAudioType"] = function(self, val) self.AudioDefaultLocalizedAreaName = val end,
		},
		
		["TRANSITION AREAS"] = {
			["LoadData"] = function (self, data, loadtable) self:AddTransitionAreasFromData(data) end,
			["HAS BOAT"] = function(self) return self.HasBoat end,
			["IN HELICOPTER"] = function(self) return self.InHelicopter end
		}
	}
	
	-------------------------------
	--DYNAMIC SCENELOADING TABLES--
	-------------------------------
	--A list of transition areas for the current scene
	--Contains the relevant spawn area in the transitioned scene, as well as any constraints for transition
	self.TransitionAreas = {};
	
	--The saved human table, used to transition humans from scene to scene
	--Keys - Values 
	--name, team, health, sharpness, player = the player controlling the actor, sust = {table with their values for each susttype},
	--wounds = all their wounds from the global wound table, inventory = their inventory and equipped item, in order
	self.TransitionHumanTable = {};
	
	------------------------
	--TRANSITION VARIABLES--
	------------------------
	self.TransitionTimer = Timer();
	self.TransitionInterval = 1000; --Decrement counter ever second
	self.TransitionBaseWaitCounter = 5; --The base count-down to scene transitions that the actual counter gets reset to
	self.TransitionWaitCounter = self.TransitionBaseCounter; --The count-down to scene transitions
end
----------------------
--CREATION FUNCTIONS--
----------------------
function ModularActivity:LoadScene(scenename)
	local file = LuaMan:FileOpen(self.DataPath..scenename..self.DataFileExtension, "rt");
	while not LuaMan:FileEOF(file) do
		local line = LuaMan:FileReadLine(file)
		local data = line:gsub("\n" , "");
		data = data:gsub("\r" , "");
		if data:find("%-%-") ~= nil then
			data = data:sub(1, (data:find("%-%-") - 2));
		end
		if data:find("//") ~= nil then
			data = data:sub(1, (data:find("//") - 2));
		end
		if data:trim() ~= "" then
			if data:find("||") ~= nil then
				self.CurrentDataType = data:sub(3, data:len());
			else
				if self.SceneLoadingData[self.CurrentDataType] ~= nil then
					self.SceneLoadingData[self.CurrentDataType].LoadData(self, data, self.SceneLoadingData[self.CurrentDataType]);
				end
			end
		end
	end
	LuaMan:FileClose(file)
end
--Adding simple boolean or number values, such as module inclusions, general variables, daynight variables, area numbers
function ModularActivity:AddSimpleValueFromData(data, loadtable)
	local fields = self:TrimTable(data:split("="));
	if loadtable[fields[1]] ~= nil then
		if tonumber(fields[2]) ~= nil then
			loadtable[fields[1]](self, tonumber(fields[2]));
			--print("Loading Number Data: self."..fields[1].." = "..fields[2]);
		elseif fields[2] == "true" or fields[2] == "false" then
			local istrue = fields[2] == "true";
			loadtable[fields[1]](self, istrue);
			--print("Loading Boolean Data: self."..fields[1].." = "..fields[2]);
		else
			loadtable[fields[1]](self, fields[2]);
			--print("Loading String Data: self."..fields[1].." = "..fields[2]);
		end
	end
end
--Adding transitions
function ModularActivity:AddTransitionAreasFromData(data, loadtable)
	local fields = self:TrimTable(data:split("="));
	if data:find("\t") == nil then
		self.TransitionAreas[#self.TransitionAreas+1] = {area = SceneMan.Scene:GetArea("Transition Area "..tostring(#self.TransitionAreas+1)), target = fields[2], spawnarea = "", constraints = {}};
		--print ("Transition Area "..tostring(#self.TransitionAreas).." Added");
	else
		if fields[1]:find("Spawn Area") ~= nil then
			self.TransitionAreas[#self.TransitionAreas].spawnarea = tonumber(fields[2]); --Spawn areas stay as text and are located during sceneloading
			--print ("Added spawn area to transition area "..tostring(#self.TransitionAreas)..": "..tostring(self.TransitionAreas[#self.TransitionAreas].spawnarea));
		elseif fields[1]:find("Constraints") ~= nil then
			local constraints = fields[2]:split(",");
			self.TransitionAreas[#self.TransitionAreas].constraints = constraints; --Constraints stay as a table of strings as their actual functions are run during transition attempts
			--print ("Added constraint to transition area "..tostring(#self.TransitionAreas)..": "..tostring(self.TransitionAreas[#self.TransitionAreas].constraints[1]));
		end
	end
end
--Load the spawn areas for the newly loaded scene
function ModularActivity:LoadScenePlayerSpawnAreas()
	--Load spawn areas for the new scene
	self.PlayerSpawnAreas = {};
	for i = 1, self.NumberOfPlayerSpawnAreas do
		self.PlayerSpawnAreas[i] = SceneMan.Scene:GetArea("Player Spawn Area "..tostring(i));
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Check for any transitions that should be happening
function ModularActivity:RunTransitions()
	local possibletransitions = {}; --A counter for possible transitions, i.e. there's at least one player in the area and constraints are met
	for _, transition in pairs(self.TransitionAreas) do
		for __, player in pairs(self.HumanTable.Players) do
			if self:CheckTransitionConstraints(transition.constraints) and transition.area:IsInside(player.actor.Pos) then
				possibletransitions[#possibletransitions+1] = player.actor;
			end
		end
		--Don't zero the transition count if there are any transitions possible
		if #possibletransitions > 0 and #possibletransitions < self.HumanCount then
			for _, actor in ipairs(possibletransitions) do
				self:AddScreenText("You must gather your party before venturing forth.", actor:GetController().Player);
				self:AddScreenText("Transition in "..tostring(self.TransitionWaitCounter).." seconds.", actor:GetController().Player);
			end
			self.TransitionTimer:Reset();
		--Start to transition if the transition count is equal to the number of players
		elseif #possibletransitions == self.HumanCount then
			self:AddScreenText("Transition in "..tostring(self.TransitionWaitCounter).." seconds");
			if self.TransitionWaitCounter > 0 and self.TransitionTimer:IsPastSimMS(self.TransitionInterval) then
				self.TransitionWaitCounter = self.TransitionWaitCounter - 1;
				self.TransitionTimer:Reset()
			elseif self.TransitionWaitCounter == 0 then
				self:DoSceneTransition(transition.target, transition.spawnarea);
			end
			return;
		end
	end
	--Reset transition countdown if no one is in a transition area
	if #possibletransitions == 0 then
		self.TransitionWaitCounter = self.TransitionBaseWaitCounter;
		self.TransitionTimer:Reset();
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Clean up main script tables for transitions
function ModularActivity:DoCleanupForTransition()
	self.HumanTable = {
		Players = {},
		NPCs = {}
	};
	self.ZombieTable = {};
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Check if a transitions area's constraints are met (also returns true if they're invalid)
function ModularActivity:CheckTransitionConstraints(constraints)
	for _, constraint in pairs(constraints) do
		if self.SceneLoadingData["TRANSITION AREAS"][constraint](self) == false then
			return false;
		end
	end
	return true;
end
--Transition scenes
function ModularActivity:DoSceneTransition(target, playerspawnareanum)
	local stateandtime = self:RequestDayNight_GetCurrentStateAndTime() or {};
	self.TransitionAreas = {};
	self:SavePlayersForTransition();
	
	SceneMan:LoadScene(target, true); --Load the actual scene
	self.Wrap = SceneMan.SceneWrapsX;
	self:DoCleanupForTransition(); --Cleanup any leftovers from required modules that don't get re-instantiated
	self:LoadScene(target); --Parse the scene datafiles
	self:LoadScenePlayerSpawnAreas(); --Get as areas the spawn areas for the scene, as defined in the datafile
	
	--v DO NOT TOUCH FOR MODULE CHANGES v--
	self:DoExtraModuleInclusion();
	self:DoExtraModuleOverwrites(); --Use this function (in the main script) to overwrite scene specific inclusions
	self:DoExtraModuleEnforcement();
	self:DoExtraModuleInitialization();
	--^ DO NOT TOUCH FOR MODULE CHANGES ^--

	self:NotifyDayNight_SceneTransitionOccurred(stateandtime.cstate, stateandtime.ctime);
	self:AddStartingPlayerActors(playerspawnareanum);
	self.D = self.D + 1;
end
--Save players so they keep their stats on scene transitions
function ModularActivity:SavePlayersForTransition()
	self.TransitionHumanTable = {};
	for k, v in pairs(self.HumanTable.Players) do
		self:SavePlayerForTransition(v.actor);
	end
end
--Save a player for transition to keep its stats
function ModularActivity:SavePlayerForTransition(actor)
	table.insert(self.TransitionHumanTable, {name = actor.PresetName, team = actor.Team, health = actor.Health, sharpness = actor.Sharpness, player = actor:GetController().Player, sust = {}, wounds = {}, inventory = {}});
	--Add the player's sust
	for susttype, sustamount in pairs(self:RequestSustenance_GetSustenanceValuesForID(actor.UniqueID)) do
		self.TransitionHumanTable[#self.TransitionHumanTable].sust[susttype] = sustamount;
	end
	--Add the player's wounds
	if DayZHumanWoundTable ~= nil and DayZHumanWoundTable[actor.UniqueID] ~= nil then
		self.TransitionHumanTable[#self.TransitionHumanTable].wounds = DayZHumanWoundTable[actor.UniqueID].wounds;
		DayZHumanWoundTable[actor.UniqueID] = nil;
	end
	--Add the player's equipped item
	if actor.EquippedItem ~= nil then
		local obj = actor.EquippedItem;
		local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
		table.insert(self.TransitionHumanTable[#self.TransitionHumanTable].inventory, item);
	end
	--Add the player's inventory
	if not actor:IsInventoryEmpty() then
		for i = 1, actor.InventorySize do
			local obj = actor:Inventory();
			local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
			table.insert(self.TransitionHumanTable[#self.TransitionHumanTable].inventory, item);
			actor:SwapNextInventory(nil, true);
		end
	end
	actor.ToDelete = true;
end
--Add starting player actors after a transition
function ModularActivity:AddStartingPlayerActors(spawnareanum)
	if #self.TransitionHumanTable == 0 then
		self:CreateNewPlayerActors();
	else
		self:LoadPlayersAfterTransition();
	end
	self:SpawnPlayerActors(spawnareanum);
end
--Load players that were saved for the transition
function ModularActivity:LoadPlayersAfterTransition()
	for _, humantable in pairs(self.TransitionHumanTable) do
		----------------------------------------------------------------------------------------------------
		--TODO in future versions use simple MovableMan:RemoveActor and MovableMan:RemoveActor for this NOTE: RemoveActor may cause problems!?
		local newactor = CreateAHuman(humantable.name, self.RTE);
		newactor.Team = humantable.team;
		newactor.Health = humantable.health;
		newactor.Sharpness = humantable.sharpness;
		newactor.AIMode = Actor.AIMODE_SENTRY;
		newactor.HUDVisible = false;
		--Attach wounds
		for _, wound in pairs(humantable.wounds) do
			local wound = CreateAEmitter(wound.PresetName);
			newactor:AttachEmitter(wound, Vector(RangeRand(-1,1),RangeRand(-newactor.Height/3, newactor.Height/3)), true); --TODO maybe come up with a better way of wound positioning? Get the original positions?
		end
		--Add inventory
		local itemcreatetable = {HDFirearm = function(self, name) return CreateHDFirearm(name, self.RTE) end,
								 TDExplosive = function(self, name) return CreateTDExplosive(name, self.RTE) end,
								 HeldDevice = function(self, name) return CreateHeldDevice(name, self.RTE) end,
								 ThrownDevice = function(self, name) return CreateThrownDevice(name, self.RTE) end}
		for _, item in ipairs(humantable.inventory) do
			local newitem = itemcreatetable[item.itype](self, item.name);
			newitem.Sharpness = item.sharpness;
			newactor:AddInventoryItem(newitem);
		end
		----------------------------------------------------------------------------------------------------
		self:AddPlayerToRespawnTable(newactor, humantable.player, {sust = humantable.sust});
	end
	self.TransitionHumanTable = {};
end