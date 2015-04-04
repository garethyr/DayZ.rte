-----------------------------------------------------------------------------------------
-- Spawn zombies and NPCs for a variety of reasons and purposes
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartSpawns()
	--------------------------
	--ZOMBIE SPAWN CONSTANTS--
	--------------------------
	--General
	self.ZombieSpawnInterval = 90000; --General purpose spawn interval used for various specific ones
	self.ZombieSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --Minimum spawn distance for all zombies, no specific minimum spawn should be less than this
	self.ZombieSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --Maximum spawn distance for all zombies, specific maximum spawns can be greater than this
	self.ZombieAlertAwarenessModifier = 1; --The modifier for zombie alert awareness range, < 1 is less aware, > 1 is more aware, so >1 would mean they detect alerts from longer distances
	
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
end
--------------------
--CREATE FUNCTIONS--
--------------------
--Spawn 3 zombies in the area
--Spawners: alert - the actual alert table value, "loot" - spawned for loot guarding
--TargetTypes: human, alert, pos - the first is for any actor triggered spawn, the second for alert and the third for static position
--Note that pos targets are passed in as a table: {pos = Vector(), weight = number}
function ModularActivity:SpawnZombie(spawnpos, target, targettype, spawner)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		print (string.format("Spawning %s zombie at approximate %s %s for %s target", type(spawner) == "table" and "alert" or "loot", targettype == "alert" and "offset" or "position", tostring(spawnpos), targettype));
		local targetpos = self:GetZombieTargetPos(target, targettype);
		
		local actor = CreateAHuman("[DZ] Zombie 1", self.RTE);
--		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack BG", self.RTE));
		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", self.RTE));
		actor.Team = self.ZombieTeam;
		
		--Alert zombies (i.e. those spawned from alerts) have to be positioned differently than loot zombies
		--Note that spawner can be the same as target, but is not always
		if type(spawner) == "table" then --Table spawners are only alerts,
			local offset = spawnpos;
			actor.Pos = self:GetSafeRandomSpawnPosition(targetpos, offset, 10, true); --Less randomness and grounding on alert spawns
		elseif spawner == "loot" then
			actor.Pos = self:GetSafeRandomSpawnPosition(spawnpos, 0, 30, false); --More randomness on loot spawns
		end
		print ("After safety adjustments, zombie spawned at "..tostring(actor.Pos));
		
		MovableMan:AddActor(actor);
		self:SetZombieTarget(actor, target, targettype, spawner);
        self:AddToZombieTable(actor, target, targettype, spawner, startdist);
		
		return actor; --In case the function caller needs a reference to the actor
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
function ModularActivity:DoSpawns()
	self:DoLootZombieSpawning();
end
--Pick where to spawn the zombies based on human and alert positions
function ModularActivity:DoLootZombieSpawning()
	--If we have a human in one of the loot zombie spawn areas and haven't spawned recently, spawn zombies for the area.
	local target, nearhumans, nearalerts;
	for i, v in ipairs(self.SpawnLootZombieArea) do
		if self.SpawnLootZombieTimer[i]:IsPastSimMS(self.SpawnLootZombieInterval) then
			nearhumans = self:CheckForNearbyHumans(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
			nearalerts = self:RequestAlerts_CheckForVisibleAlerts(v:GetCenterPoint(), self.ZombieAlertAwarenessModifier, self.SpawnLootZombieMinDistance);
			--Get the spawn target if there are nearby humans or alerts
			if nearhumans or nearalerts then
				--Human targets take priority - for an alert target to take priority it would have to be made before a human started it
				if nearhumans then
					target = self:NearestHuman(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
					for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
						self:SpawnZombie(v:GetCenterPoint(), target, "human", "loot");
					end
				--If there are no nearby humans, alert targets are used
				elseif not nearhumans and nearalerts then
					target = self:RequestAlerts_NearestVisibleAlert(v:GetCenterPoint(), self.ZombieAlertAwarenessModifier, self.SpawnLootZombieMinDistance);
					for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
						self:SpawnZombie(v:GetCenterPoint(), target, "alert", "loot");
					end
				end
				self.SpawnLootZombieTimer[i]:Reset();
			end
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Return a safe spawn position (minimum spawn distance away from any humans), with an inputted random offset for position
function ModularActivity:GetSafeRandomSpawnPosition(spawnpos, offset, randomoffsetrange, movetoground)
	local resultpos = spawnpos;
	local randoffset = math.random(-randomoffsetrange, randomoffsetrange);
	local viable = false;
	
	--See if the offset spawnpos is viable in either direction (i.e. not near humans and within the map specific outer side spawn boundaries)
	for i = -1, 1, 2 do --Try offseting by positive and negative offset + randoffset
		resultpos = Vector(spawnpos.X + offset*i + randoffset, spawnpos.Y);
		if self:CheckForNearbyHumans(resultpos, 0, self.ZombieSpawnMinDistance) == false and resultpos.X > self.LeftMostSpawn and resultpos.Y < self.RightMostSpawn then
			viable = true;
			break;
		end
	end
	--If the position found wasn't viable, try using the position of the nearest human, offset by ZombieSpawnMinDistance
	if not viable then
		local humanactor = self:NearestHuman(resultpos, 0, self.ZombieSpawnMinDistance);
		resultpos = GetSafeRandomSpawnPosition(humanactor.Pos, self.ZombieSpawnMinDistance, randomoffsetrange, movetoground);
	end
		
	--Move the point to ground if necessary
	if movetoground then
		resultpos = SceneMan:MovePointToGround(Vector(resultpos.X, 0), 10, 0);
	end
	return resultpos;
end
--Directly set a zombie's target, both human waypoints and zombie table target value
function ModularActivity:SetZombieTarget(actor, target, targettype, spawner)
	local targetpos = self:GetZombieTargetPos(target, targettype);
	local startdist = math.floor(SceneMan:ShortestDistance(targetpos, actor.Pos, true).Magnitude);
	
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor:ClearAIWaypoints();
	
	--Zombies with human targets get an MOWaypoint, those without get a SceneWaypoint nearby
	if targettype == "human" then
		actor:AddAIMOWaypoint(target);
	else
		actor:AddAISceneWaypoint(SceneMan:MovePointToGround(Vector(targetpos.X, targetpos.Y), 10, 5));
	end
	self:AddToZombieTable(actor, target, targettype, spawner, startdist);
	actor.AIMode = Actor.AIMODE_GOTO;
	
	return targetpos;
end
--Return a position for the target, based on what type of target it is
function ModularActivity:GetZombieTargetPos(target, targettype)
	local targetpos = target.pos; --Alert and pos targets use tables wherein pos is the position
	if targettype == "human" then
		targetpos = target.Pos;
	end
	return targetpos;
end
--Clear the zombie's target completely
function ModularActivity:ClearZombieTarget(zombie)
	zombie.target = {val = false, ttype = "", startdist = 0};
	print ("Cleared zombie target, zombie table target entry is now "..tostring(self.ZombieTable[zombie.actor.UniqueID].target.val));
end