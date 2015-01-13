-----------------------------------------------------------------------------------------
-- Manage zombie and NPC actions and behaviours
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Use FOW to fake night
-----------------------------------------------------------------------------------------
--Setup
function DayZActivity:StartBehaviours()
	------------------------------
	--ZOBMIE BEHAVIOUR CONSTANTS--
	------------------------------
	self.ZombieDespawnDistance = FrameMan.PlayerScreenWidth/2 + 600; --Despawn distance for all zombies, no specific despawn distances should be less than this
	self.ZombieIdleDistance = 25; --The distance below which a zombie can stop moving towards a position target and idle
	
	---------------------------
	--NPC BEHAVIOUR CONSTANTS--
	---------------------------
end
--------------------
--CREATE FUNCTIONS--
--------------------
--------------------
--UPDATE FUNCTIONS--
--------------------
function DayZActivity:DoBehaviours()
	self:ManageZombieTargets();
	self:DespawnZombies();
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Despawn any zombies with no target and nearby alerts or humans
function DayZActivity:DespawnZombies()
	for k, zombie in pairs(self.ZombieTable) do
		if not zombie.target.val and not self:CheckForNearbyHumans(zombie.actor.Pos, 0, self.ZombieDespawnDistance) and not self:RequestAlerts_CheckForVisibleAlerts(zombie.actor.Pos, self.ZombieAlertAwarenessModifier) then
			print ("Kill zombie "..tostring(zombie.actor.UniqueID).." because it has no target and no nearby humans or visible alerts");
			zombie.actor.ToDelete = true;
			self.ZombieTable[k] = nil;
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--
function DayZActivity:ManageZombieTargets()
	for _, zombie in pairs(self.ZombieTable) do
		if zombie.target.val then
			--If we have an actor target, update the startdist and, if the zombie's too far, make it lose its target completely
			if zombie.target.ttype == "actor" then
				local curdist = SceneMan:ShortestDistance(zombie.target.val.Pos, zombie.actor.Pos, true).Magnitude;
				zombie.target.startdist = math.max(self.ZombieDespawnDistance, math.min(curdist, zombie.target.startdist));
				if curdist > zombie.target.startdist*1.1 then
					print ("Remove zombie actor target because curdist is "..tostring(curdist).." out of "..tostring(zombie.target.startdist*1.5));
					zombie.target = {val = false, ttype = "", startdist = 0};
				end
			--If we have a position target and the zombie's close to it, lose the target so the zombie can idle
			elseif zombie.target.ttype == "pos" then
				local curdist = SceneMan:ShortestDistance(zombie.target.val, zombie.actor.Pos, true).Magnitude;
				if curdist <= self.ZombieIdleDistance then
					print ("Remove zombie pos target because curdist is "..tostring(curdist).." less than "..tostring(self.ZombieIdleDistance));
					zombie.target.val = false;
				end
			--If we have an alert target, update its position to account for any movement it may have
			elseif zombie.target.ttype == "alert" then
				zombie.actor:ClearAIWaypoints();
				ToAHuman(zombie.actor):AddAISceneWaypoint(zombie.target.val.pos);
			end
		end	
	end
end
-----------------------------------------------------------------------------------------
-- A convenient function for finding the closest target, also returns
-----------------------------------------------------------------------------------------
function DayZActivity:FindTarget(start, bool, hasactorbool) --TODO change this so it takes a number as its last value, allowing you to change the range to check for actors
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
--Zombie actions - follow player when close and move around randomly when not
function DayZActivity:DoZombieActions()
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