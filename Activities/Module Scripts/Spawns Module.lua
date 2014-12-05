-----------------------------------------------------------------------------------------
-- Spawn zombies and NPCs for a variety of reasons and purposes
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartSpawns()
	--------------------------
	--ZOMBIE SPAWN CONSTANTS--
	--------------------------
	--General
	self.ZombieSpawnInterval = 30000; --General purpose spawn interval used for various specific ones
	self.ZombieSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --Minimum spawn distance for all zombies, no specific minimum spawn should be less than this
	self.ZombieSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --Minimum spawn distance for all zombies, specific maximum spawns can be greater than this
	self.ZombieAlertAwarenessModifier = 1; --The modifier for zombie alert awareness range, < 1 is less aware, > 1 is more aware
	
	--Loot area zombies
	self.SpawnLootZombieMaxGroupSize = 4; --The maximum number of loot zombies that will spawn for one area
	self.SpawnLootZombieMinDistance = self.ZombieSpawnMinDistance; --Minimum spawn distance for loot zombies
	self.SpawnLootZombieMaxDistance = self.ZombieSpawnMaxDistance; --Maximum spawn distance for loot zombies
	
	self.SpawnLootZombieArea = {};
	self.SpawnLootZombieTimer = {};
	self.SpawnLootZombieInterval = self.ZombieSpawnInterval; 
	for i = 1, self.NumberOfLootZombieSpawnAreas do
		self.SpawnLootZombieArea[i] = SceneMan.Scene:GetArea(("Spawn Area "..tostring(i)));
		self.SpawnLootZombieTimer[i] = Timer();
		self.SpawnLootZombieTimer[i].ElapsedSimTimeMS = self.SpawnLootZombieInterval; --Make sure first wave of zombies always spawns
	end
	--Alert zombies
	
	
	-----------------------
	--NPC SPAWN CONSTANTS--
	-----------------------
end
--------------------
--CREATE FUNCTIONS--
--------------------
--Spawn 3 zombies in the area
--SpawnTypes: alert, loot - the former is only for alert zombies
--TargetTypes: alert, actor, pos - the first is for any alert triggered spawn, the second for actor and the third for static position --TODO is pos never used???
function Chernarus:SpawnZombie(spawnpoint, target, targettype, spawntype)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		local targetpos;
		--Get the target's position to calculate startdist and use for waypoints
		if spawntype == "alert" or targettype == "alert" then
			targetpos = target.pos;
		else
			targetpos = targettype == "actor" and target.Pos or target;
		end
	
		local actor = CreateAHuman("Zombie 1", "DayZ.rte");
		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", "DayZ.rte"));
		actor.Team = self.ZombieTeam;
		
		--Alert zombies have to be positioned differently than loot zombies
		if spawntype == "alert" then
			actor.Pos = SceneMan.MovePointToGround(Vector(target.X - self.ZombieSpawnMinDistance + math.random(-30, 30), target.Y), 10, 0); --TODO make this spawn pos safer
		elseif spawntype == "loot" then
			actor.Pos = Vector(spawnpoint.X + math.random(-30, 30), spawnpoint.Y);
		end
		--Zombies with actor targets get an MOWaypoint, those without get a SceneWaypoint nearby
		if targettype == "actor" then
			actor:AddAIMOWaypoint(target);
		else
			--actor:AddAISceneWaypoint(targetpos);
		end
		actor.AIMode = Actor.AIMODE_GOTO;
		MovableMan:AddActor(actor);
		local startdist =  math.floor(SceneMan:ShortestDistance(targetpos, actor.Pos, true).Magnitude);
		self:AddToZombieTable(actor, target, targettype, startdist);
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
function Chernarus:DoSpawns()
	self:DoLootZombieSpawning();
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Pick where to spawn the zombies based on player position
function Chernarus:DoLootZombieSpawning()
	--If we have a human in one of the loot zombie spawn areas and haven't spawned recently, spawn zombies for the area.
	local target, nearhumans, nearalerts;
	for i, v in ipairs(self.SpawnLootZombieArea) do
		if self.SpawnLootZombieTimer[i]:IsPastSimMS(self.SpawnLootZombieInterval) then
			nearhumans = self:CheckForNearbyHumans(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
			nearalerts = self:RequestAlerts_CheckForVisibleAlerts(v:GetCenterPoint(), self.ZombieAlertAwarenessModifier, self.SpawnLootZombieMinDistance);
			if nearhumans or nearalerts then
				if nearhumans then
					target = self:NearestHuman(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
					for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
						self:SpawnZombie(v:GetCenterPoint(), target, "actor", "loot");
					end
				elseif nearalerts then
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
