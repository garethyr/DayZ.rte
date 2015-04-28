-----------------------------------------------------------------------------------------
-- Manage zombie and NPC actions and behaviours
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartBehaviours()
	------------------------------
	--ZOBMIE BEHAVIOUR CONSTANTS--
	------------------------------
	self.ZombieDespawnDistance = FrameMan.PlayerScreenWidth/2 + 600; --Despawn distance for all zombies, no specific despawn distances should be less than this
	self.ZombieIdleDistance = 25; --The distance below which a zombie can stop moving towards a position target and idle
	self.ZombieMaxTargetDistance = self.ZombieSpawnMinDistance + 100;	--The distance a target needs to be within of a zombie for it to stop wandering and move at the target, setting it to less than min spawn distance may do strange things for alert zombies
	self.ZombieMaxTargetWeight = 1000; --Arbitrary max target weight for zombies, that target weights are balanced to
	
	self.ZombieTargetPriorityTable = {human = 1, alert = 2, pos = 3}; --Zombie target types in order of importance (zombies can only change to lower number targets naturally)
	self.ZombieLowestPriorityTargetType = "pos"; --The lowest priority type (i.e. the one with the highest number), must be updated manually for clearing targets to work properly
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
function ModularActivity:DoBehaviours()
	self:ManageZombieTargets();
	self:CheckForNewZombieTargets();
	self:DespawnTargetlessZombies();
end
--Check for new targets, following the target weight types
function ModularActivity:CheckForNewZombieTargets()
	for _, zombie in pairs(self.ZombieTable) do
		local origtargettype = zombie.target.ttype; --Type of original target
		local origweight = self:GetCurrentTargetWeightForZombie(zombie); --Weight of original target
		local origpriority = self.ZombieTargetPriorityTable[zombie.target.ttype] or 999; --Priority of original target
		local curtargettype, curweight, curpriority = origtargettype, origweight, origpriority; --Used for logic later
		local newtarget = false; --Gets set to the new target if the target gets changed
		
		--Get all the possible new targets
		local possibletargets = {};
		possibletargets.human = self:CheckForNearbyHumans(zombie.actor.Pos, 0, self.ZombieMaxTargetDistance) and self:NearestHuman(zombie.actor.Pos, 0, self.ZombieMaxTargetDistance) or nil;
		--If the target is not higher priority (i.e. lower number) than alerts, look for a potential alert target
		if origpriority >= self.ZombieTargetPriorityTable["alert"] and self:RequestAlerts_CheckForVisibleAlerts(zombie.actor.Pos, self.ZombieAlertAwarenessModifier, 0, self.ZombieMaxTargetDistance) then
			possibletargets.alert = self:RequestAlerts_NearestVisibleAlert(zombie.actor.Pos, self.ZombieAlertAwarenessModifier, 0, self.ZombieMaxTargetDistance);
		end
		
		--Iterate through all possible targets and get the most weighted one, as long as it's lower priority than the original target
		for targettype, priority in pairs(self.ZombieTargetPriorityTable) do
			--Make sure the target is actually possible
			if possibletargets[targettype] ~= nil then
				--Make sure the new target we're checking isn't the current target
				local notcurrenttarget = true;
				if targettype == origtargettype then
					local origpos = self:GetZombieTargetPos(zombie.target.val, origtargettype);
					local newpos = self:GetZombieTargetPos(possibletargets[targettype], targettype);
					--Note: It's fine to not worry about very close by targets since humans will move around and change and alerts should merge when closeby
					--if SceneMan:ShortestDistance(origpos, newpos, true).Magnitude < 10 then
					if origpos.X == newpos.X and origpos.Y == newpos.Y then
						notcurrenttarget = false;
					end
				end
				--If it isn't the original target, it can be checked to see if it should be used as the new target
				if notcurrenttarget then
					--Accept if its weight is higher than the current target and its priority higher than (<=) the original
					targetweight = self:GetWeightOfTargetForZombie(zombie, possibletargets[targettype], targettype);
					if targetweight > curweight and priority <= origpriority then
						curtargettype = targettype;
						curweight = targetweight;
						curpriority = priority; --Not actually used TODO Remove???
						newtarget = possibletargets[targettype] ~= nil and possibletargets[targettype] or false; --Safety check
					else
						print (string.format("Zombie at %s DID NOT change target from %s with weight %d and priority %d, to %s with weight %d and priority %d", tostring(zombie.actor.Pos), origtargettype, origweight, origpriority, targettype, targetweight, priority));
					end
				end
			end
		end
		
		--Set the zombie's target to the new target
		if newtarget ~= false then
			self:SetZombieTarget(zombie.actor, newtarget, curtargettype, zombie.spawner);
			print (string.format("Zombie at %s changed target from %s with weight %d and priority %d, to %s with weight %d and priority %d", tostring(zombie.actor.Pos), origtargettype, origweight, origpriority, curtargettype, curweight, curpriority));
		end
	end
end
--Update zombie waypoints and remove zombies if they're too far from any potential targets or too close to position targets
function ModularActivity:ManageZombieTargets()
	for _, zombie in pairs(self.ZombieTable) do
		if zombie.target.val then
			--If we have an actor target, update the startdist and, if the zombie's too far, make it lose its target completely
			if zombie.target.ttype == "human" then
				local curdist = SceneMan:ShortestDistance(zombie.target.val.Pos, zombie.actor.Pos, true).Magnitude;
				zombie.target.startdist = math.max(self.ZombieDespawnDistance, math.min(curdist, zombie.target.startdist));
				if curdist > zombie.target.startdist*1.1 then --TODO remove this magic number
					print ("Remove zombie actor target because curdist is "..tostring(curdist).." out of "..tostring(zombie.target.startdist*1.5));
					self:RemoveZombieTarget(zombie);
				end
			--If we have a position target and the zombie's close to it, lose the target so the zombie can idle
			elseif zombie.target.ttype == "pos" then
				local curdist = SceneMan:ShortestDistance(zombie.target.val.pos, zombie.actor.Pos, true).Magnitude;
				if curdist <= self.ZombieIdleDistance then
					print ("Remove zombie pos target because curdist is "..tostring(curdist).." less than "..tostring(self.ZombieIdleDistance));
					self:RemoveZombieTarget(zombie);
				end
			--If we have an alert target, update its position to account for any movement it may have, and if the zombie is close, make them wander around it
			elseif zombie.target.ttype == "alert" then
				--If the alert is a mobile type alert and currently moving, keep updating the zombie's target 
				if zombie.target.val.target ~= nil and zombie.target.val.pos ~= zombie.actor:GetLastAIWaypoint() then
					zombie.actor:ClearAIWaypoints();
					zombie.actor:AddAISceneWaypoint(SceneMan:MovePointToGround(zombie.target.val.pos, 10, 5));
				--If the alert is immobile/not moving and the zombie is close to it, make it wander around the alert position instead
				else
					local curdist = SceneMan:ShortestDistance(zombie.target.val.pos, zombie.actor.Pos, true).Magnitude;
					if curdist <= self.ZombieIdleDistance*2 then
						local offsetpos = math.random(0, self.ZombieIdleDistance);
						if zombie.actor.Pos.X > zombie.target.val.pos.X then
							offsetpos = -offsetpos;
						end
						zombie.actor:ClearAIWaypoints();
						zombie.actor:AddAISceneWaypoint(SceneMan:MovePointToGround(Vector(zombie.target.val.pos.X + offsetpos, zombie.target.val.pos.Y), 10, 5));
						print ("Zombie with alert target at "..tostring(zombie.target.val.pos).." idling around target");
					end
				end
			end
		end	
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Despawn any zombies with no target and nearby alerts or humans
function ModularActivity:DespawnTargetlessZombies()
	for k, zombie in pairs(self.ZombieTable) do
		if not zombie.target.val and not self:CheckForNearbyHumans(zombie.actor.Pos, 0, self.ZombieDespawnDistance) and not self:RequestAlerts_CheckForVisibleAlerts(zombie.actor.Pos, self.ZombieAlertAwarenessModifier) then
			print ("Kill zombie "..tostring(zombie.actor.UniqueID).." because it has no target and no nearby humans or visible alerts");
			zombie.actor.ToDelete = true;
			self:RemoveFromZombieTable(zombie.actor);
		end
	end
end
--Set a new position target with 0 weight for any zombies that are targeting the dead actor
function ModularActivity:RemoveZombieTargetsForDeadActor(ID)
	for zombieID, zombie in pairs(self.ZombieTable) do
		if zombie.target.ttype == "human" and zombie.target.val.UniqueID == ID then
			self:ClearZombieTarget(zombie, zombie.actor:GetLastAIWaypoint());
			print (string.format("Zombie at %s with HUMAN target of %d given 0 strength position target at %s", (zombie.actor.Pos), ID, tostring(zombie.actor:GetLastAIWaypoint())));
		end
	end
end
--Set a new position target with 0 weight for any zombies that are targeting the dead alert
function ModularActivity:RemoveZombieTargetsForDeadAlert(alert)
	for zombieID, zombie in pairs(self.ZombieTable) do
		if zombie.target.ttype == "alert" and zombie.target.val.pos == alert.pos then
			self:ClearZombieTarget(zombie, zombie.actor:GetLastAIWaypoint());
			print (string.format("Zombie at %s with ALERT target of at pos %s given 0 strength position target at %s", tostring(zombie.actor.Pos), alert.pos, tostring(zombie.actor:GetLastAIWaypoint())));
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Set the alert as the target for any zombies whose current target has lower weight, priority is completely ignored
function ModularActivity:ManageZombieBehaviourForNewAlert(alert)
	-- print ("managing zombie behaviours for new alert")
	-- ConsoleMan:SaveAllText("output")
	for _, zombie in pairs(self.ZombieTable) do
		-- print ("zombie table actor is "..tostring(zombie.actor).." with id "..tostring(zombie.actor.UniqueID).." and an "..zombie.target.ttype.." target");
	-- ConsoleMan:SaveAllText("output")
		local curweight = self:GetCurrentTargetWeightForZombie(zombie);
		-- print("current target weight is "..tostring(curweight));
	-- ConsoleMan:SaveAllText("output")
		local alertweight = self:GetWeightOfTargetForZombie(zombie, alert, "alert");
		-- print("alert target weight is "..tostring(alertweight));
	-- ConsoleMan:SaveAllText("output")
		if alertweight > curweight then
			print (string.format("NEW ALERT caused zombie at %s to change target from %s with weight %d, to %s with weight %d", zombie.actor.Pos, zombie.target.ttype, curweight, "alert", alertweight));
			-- ConsoleMan:SaveAllText("output")
			self:SetZombieTarget(zombie.actor, alert, "alert", zombie.spawner);
		end
	end
end
--Return the weight of the zombie's current target
function ModularActivity:GetCurrentTargetWeightForZombie(zombie)
	--print ("Getting weight of current target for zombie at "..tostring(zombie.actor.Pos));
	if zombie.target.ttype == "pos" then
		return zombie.target.val.weight;
	else
		return self:GetWeightOfTargetForZombie(zombie, zombie.target.val, zombie.target.ttype);
	end
end
--Return the weight of the inputted target (given target type) for the zombie
function ModularActivity:GetWeightOfTargetForZombie(zombie, target, targettype)
	local pos = zombie.actor.Pos;
	local dist, weight = 0, 0;
	--print ("Checking weight of target for zombie, for target "..tostring(target));
	--Note that the weight of any target is 0 at or beyond max target distance, and can't be larger than max target weight
	if target ~= nil and target ~= false  then
		--Human target weight is based entirely on distance
		if targettype == "human" then
			dist = SceneMan:ShortestDistance(pos, target.Pos, true).Magnitude;
			weight = math.max(0, self.ZombieMaxTargetWeight*(self.ZombieMaxTargetDistance - dist)/self.ZombieMaxTargetDistance);
			--print ("Weight for ACTOR target with distance "..tostring(dist).." = "..tostring(weight));
		--Alert target weight is based on the overall zombie awareness modifier and the strength of the alert (compared to the overall base alert strength)
		elseif targettype == "alert" then
			local alertcoefficient = self.ZombieAlertAwarenessModifier*self:RequestAlerts_GetAlertCurrentStrength(target)/self:RequestAlerts_GetBaseAlertStrength();
			dist = SceneMan:ShortestDistance(pos, target.pos, true).Magnitude;
			weight = math.max(0, self.ZombieMaxTargetWeight*alertcoefficient*(self.ZombieMaxTargetDistance - dist)/self.ZombieMaxTargetDistance);
			--print ("Weight for ALERT target with distance "..tostring(dist).." and coefficient "..tostring(alertcoefficient).." = "..tostring(weight));
		--NOTE: Should not have a pos target passed into this method, but it is handled and warned about for safety
		elseif targettype == "pos" then
			print ("WARNING: Position target passed into function GetWeightOfTargetForZombie - This shouldn't happen")
			weight = target.weight ~= nil and target.weight or 0;
		end
	end
	return math.min(weight, self.ZombieMaxTargetWeight); --Make sure weight isn't over max weight
end
--Set the zombie's target as lowest priority target type with weight 0
function ModularActivity:ClearZombieTarget(zombie, pos)
	self:SetZombieTarget(zombie.actor, {pos = pos, weight = 0}, self.ZombieLowestPriorityTargetType, zombie.spawner);
	print ("Cleared zombie target, zombie table target entry is now "..tostring(self.ZombieTable[zombie.actor.UniqueID].target.val.pos));
end

--VVVVVVVVVVVVVVVVVVVVVVVVV--
--THE FOLLOWING IS NOT USED--
--VVVVVVVVVVVVVVVVVVVVVVVVV--

-----------------------------------------------------------------------------------------
-- A convenient function for finding the closest target, also returns
-----------------------------------------------------------------------------------------
local oldModularActivity = ModularActivity;
function oldModularActivity:FindTarget(start, bool, hasactorbool) --TODO change this so it takes a number as its last value, allowing you to change the range to check for actors
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
function oldModularActivity:DoZombieActions()
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