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
	self.SpawnAreas = {}; --The various player spawn areas in the current scene
	self.NumberOfSpawnAreas = nil; --The number of predictably named spawn areas in the current scene
	
	--DayNight variables - only used if self.DayNightIncludable is true
	if self.DayNightIncludable then
		self.BackgroundChanges = nil;
		self.BackgroundTotalNumber = nil;
		self.CelestialBodies = nil;
		self.CelestialBodySunFrameTotal = nil;
		self.CelestialBodyMoonFrameTotal = nil;
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
			["Flashlight"] = function(self, val) self.IncludeIcons = val end,
			["Behaviours"] = function(self, val) self.IncludeBehaviours = val end,
			["Icons"] = function(self, val) self.IncludeIcons = val end,
			["Audio"] = function(self, val) self.IncludeAudio = val end,
			["Alerts"] = function(self, val) self.IncludeAlerts = val end
		},
		
		["GENERAL"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["IsOutside"] = function(self, val) self.IsOutside = val end
		},
		
		["AREA NUMBERS"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["CivilianLootAreas"] = function(self, val) self.NumberOfCivilianLootAreas = val end,
			["HospitalLootAreas"] = function(self, val) self.NumberOfHospitalLootAreas = val end,
			["MilitaryLootAreas"] = function(self, val) self.NumberOfMilitaryLootAreas = val end,
			["LootZombieSpawnAreas"] = function(self, val) self.NumberOfLootZombieSpawnAreas = val end,
			["ShelterAreas"] = function(self, val) self.NumberOfShelterAreas = val end,
			["AudioCivilizationAreas"] = function(self, val) self.NumberOfAudioCivilizationAreas = val end,
			["AudioBeachAreas"] = function(self, val) self.NumberOfAudioBeachAreas = val end,
			["SpawnAreas"] = function(self, val) self.NumberOfSpawnAreas = val end
		},
		
		["DAYNIGHT"] = {
			["LoadData"] = function (self, data, loadtable) self:AddSimpleValueFromData(data, loadtable) end,
			["BackgroundChanges"] = function(self, val) self.BackgroundChanges = val end,
			["BackgroundTotal"] = function(self, val) self.BackgroundTotalNumber = val end,
			["CelestialBodies"] = function(self, val) self.CelestialBodies = val end,
			["SunFrameTotal"] = function(self, val) self.CelestialBodySunFrameTotal = val end,
			["MoonFrameTotal"] = function(self, val) self.CelestialBodyMoonFrameTotal = val end
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
	self.TransitionAreas = {}
	
	--------------------------
	--SCENELOADING VARIABLES--
	--------------------------
	self.CurrentDataType = "";
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
		else
			local istrue = fields[2] == "true";
			loadtable[fields[1]](self, istrue);
			--print("Loading Boolean Data: self."..fields[1].." = "..fields[2]);
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
			self.TransitionAreas[#self.TransitionAreas].spawnarea = fields[2]; --Spawn areas stay as text and are located during sceneloading
			--print ("Added spawn area to transition area "..tostring(#self.TransitionAreas)..": "..tostring(self.TransitionAreas[#self.TransitionAreas].spawnarea));
		elseif fields[1]:find("Constraints") ~= nil then
			local constraints = fields[2]:split(",");
			self.TransitionAreas[#self.TransitionAreas].constraints = constraints; --Constraints stay as a table of strings as their actual functions are run during transition attempts
			--print ("Added constraint to transition area "..tostring(#self.TransitionAreas)..": "..tostring(self.TransitionAreas[#self.TransitionAreas].constraints[1]));
		end
	end
end
--Load the spawn areas for the newly loaded scene
function ModularActivity:LoadSceneSpawnAreas()
	--Load spawn areas for the new scene
	self.SpawnAreas = {};
	for i = 1, self.NumberOfSpawnAreas do
		self.SpawnAreas[i] = SceneMan.Scene:GetArea("Spawn Area "..tostring(i));
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
			if self.TransitionWaitCounter > 0 and self.TransitionTimer:IsPastSimMS(self.TransitionInterval) then
				self:AddScreenText("Transition in "..tostring(self.TransitionWaitCounter).." seconds.");
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
--ACTION FUNCTIONS--
--------------------
--Check if a transitions area's constraints are met (also returns true if they're invalid)
function ModularActivity:CheckTransitionConstraints(constraints)
	for _, data in pairs(constraints) do
		if self.SceneLoadingData["TRANSITION AREAS"] == false then
			return false;
		end
	end
	return true;
end
--Transition scenes
function ModularActivity:DoSceneTransition(target, spawnarea)
	self.TransitionAreas = {};
	SceneMan:LoadScene(target, true);
	self:LoadScene(target);
	self:LoadSceneSpawnAreas();
	self:NotifyDayNight_ResetBackgroundPosition();
	if self.ModulesInitialized then
		self:AddStartingPlayerActors(self.SpawnAreas[tonumber(spawnarea)]);
	end
end
--Add starting player actors
function ModularActivity:AddStartingPlayerActors(spawnarea)
	--The player actors
	for i = 0 , self.PlayerCount do
		if self:PlayerHuman(i) then
			local player = CreateAHuman("Survivor Black Reticle Actor" , self.RTE);
			player:AddInventoryItem(CreateHDFirearm("[DZ] MR43" , self.RTE));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , self.RTE));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , self.RTE));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , self.RTE));
			player:AddInventoryItem(CreateHDFirearm("Crowbar" , self.RTE));
			player:AddInventoryItem(CreateHDFirearm("Baked Beans" , self.RTE));
			player:AddInventoryItem(CreateHDFirearm("Coke" , self.RTE));
			if self.IncludeFlashlight then
				player:AddInventoryItem(CreateHDFirearm("Flashlight" , self.RTE));
			end
			player:AddInventoryItem(CreateTDExplosive("Flare" , self.RTE));
			player.Sharpness = 0;
			player.Pos = Vector(spawnarea:GetCenterPoint().X - 25*math.floor(self.PlayerCount*0.5) + 25*i, spawnarea:GetCenterPoint().Y);
			player.Team = self.PlayerTeam;
			player.AIMode = Actor.AIMODE_SENTRY;
			player.HUDVisible = false;
			MovableMan:AddActor(player);
			--self:SetPlayerBrain(player, self.PlayerTeam);
			self:AddToPlayerTable(player);
		end
	end
	--TODO Test NPC, Remove Me!
	--[[self.TestNPC = CreateAHuman("Survivor Black" , self.RTE);
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Hatchet" , self.RTE));
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Baked Beans" , self.RTE));
	self.TestNPC:AddInventoryItem(CreateHDFirearm("Coke" , self.RTE));
	self.TestNPC:AddInventoryItem(CreateTDExplosive("M67" , self.RTE));
	self.TestNPC.Pos = Vector(1250, 400);
	self.TestNPC.Team = self.PlayerTeam;
	self.TestNPC.AIMode = Actor.AIMODE_SENTRY;
	MovableMan:AddActor(self.TestNPC);
	self.NPCTable[#self.NPCTable+1] = {self.TestNPC, 0, 0}--]]
end