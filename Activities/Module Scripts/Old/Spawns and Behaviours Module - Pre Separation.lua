-----------------------------------------------------------------------------------------
-- Functions for the spawn queue, which keeps us from spawning too many MOs at once
-----------------------------------------------------------------------------------------
function Chernarus:StartSpawnsAndBehaviours()
	--A queue and timer for all spawns, to avoid crashes trying to add too many MOS to the scene at once
	self.SpawnQueue = {};
	self.SpawnQueueTimer = Timer();
end
function Chernarus:AddToSpawnQueue(actor, ttype, emergency)
	self.SpawnQueue[#self.SpawnQueue+1] = {actor, ttype, emergency};
end
function Chernarus:RunSpawnQueue()
	if #self.SpawnQueue > 0 and MovableMan:GetMOIDCount() <= self.MOIDLimit then
		if self.SpawnQueueTimer:IsPastSimMS(100) then
			local q = self.SpawnQueue[1];
			table.remove(self.SpawnQueue, 1);
			MovableMan:AddActor(q[1]);
			print ("Spawned");
			if q[2] == "p" then
				self:AddToPlayerTable(q[1]);
			elseif q[2] == "n" then
				self:AddToNPCTable(q[1]);
			elseif q[2] == "z" then
				self:AddToZombieTable(q[1], q[3]);
			else
				print ("NO TABLE TYPE SPECIFIED FOR SPAWNING FROM QUEUE");
			end
			self.SpawnQueueTimer:Reset();
		end
	end
end
-----------------------------------------------------------------------------------------
-- A convenient function for finding the closest target, also returns
-----------------------------------------------------------------------------------------
function Chernarus:FindTarget(start, bool, hasactorbool) --TODO change this so it takes a number as its last value, allowing you to change the range to check for actors
	--Check through players, NPCs and alerts (if bool == true) to find a target
	local target = nil; --Pick a distant point as the initial target
	local tmod = nil; --Used to make alert strength affect whether or not it counts as a target in the end
	local hasactors = nil; --Used to despawn zombies if there are no actors near to them. Integrated into find target for convenience
	if hasactorbool == true then --Only set to be checked if the second boolean value is true, since not everything should bother checking it
		hasactors = false;
	end
	--Check through players
	if start ~= nil then
		if #self.PlayerTable > 0 then
			for i = 1, #self.PlayerTable do
				if SameHeightArea(start, self.PlayerTable[i][1].Pos) == true then
					if target == nil then
						target = self.PlayerTable[i][1].Pos;
					else
						if SceneMan:ShortestDistance(self.PlayerTable[i][1].Pos, start, false).Magnitude < SceneMan:ShortestDistance(target, start, false).Magnitude then
							target = self.PlayerTable[i][1].Pos;
						end
					end
					--Check if the actor is within the zombie despawn distance
					if hasactors == false then
						if SceneMan:ShortestDistance(self.PlayerTable[i][1].Pos, start, false).Magnitude <= self.ZombieDespawnDistance then
							hasactors = true;
						end
					end
				end
			end
		end
		--Check through NPCs
		if #self.NPCTable > 0 then
			for i = 1, #self.NPCTable do
				if SameHeightArea(start, self.NPCTable[i][1].Pos) == true then
					if target == nil then
						target = self.NPCTable[i][1].Pos;
					else
						if SceneMan:ShortestDistance(self.NPCTable[i][1].Pos, start, false).Magnitude < SceneMan:ShortestDistance(target, start, false).Magnitude then
							target = self.NPCTable[i][1].Pos;
						end
					end
					--Check if the actor is within the zombie despawn distance, no need to check if we've already found it true, save a bit of expense
					if hasactors == false then
						if SceneMan:ShortestDistance(self.NPCTable[i][1].Pos, start, false).Magnitude <= self.ZombieDespawnDistance then
							hasactors = true;
						end
					end
				end
			end
		end
		--Check through Alerts
		if #self.AlertTable > 0 and bool == true then
			for i = 1, #self.AlertTable do
				if SameHeightArea(start, self.AlertTable[i][1]) == true then
					if target == nil then
						target = self.AlertTable[i][1];
					else
						--Try to prioritize actor targets over alerts, unless the alerts are very strong. So we give alerts a negative handicap set below, then add to that based on its strength
						local alerthandicap = 1000;
						if SceneMan:ShortestDistance(self.AlertTable[i][1], start, false).Magnitude < SceneMan:ShortestDistance(target, start, false).Magnitude - alerthandicap + self.AlertPriorityFactor*math.ceil(self.AlertTable[i][3]/1000) then
							target = self.AlertTable[i][1];
							tmod = self.AlertTable[i][3]/self.AlertBaseStrength; --The modifier for zombie attacks, based on the alert strength over the base alert strength
						end
					end
				end
			end
		end
	else
		print ("NO START FOR TARGET FINDING FUNCTION");
	end
	return target, tmod, hasactors;
end
-----------------------------------------------------------------------------------------
-- A convenient function for comparing height areas of two points (i.e. in tunnels or above ground)
-----------------------------------------------------------------------------------------
function SameHeightArea(p1, p2)
	--Returns true if both points are in the same height area and false otherwise
	local h = 560; --The height to check
	if (p1.Y >= h and p2.Y >= h) or (p1.Y < h and p2.Y < h) then
		return true;
	else
		return false;
	end
end
-----------------------------------------------------------------------------------------
-- Everything for Zombies
-----------------------------------------------------------------------------------------
--The actual zombie spawning
function Chernarus:SpawnZombies(point)
	local target = self:FindTarget(point, false, false);
	if target ~= nil then
		for i = 1, 3 do
			if MovableMan:GetMOIDCount() <= self.MOIDLimit then
				local actor = CreateAHuman("Zombie 1", "DayZ.rte");
				actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", "DayZ.rte"));
				actor.Pos = Vector(point.X - 60 + 30*i + math.random(-10, 10), point.Y);
				actor.Team = self.ZombieTeam;
				actor:AddAISceneWaypoint(Vector(actor.Pos.X - (actor.Pos.X - target.X)/4 + math.random(-50, 50), actor.Pos.Y));
				actor.AIMode = Actor.AIMODE_GOTO;
				self:AddToSpawnQueue(actor, "z", false);
			end
		end
	end
end
--Emergency zombie spawns, called by other things with the target already chosen
function Chernarus:SpawnAlertZombie(alertpos)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit then
		local actor = CreateAHuman("Zombie 1", "DayZ.rte");
		actor:AddInventoryItem(CreateHDFirearm("Zombie Attack", "DayZ.rte"));
		actor.Pos = Vector(alertpos.X - self.ZombieSpawnMinDistance + math.random(-20, 20), alertpos.Y);--SceneMan.MovePointToGround(Vector(alertpos.X - self.ZombieSpawnMinDistance + math.random(-20, 20), alertpos.Y), 20, 20);
		actor.Team = self.ZombieTeam;
		actor:AddAISceneWaypoint(alertpos);
		actor.AIMode = Actor.AIMODE_GOTO;
		self:AddToSpawnQueue(actor, "z", alert);
	end
end
--Pick where to spawn the zombies based on player position
function Chernarus:DoZombieSpawning()
	for i = 1, #self.SpawnArea do
		--Find the nearest target to check if we should spawn zombies
		local target, tmod = self:FindTarget(self.SpawnArea[i]:GetCenterPoint(), false, false);
		local maxdist = self.ZombieSpawnMaxDistance;
		local mindist = self.ZombieSpawnMinDistance;
		--If there's an alert strength modifier, use it and make sure it still does something
		if tmod ~= nil then
			maxdist = maxdist*tmod;
			if maxdist < 50 then
				maxdist = 50;
			end
			mindist = mindist - 500*tmod;
		end
		--Spawn zombies to go to target
		if target ~= nil then
			if SceneMan:ShortestDistance(target, self.SpawnArea[i]:GetCenterPoint(), false).Magnitude <= maxdist and SceneMan:ShortestDistance(target, self.SpawnArea[i]:GetCenterPoint(), false).Magnitude >= mindist and self.ZombieSpawnTimer[i]:IsPastSimMS(self.ZombieSpawnInterval) then
				for j = 1, math.random(1,2) do
					self:SpawnZombies(self.SpawnArea[i]:GetCenterPoint());
				end
				print ("ZOMBIES QUEUED FOR AREA "..tostring(i));
				self.ZombieSpawnTimer[i]:Reset();
				break;
			end
		end
	end
end
--Zombie actions - follow player when close and move around randomly when not
function Chernarus:DoZombieActions()
	if #self.ZombieTable > 0 then
		--Go through all zombies
		for i = 1, #self.ZombieTable do
			if self.ZombieTable[i] ~= nil and MovableMan:IsActor(self.ZombieTable[i][1]) then
				local z = self.ZombieTable[i][1];
				if MovableMan:IsActor(z) then
					z:GetController():SetState(Controller.BODY_CROUCH, false);
					z:GetController():SetState(Controller.WEAPON_PICKUP, false);
					z:GetController():SetState(Controller.BODY_JUMPSTART, false);
					z:GetController():SetState(Controller.BODY_JUMP, false);
					
					--Find the nearest target and the alert strength modifier if there is one
					local target, tmod, hasactors = self:FindTarget(z.Pos, true, true); --Second boolean is to check for any actors nearby for despawning
					local dist = self.ZombieAlertDistance;
					--If there's an alert strength modifier, use it and make sure it still does something
					if tmod ~= nil then
						dist = self.ZombieAlertDistance*tmod;
						if dist < 50 then
							dist = 50;
						end
					end
					--Make zombies attack targets, if they have a target, it's within the attack distance and they're not already attacking it
					if target ~= nil then
						if SceneMan:ShortestDistance(target, z.Pos, false).Magnitude < dist then
							if z.AIMode == Actor.AIMODE_SENTRY or (z.AIMode == Actor.AIMODE_GOTO and (z:GetLastAIWaypoint() - target).Magnitude > 20) then
								z:ClearAIWaypoints();
								z.AIMode = Actor.AIMODE_SENTRY;
								--If they're close to target and it's an, wander a bit, otherwise charge at target
								local close = false
								if tmod ~= nil then
									if SceneMan:ShortestDistance(z.Pos, target, false).Magnitude < 50 then
										close = true
									end
								end
								if close == true then
									z:AddAISceneWaypoint(Vector(target.X + math.random(-20, 20), target.Y));
									print ("WANDER AROUND TARGET");
								else
									z:AddAISceneWaypoint(target);
									print ("CHARGE AT PLAYER");
								end
								
							end
						else
							--Clear waypoints once if the zombie's far from the target
							if z:GetLastAIWaypoint() == target then
								z:ClearAIWaypoints();
								z.AIMode = Actor.AIMODE_SENTRY;
							end
						end
						--Make the zombies move around randomly
						if z.AIMode == Actor.AIMODE_SENTRY then
							z:ClearAIWaypoints();
							z.AIMode = Actor.AIMODE_SENTRY;
							local rand = math.random(-100, 100);
							z:AddAISceneWaypoint(SceneMan:MovePointToGround(Vector(z.Pos.X + rand, z.Pos.Y), z.Height/2, 2));
							z.AIMode = Actor.AIMODE_GOTO;
							print ("WANDER");
						end
						--Clean up any no longer existing alert targets
						if self.ZombieTable[i][2] ~= false and (self.ZombieTable[i][2] == nil or self.ZombieTable[i][2][3] <= 0) then
							self.ZombieTable[i][2] = false;
						end
						--Remove distant zombies if they're not on a target or they're far from their target)
						if hasactors == false and (self.ZombieTable[i][2] == false or (self.ZombieTable[i][2] ~= false and SceneMan:ShortestDistance(z.Pos, self.ZombieTable[i][2][1], false).Magnitude > self.ZombieDespawnDistance)) then
							local actor = z;
							table.remove(self.ZombieTable, i);
							actor.ToDelete = true;
							print ("REMOVE ZOMBIE FOR DISTANCE: "..tostring(i));
						end
					end
				end
			end
		end
	end
end