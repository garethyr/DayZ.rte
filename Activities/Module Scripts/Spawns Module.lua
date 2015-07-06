-----------------------------------------------------------------------------------------
-- Spawn zombies and NPCs for a variety of reasons and purposes
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartSpawns()
	--------------------------
	--GENERAL SPAWN CONSTANTS--
	--------------------------
	self.MaxNumberOfSpawnSafetyCheckAttempts = 3; --The maximum number of times spawn safety checking should try to find another safe spot, if it hasn't found one already. Limited to avoid infinite or overly long loops

	--------------------------
	--ZOMBIE SPAWN CONSTANTS--
	--------------------------
	--General
	self.ZombieSpawnInterval = 90000; --General purpose spawn interval used for various specific ones
	self.ZombieSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --Minimum spawn distance for all zombies, no specific minimum spawn should be less than this
	self.ZombieSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --Maximum spawn distance for all zombies, specific maximum spawns can be greater than this
	self.ZombieAlertAwarenessModifier = 1; --The modifier for zombie alert awareness range, < 1 is less aware, > 1 is more aware, so > 1 would mean they detect alerts from longer distances
	
	--Loot area zombies
	self.SpawnLootZombieMaxGroupSize = 1; --The maximum number of loot zombies that will spawn for one area
	self.SpawnLootZombieMinDistance = self.ZombieSpawnMinDistance; --Minimum spawn distance for loot zombies
	self.SpawnLootZombieMaxDistance = self.ZombieSpawnMaxDistance; --Maximum spawn distance for loot zombies
	
	self.SpawnLootZombieArea = {};
	self.SpawnLootZombieTimer = {};
	self.SpawnLootZombieInterval = self.ZombieSpawnInterval; 
	for i = 1, self.NumberOfLootZombieSpawnAreas do
		self.SpawnLootZombieArea[i] = SceneMan.Scene:GetArea(("Loot Zombie Spawn Area "..tostring(i)));
		self.SpawnLootZombieTimer[i] = Timer();
		self.SpawnLootZombieTimer[i].ElapsedSimTimeMS = self.SpawnLootZombieInterval; --Make sure first wave of zombies always spawns
	end
	
	
	-----------------------
	--NPC SPAWN CONSTANTS-- TODO probably best to split up zombie and npc modules
	-----------------------
	--General
	self.NPCSpawnInterval = 90000; --General purpose spawn interval used for various specific ones
	self.NPCSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --Minimum spawn distance for all NPCs, no specific minimum spawn should be less than this
	self.NPCSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --Maximum spawn distance for all NPCs, specific maximum spawns can be greater than this
	self.NPCAlertAwarenessModifier = 1; --The modifier for NPC alert awareness range, < 1 is less aware, > 1 is more aware, so > 1 would mean they detect alerts from longer distances
	self.NPCChanceToUseMilitaryWeapons = 0.15; --% chance for an NPC to spawn with military grade weapons
	
	--Patrol
	self.SpawnNPCPatrolSize = 5; --The size of NPC patrol groups
	self.SpawnNPCPatrolAreaToGoTo = self.PlayerSpawnAreas[1]; --The player spawn area NPC patrols will aim to get to, then return from
	
	self.SpawnNPCPatrolArea = {}
	self.SpawnNPCPatrolTimer = Timer();
	self.SpawnNPCPatrolInterval = self.NPCSpawnInterval;
	for i = 1, self.NumberOfNPCPatrolSpawnAreas do
		self.SpawnNPCPatrolArea[i] = SceneMan.Scene:GetArea(("NPC Patrol Spawn Area "..tostring(i)));
	end
	
	--Ambush
	self.SpawnNPCAmbushSize = 1; --The size of NPC ambush groups
	
	self.SpawnNPCAmbushArea = {}
	self.SpawnNPCAmbushActors = {};
	self.SpawnNPCAmbushTimer = {};
	self.SpawnNPCAmbushInterval = self.NPCSpawnInterval*0.5; 
	for i = 1, self.NumberOfNPCAmbushSpawnAreas do
		self.SpawnNPCAmbushArea[i] = SceneMan.Scene:GetArea(("NPC Ambush Spawn Area "..tostring(i)));
		self.SpawnNPCAmbushTimer[i] = Timer();
		self.SpawnNPCAmbushTimer[i].ElapsedSimTimeMS = self.SpawnNPCAmbushInterval; --Make sure first wave of ambushers always spawns
	end
	
	-----------------------------
	--DYNAMIC NPC SPAWN TABLES--
	-----------------------------
	--Patrol
	self.NPCPatrolGroup = {};
end
--------------------
--CREATE FUNCTIONS--
--------------------
--Spawn a zombie in the area and return it for use
--Spawners: alert - the actual alert table value, "loot" - spawned for loot guarding
--TargetTypes: human, alert, pos - the first is for any actor triggered spawn, the second for alert and the third for static position
--Note that pos targets are passed in as a table: {pos = Vector(), weight = number}
function ModularActivity:SpawnZombie(spawnpos, targetval, targettype, spawner)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		print (string.format("Spawning %s zombie at approximate %s %s for %s targetval", type(spawner) == "table" and "alert" or "loot", targettype == "alert" and "offset" or "position", tostring(spawnpos), targettype));
		local targetpos = self:GetZombieTargetPos(targetval, targettype);
		
		local actor = CreateAHuman("[DZ] Zombie 1", self.RTE);
--		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack BG", self.RTE));
		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", self.RTE));
		actor.Team = self.ZombieTeam;
		
		--Alert zombies (i.e. those spawned from alerts) have to be positioned differently than loot zombies
		--Note that spawner can be the same as targetval, but is not always
		if type(spawner) == "table" then --Table spawners are only alerts,
			local offset = spawnpos;
			actor.Pos = self:GetSafeRandomSpawnPosition(targetpos, offset, 10, true); --Less randomness and grounding on alert spawns
		elseif spawner == "loot" then
			actor.Pos = self:GetSafeRandomSpawnPosition(spawnpos, 0, 30, false); --More randomness on loot spawns
		end
		print ("After safety adjustments, zombie spawned at "..tostring(actor.Pos));
		
		MovableMan:AddActor(actor);
		self:SetZombieTarget(actor, targetval, targettype, spawner);
		
		return actor; --In case the function caller needs a reference to the actor
	end
	return false;
end
function ModularActivity:SpawnNPC(spawnpos, targetpos)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		print ("Spawning NPC at approximate pos "..tostring(spawnpos).."with target pos "..tostring(targetpos));
		local usemilitary = math.random() < self.NPCChanceToUseMilitaryWeapons;
		
		local actors = {[false] = "Survivor Blue", [true] = "Ghillie Suit Soldier"};
		local primary = {[false] = "Civilian", [true] = "Military"};
		primary = self.WeaponList[primary[usemilitary]];
		local secondary = {[false] = "Melee", [true] = "Civilian"};
		secondary = self.WeaponList[secondary[usemilitary]];
		local tertiary = {[false] = nil, [true] = "Melee"};
		tertiary = tertiary[usemilitary] ~= nil and self.WeaponList[tertiary[usemilitary]] or nil;
		
		local actor = CreateAHuman(actors[usemilitary] , self.RTE);
		local mass = actor.Mass;
		local weapon = nil;
		
		weapon = CreateHDFirearm(primary[math.random(#primary)].weapon, self.RTE);
		actor:AddInventoryItem(weapon);
		weapon = CreateHDFirearm(secondary[math.random(#secondary)].weapon, self.RTE);
		actor:AddInventoryItem(weapon);
		if tertiary ~= nil then
			weapon = CreateHDFirearm(tertiary[math.random(#tertiary)].weapon, self.RTE);
			actor:AddInventoryItem(weapon);
		end
		--if self.IncludeFlashlight then
		--	self:AddFlashlightForActor(actor);
		--end
		
		actor.Pos = self:GetSafeRandomSpawnPosition(spawnpos, 0, 10, true); --Not too much randomness and move to ground
		actor.Sharpness = 0;
		actor.Team = self.BanditTeam;
		if targetpos == nil then
			actor.AIMode = Actor.AIMODE_SENTRY;
		else
			actor:AddAISceneWaypoint(targetpos);
			actor.AIMode = Actor.AIMODE_GOTO;
		end
		actor.HUDVisible = false;
		MovableMan:AddActor(actor);
		self:AddToNPCTable(actor);
		
		return actor;
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
function ModularActivity:DoSpawns()
	self:DoLootZombieSpawning();
	self:DoPatrolNPCSpawning();
	self:DoAmbushNPCSpawning();
end
--Pick where to spawn the zombies based on human and alert positions
function ModularActivity:DoLootZombieSpawning()
	--If we have a human in one of the loot zombie spawn areas and haven't spawned recently, spawn zombies for the area.
	local target, nearhumans, nearalerts;
	for i, v in ipairs(self.SpawnLootZombieArea) do
		if self.SpawnLootZombieTimer[i]:IsPastSimMS(self.SpawnLootZombieInterval) then
			nearhumans = self:CheckForNearbyHumans(v:GetCenterPoint(), nil, self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
			nearalerts = self:RequestAlerts_CheckForVisibleAlerts(v:GetCenterPoint(), self.ZombieAlertAwarenessModifier, self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
			--Get the spawn target if there are nearby humans or alerts
			if nearhumans or nearalerts then
				--Human targets take priority - for an alert target to take priority it would have to be made before a human started it
				if nearhumans then
					target = self:NearestHuman(v:GetCenterPoint(), nil, self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
					for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
						self:SpawnZombie(v:GetCenterPoint(), target, "human", "loot");
					end
				--If there are no nearby humans, alert targets are used
				elseif not nearhumans and nearalerts then
					target = self:RequestAlerts_NearestVisibleAlert(v:GetCenterPoint(), self.ZombieAlertAwarenessModifier, self.SpawnLootZombieMinDistance);
					print ("nearest alert to point is alert at pos "..tostring(target.pos));
					for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
						self:SpawnZombie(v:GetCenterPoint(), target, "alert", "loot");
					end
					print ("Loot zombies spawned because of alert at pos "..tostring(target.pos));
				end
				self.SpawnLootZombieTimer[i]:Reset();
			end
		end
	end
end
function ModularActivity:DoPatrolNPCSpawning()
	if self.SpawnNPCPatrolTimer:IsPastSimMS(self.SpawnNPCPatrolInterval) then
		local missing = self.SpawnNPCPatrolSize;
		for _, __ in pairs(self.NPCPatrolGroup) do
			missing = missing - 1;
		end
		if missing > math.floor(self.SpawnNPCPatrolSize*0.5) then
			for i = 1, missing do
				local pos = Vector(self.SpawnNPCPatrolArea[1]:GetCenterPoint().X - 75*(math.floor(missing*0.5) - i), self.SpawnNPCPatrolArea[1]:GetCenterPoint().Y);
				local actor = self:SpawnNPC(pos, self.SpawnNPCPatrolAreaToGoTo:GetCenterPoint());
				self.NPCPatrolGroup[actor.UniqueID] = actor;
			end
			self.SpawnNPCPatrolTimer:Reset();
		else
			self.SpawnNPCPatrolTimer:Reset();
		end
	end
end
function ModularActivity:DoAmbushNPCSpawning()
	local npc, nearplayers, nearalerts, nearzombies;
	for i, v in ipairs(self.SpawnNPCAmbushArea) do
		if  self.SpawnNPCAmbushActors[i] == nil and self.SpawnNPCAmbushTimer[i]:IsPastSimMS(self.SpawnNPCAmbushInterval) then
			nearplayers = self:CheckForNearbyHumans(v:GetCenterPoint(), "Players", self.NPCSpawnMinDistance, self.NPCSpawnMaxDistance);
			nearalerts = self:RequestAlerts_CheckForVisibleAlerts(v:GetCenterPoint(), self.NPCAlertAwarenessModifier, self.NPCSpawnMaxDistance, self.NPCSpawnMinDistance);
			nearzombies = self:CheckForNearbyZombies(v:GetCenterPoint(), self.NPCSpawnMinDistance, self.NPCSpawnMaxDistance);
			
			if nearhumans or nearalerts or nearzombies then
				npc = self:SpawnNPC(v:GetCenterPoint(), v:GetCenterPoint());
				self.SpawnNPCAmbushTimer[i]:Reset();
			end
		else
			self.SpawnNPCAmbushTimer[i]:Reset();
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Return a safe spawn position (minimum spawn distance away from any humans), with an inputted random offset for position
function ModularActivity:GetSafeRandomSpawnPosition(spawnpos, offset, randomoffsetrange, movetoground)
	return self:GetSafeRandomSpawnPositionRecurse(spawnpos, offset, randomoffsetrange, movetoground, 0);
end
function ModularActivity:GetSafeRandomSpawnPositionRecurse(spawnpos, offset, randomoffsetrange, movetoground, repeatcount)
	local resultpos = spawnpos;
	local randoffset = math.random(-randomoffsetrange, randomoffsetrange);
	local viable = false;
	
	--See if the offset spawnpos is viable in either direction (i.e. not near humans and within the map specific outer side spawn boundaries)
	for i = -1, 1, 2 do --Try offseting by positive and negative offset + randoffset
		resultpos = Vector(spawnpos.X + offset*i + randoffset, spawnpos.Y);
		if self:CheckForNearbyHumans(resultpos, "Players", 0, self.ZombieSpawnMinDistance) == false and resultpos.X > self.LeftMostSpawn and resultpos.X < self.RightMostSpawn then
			viable = true;
			break;
		end
	end
	--If the position found wasn't viable, try using the position of the nearest human, offset by ZombieSpawnMinDistance
	if not viable and repeatcount < self.MaxNumberOfSpawnSafetyCheckAttempts then
		local humanactor = self:NearestHuman(resultpos, nil, 0, self.ZombieSpawnMinDistance);
		resultpos = self:GetSafeRandomSpawnPositionRecurse(humanactor.Pos, self.ZombieSpawnMinDistance, randomoffsetrange, movetoground, repeatcount + 1);
	end
	--Move the point to ground if necessary
	if movetoground then
		local movefromair, movefromresult = Vector(0, 0), Vector(0, 0);
		--For outside maps, default to the move from air method but also calculated move from result to see which is better
		if self.IsOutside then
			movefromair = SceneMan:MovePointToGround(Vector(resultpos.X, 0), 10, 5);
			resultpos = movefromair;
		end
		movefromresult = SceneMan:MovePointToGround(resultpos, 10, 5);
		--If move from air is notably above move from result it's probably hitting a roof or something, so use move from result as long as it's not underground
		if movefromresult.Y - movefromair.Y > 10 then
			if SceneMan:FindAltitude(movefromresult, 20, 2) > 1 then
				resultpos = movefromresult;
			else
				resultpos = movefromair.Y == 0 and SceneMan:MovePointToGround(Vector(resultpos.X, 0), 10, 5) or movefromair;
			end
		end
	end
	return resultpos;
end
--Directly set a zombie's target, both human waypoints and zombie table target value
--NOTE: Rewrites the zombie's zombietable entry since it's the easiest way to update everything
function ModularActivity:SetZombieTarget(actor, targetval, targettype, spawner)
	local targetpos = self:GetZombieTargetPos(targetval, targettype);
	local startdist = math.floor(SceneMan:ShortestDistance(targetpos, actor.Pos, self.Wrap).Magnitude);
	
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor:ClearAIWaypoints();
	
	--Zombies with human targets get an MOWaypoint, those without get a SceneWaypoint nearby
	if targettype == "human" then
		actor:AddAIMOWaypoint(targetval);
	else
		actor:AddAISceneWaypoint(SceneMan:MovePointToGround(targetpos, 10, 5));
	end
	self:AddToZombieTable(actor, targetval, targettype, spawner, startdist);
	actor.AIMode = Actor.AIMODE_GOTO;
	
	return targetpos;
end
--Return a position for the target, based on what type of target it is
function ModularActivity:GetZombieTargetPos(targetval, targettype)
	--Handle zombies without a target
	if targetval == false then
		return 0;
	end
	local targetpos = targetval.pos; --Alert and pos targets use tables wherein pos is the position
	if targettype == "human" then
		targetpos = targetval.Pos;
	end
	return targetpos;
end
--Remove the zombie's target completely, setting it to empty target type and false target value
function ModularActivity:RemoveZombieTarget(zombie)
	zombie.target = {val = false, ttype = "", startdist = 0};
	print ("Removed zombie target, zombie table target entry is now "..tostring(self.ZombieTable[zombie.actor.UniqueID].target.val));
end