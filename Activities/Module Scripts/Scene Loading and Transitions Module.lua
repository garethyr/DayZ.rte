-----------------------------------------------------------------------------------------
-- Load scenes from their datafiles
-----------------------------------------------------------------------------------------
--Setup
function DayZ:StartSceneLoading()
	--------------------------
	--SCENELOADING CONSTANTS--
	--------------------------
	self.DataPath = "DayZ.rte/Scenes/Data/"; --The path to all datafiles
	self.DataFileExtension = ".txt"; --The extension for all datafiles
	--NOTE: Scene specific constants are setup here and loaded from the relevant datafile
	--Non-Transition Areas
	self.NumberOfLootArea  = nil; --The number of loot areas
	self.NumberOfLootZombieSpawnAreas = nil; --The number of spawn areas for loot zombies
	self.NumberOfShelterAreas = nil; --The number of shelter areas, places players and NPCs can use to avoid getting sickness due to bad weather
	self.NumberOfAudioCivilizationAreas = nil; --The number of areas where civilization localized audio will play instead of nature localized audio
	self.NumberOfAudioBeachAreas = nil; --The number of areas where beach localized audio will play instead of nature localized audio

	--Transition Areas
	self.TransitionAreas = {};
	
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
	
	------------------------------
	--STATIC SCENELOADING TABLES--
	------------------------------
	--Tables for translating datafile text to lua variables
	self.AreaNumberData = {
		["LootAreas"] = function(self, val) self.NumberOfLootAreas = val end,
		["LootZombieSpawnAreas"] = function(self, val) self.NumberOfLootZombieSpawnAreas = val end,
		["ShelterAreas"] = function(self, val) self.NumberOfShelterAreas = val end,
		["AudioCivilizationAreas"] = function(self, val) self.NumberOfAudioCivilizationAreas = val end,
		["AudioBeachAreas"] = function(self, val) self.NumberOfAudioBeachAreas = val end
	}
	
	self.TransitionConstraintData = {
		["HAS BOAT"] = function(self) return self.HasBoat end,
		["IN HELICOPTER"] = function(self) return self.InHelicopter end
	}
	
	self.ModuleData = {
		["Loot"] = function(self, val) self.IncludeLoot = val end,
		["Sustenance"] = function(self, val) self.IncludeSustenance = val end,
		["Spawns"] = function(self, val) self.IncludeSpawns = val end,
		["DayNight"] = function(self, val) self.IncludeDayNight = val end,
		["Flashlight"] = function(self, val) self.IncludeIcons = val end,
		["Behaviours"] = function(self, val) self.IncludeBehaviours = val end,
		["Icons"] = function(self, val) self.IncludeIcons = val end,
		["Audio"] = function(self, val) self.IncludeAudio = val end,
		["Alerts"] = function(self, val) self.IncludeAlerts = val end,
	}
	
	--------------------------
	--SCENELOADING VARIABLES--
	--------------------------
	self.TransitionTimer = Timer();
	self.TransitionInterval = 1000; --Decrement counter ever second
	self.TransitionBaseWaitCounter = 5; --The base count-down to scene transitions that the actual counter gets reset to
	self.TransitionWaitCounter = self.TransitionBaseCounter; --The count-down to scene transitions
end
----------------------
--CREATION FUNCTIONS--
----------------------
function DayZ:LoadScene(scenename)
	local file = LuaMan:FileOpen(self.DataPath..scenename..self.DataFileExtension, "rt");
	local stage = 0;
	while not LuaMan:FileEOF(file) do
		local line = LuaMan:FileReadLine(file)
		local data = line:gsub("\n" , "");
		data = data:gsub("\r" , "");
		--data = data:gsub("--.*", ""); --TODO implement comments working (no need for block comments)
		--print ("Data is "..data)
		if data:trim() ~= "" then
			if data:find("||") ~= nil then
				stage = stage + 1;
			else
				if stage == 1 then
					self:AddAreaNumberFromData(data);
				elseif stage == 2 then
					self:AddTransitionAreaFromData(data);
				elseif stage == 3 then
					self:AddModuleInclusionFromData(data);
				end
			end
		end
	end
	LuaMan:FileClose(file)
end
function DayZ:AddAreaNumberFromData(data)
	local fields = self:TrimTable(data:split("="));
	if self.AreaNumberData[fields[1]] ~= nil then
		self.AreaNumberData[fields[1]](self, tonumber(fields[2]));
	end
end
function DayZ:AddTransitionAreaFromData(data)
	local fields = self:TrimTable(data:split("="));
	if data:find("\t") == nil then
		self.TransitionAreas[#self.TransitionAreas+1] = {area = SceneMan.Scene:GetArea("Transition Area "..tostring(#self.TransitionAreas+1)), target = fields[2], constraints = {}};
		--print ("Transition Area Added "..tostring(self.TransitionAreas[#self.TransitionAreas].area));
	else
		local constraints = fields[2]:split(",");
		self.TransitionAreas[#self.TransitionAreas].constraints = constraints; --Constraints stay as text as their actual functions are run during transition attempts
		--print ("Added constraint to transition area "..tostring(#self.TransitionAreas)..": "..tostring(self.TransitionAreas[#self.TransitionAreas].constraints[1]));
	end
end
function DayZ:AddModuleInclusionFromData(data)
	local fields = self:TrimTable(data:split("="));
	local included = tonumber(fields[2]) == 1;
	if self.ModuleData[fields[1]] ~= nil then
		self.ModuleData[fields[1]](self, included);
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Check for any transitions that should be happening
function DayZ:RunTransitions()
	local possibletransitioncount = 0; --A counter for possible transitions, i.e. there's at least one player in the area and constraints are met
	for _, transition in pairs(self.TransitionAreas) do
		for __, player in pairs(self.HumanTable.Players) do
			if self:CheckTransitionConstraints(transition.constraints) and transition.area:IsInside(player.actor.Pos) then
				possibletransitioncount = possibletransitioncount + 1;
			end
		end
		--Don't zero the transition count if there are any transitions possible
		if possibletransitioncount > 0 and possibletransitioncount < self.HumanCount then
			self:AddObjectivePoint("You must gather your party before venturing forth.\nTransition in "..tostring(self.TransitionWaitCounter).." seconds", transition.area:GetCenterPoint(), self.PlayerTeam, GameActivity.ARROWDOWN);
			self.TransitionTimer:Reset();
		--Start to transition if the transition count is equal to the number of players
		elseif possibletransitioncount == self.HumanCount then
			if self.TransitionWaitCounter > 0 and self.TransitionTimer:IsPastSimMS(self.TransitionInterval) then
				self:AddObjectivePoint("Transition in "..tostring(self.TransitionWaitCounter).." seconds", transition.area:GetCenterPoint(), self.PlayerTeam, GameActivity.ARROWDOWN);
				self.TransitionWaitCounter = self.TransitionWaitCounter - 1;
				self.TransitionTimer:Reset()
			elseif self.TransitionWaitCounter == 0 then
				self:DoSceneTransition(transition.target);
			end
			return;
		end
	end
	--Reset transition countdown if no one is in a transition area
	if possibletransitioncount == 0 then
		self.TransitionWaitCounter = self.TransitionBaseWaitCounter;
		self.TransitionTimer:Reset();
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Check if a transitions area's constraints are met (also returns true if they're invalid)
function DayZ:CheckTransitionConstraints(constraints)
	for _, data in pairs(constraints) do
		if self.TransitionConstraintData[data] == false then
			return false;
		end
	end
	return true;
end
--Transition scenes
function DayZ:DoSceneTransition(target)
	SceneMan:LoadScene(target, true);
	self:LoadScene(target);
	self:AddStartingPlayerActors();
end
--Add starting player actors
function DayZ:AddStartingPlayerActors()
	--The player actors
	for i = 0 , self.PlayerCount do
		if self:PlayerHuman(i) then
			local player = CreateAHuman("Survivor Black Reticle Actor" , "DayZ.rte");
			player:AddInventoryItem(CreateHDFirearm("[DZ] MR43" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , "DayZ.rte"));
			player:AddInventoryItem(CreateHeldDevice("12 Gauge Buckshot (2)" , "DayZ.rte"));
			player:AddInventoryItem(CreateHDFirearm("Crowbar" , "DayZ.rte"));
			player:AddInventoryItem(CreateHDFirearm("Baked Beans" , "DayZ.rte"));
			player:AddInventoryItem(CreateHDFirearm("Coke" , "DayZ.rte"));
			if self.IncludeFlashlight then
				player:AddInventoryItem(CreateHDFirearm("Flashlight" , "DayZ.rte"));
			end
			player:AddInventoryItem(CreateTDExplosive("Flare" , "DayZ.rte"));
			player.Sharpness = 0;
			player.Pos = Vector(995, 545)--(350, 550);
			player.Team = self.PlayerTeam;
			player.AIMode = Actor.AIMODE_SENTRY;
			player.HUDVisible = false;
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