-----------------------------------------------------------------------------------------
-- Spawn zombies and NPCs for a variety of reasons and purposes
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartSpawns()
	--------------------
	--ZOMBIE CONSTANTS--
	--------------------
	--General
	self.ZombieSpawnInterval = 30000; --General purpose spawn interval used for various specific ones
	self.ZombieSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --General purpose minimum zombie spawn distance used for various specific ones, no minimum spawn distance should be less than this
	self.ZombieSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --General purpose maximum zombie spawn distance used for various specific ones
	self.DespawnZombieDistance = FrameMan.PlayerScreenWidth/2 + 600; --Screen resolution + 600 pixel distance for removing zombies
	
	
	
	--Loot area zombies
	self.SpawnLootZombieMaxGroupSize = 6; --The maximum number of loot zombies that will spawn for one area
	self.SpawnLootZombieMinDistance = self.ZombieSpawnMinDistance;
	self.SpawnLootZombieMaxDistance = self.ZombieSpawnMaxDistance;
	
	self.SpawnLootZombieArea = {};
	self.SpawnLootZombieTimer = {};
	self.SpawnLootZombieInterval = self.ZombieSpawnInterval; 
	for i = 1, self.NumberOfLootZombieSpawnAreas do
		self.SpawnLootZombieArea[i] = SceneMan.Scene:GetArea(("Spawn Area "..tostring(i)));
		self.SpawnLootZombieTimer[i] = Timer();
		self.SpawnLootZombieTimer[i].ElapsedSimTimeMS = self.SpawnLootZombieInterval; --Make sure first wave of zombies always spawns
	end
	--Alert zombies
	
	
	-----------------
	--NPC CONSTANTS--
	-----------------
end
-------------------
--CREATE FUNCTION--
-------------------
--Spawn 3 zombies in the area
function Chernarus:SpawnZombie(point, target, ttype)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		local actor = CreateAHuman("Zombie 1", "DayZ.rte");
		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", "DayZ.rte"));
		actor.Team = self.ZombieTeam;
		--Alert zombies have to be positioned differently than loot zombies
		if (ttype == "alert") then
			actor.Pos = SceneMan.MovePointToGround(Vector(target.X - self.ZombieSpawnMinDistance + math.random(-20, 20), target.Y), 10, 0); --TODO make this spawn pos safer
		elseif (ttype:find("loot") ~= nil) then
			actor.Pos = Vector(point.X + math.random(-30, 30), point.Y);
		end
		if (ttype == "actorloot") then
			actor:AddAIMOWaypoint(target);
		else
			actor:AddAISceneWaypoint(SceneMan.MovePointToGround(Vector(actor.Pos.X - (actor.Pos.X - target.X)/4 + math.random(-50, 50), actor.Pos.Y), 10, 0));
		end
		actor.AIMode = Actor.AIMODE_GOTO;
		MovableMan:AddActor(actor);
	end
end
-------------------
--UPDATE FUNCTION--
-------------------
function Chernarus:DoSpawns()
	self:DoLootZombieSpawning();
end
-----------------------------------------------------------------------------------------
-- Everything for Zombies
-----------------------------------------------------------------------------------------
--Pick where to spawn the zombies based on player position
function Chernarus:DoLootZombieSpawning()
	--If we have a human in one of the loot zombie spawn areas and haven't spawned recently, spawn zombies for the area.
	local target;
	for i, v in ipairs(self.SpawnLootZombieArea) do
		if self.SpawnLootZombieTimer[i]:IsPastSimMS(self.SpawnLootZombieInterval) and self:CheckForNearbyHumans(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance) then --OR checkfornearbyalerts == true
			print ("hey");
			target = self:NearestHuman(v:GetCenterPoint(), self.SpawnLootZombieMinDistance, self.SpawnLootZombieMaxDistance);
			for j = 1, math.random(1, self.SpawnLootZombieMaxGroupSize) do
				self:SpawnZombie(v:GetCenterPoint(), target, "actorloot");
			end
			self.SpawnLootZombieTimer[i]:Reset();
		end
	end
end