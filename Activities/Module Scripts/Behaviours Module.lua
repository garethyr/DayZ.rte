-----------------------------------------------------------------------------------------
-- Manage zombie and NPC actions and behaviours
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartBehaviours()
	------------------------------
	--ZOBMIE BEHAVIOUR CONSTANTS--
	------------------------------
	self.ZombieDespawnDistance = FrameMan.PlayerScreenWidth/2 + 600; --Despawn distance for all zombies, no specific despawn distances should be less than this
	self.ZombieIdleDistance = 50; --The distance below which a zombie can stop moving towards a position target and idle
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
		--If there are visible alerts, check if they can be used
		if self:RequestAlerts_CheckForVisibleAlerts(zombie.actor.Pos, self.ZombieAlertAwarenessModifier, 0, self.ZombieMaxTargetDistance) then
			--Determine whether all alerts can be used or only those that are set to override target priority
			local usealert = (origpriority >= self.ZombieTargetPriorityTable["alert"]) and true or false;
			local alert = nil;
			--If all alerts can be used, use the closest
			if usealert then
				alert = self:RequestAlerts_NearestVisibleAlert(zombie.actor.Pos, self.ZombieAlertAwarenessModifier, 0, self.ZombieMaxTargetDistance);
			--Otherwise find all visible alerts, and if one's set to override, use that
			else
				local visiblealerts = self:RequestAlerts_AllVisibleAlerts(zombie.actor.Pos, self.ZombieAlertAwarenessModifier, 0, self.ZombieMaxTargetDistance);
				for _, visiblealert in pairs(visiblealerts) do
					local alertparents = self:RequestAlerts_GetAlertParents(visiblealert);
					for _, parent in pairs(alertparents) do
						--TODO This should probably use the closest alert instead of the first overriding one it finds, maybe AllVisibleAlerts should sort them in order or should have a parameter to allow for sorting?
						if ToMOSRotating(parent):NumberValueExists("OverrideTargetPriority") and ToMOSRotating(parent):GetNumberValue("OverrideTargetPriority") == 1 then
							alert = visiblealert;
							usealert = true;
							break;
						end
					end
					if usealert then
						break;
					end
				end
			end
			possibletargets.alert = alert;
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
					if origpos.X == newpos.X and origpos.Y == newpos.Y then
						notcurrenttarget = false;
					end
				end
				--If it isn't the original target, it can be checked to see if it should be used as the new target
				if notcurrenttarget then
					--Accept if its weight is higher than the current target and its priority higher than (<=) the original
					targetweight = self:GetWeightOfTargetForZombie(zombie, possibletargets[targettype], targettype);
					if targetweight > curweight then
						curtargettype = targettype;
						curweight = targetweight;
						curpriority = priority; --Not actually used TODO Remove???
						newtarget = possibletargets[targettype] ~= nil and possibletargets[targettype] or false; --Safety check
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
				local curdist = SceneMan:ShortestDistance(zombie.target.val.Pos, zombie.actor.Pos, self.Wrap).Magnitude;
				zombie.target.startdist = math.max(self.ZombieDespawnDistance, math.min(curdist, zombie.target.startdist));
				if curdist > zombie.target.startdist*1.1 then --TODO remove this magic number
					print ("Remove zombie actor target because curdist is "..tostring(curdist).." out of "..tostring(zombie.target.startdist*1.5));
					self:RemoveZombieTarget(zombie);
				end
			--If we have a position target and the zombie's close to it, lose the target so the zombie can idle
			elseif zombie.target.ttype == "pos" then
				if not self:CheckForNearbyHumans(zombie.actor.Pos, 0, self.ZombieDespawnDistance) then
					local curdist = SceneMan:ShortestDistance(zombie.target.val.pos, zombie.actor.Pos, self.Wrap).Magnitude;
					if zombie.target.val.weight == 0 or curdist <= self.ZombieIdleDistance then
					
						--TODO printing delete
						local noweight = zombie.target.val.weight == 0;
						local closedist = curdist <= self.ZombieIdleDistance;
						local str = "Remove zombie pos target because no humans within "..tostring(self.ZombieDespawnDistance).." and ";
						str = str..(noweight and "weight is 0 " or "");
						str = str..(closedist and "curdist "..tostring(curdist).." is less than "..tostring(self.ZombieIdleDistance) or "");
						print (str);
						
						self:RemoveZombieTarget(zombie);
					end
				end
			--If we have an alert target, update its position to account for any movement it may have, and if the zombie is close, make them wander around it
			elseif zombie.target.ttype == "alert" then
				--If the alert is a mobile type alert and currently moving, keep updating the zombie's target 
				if zombie.target.val.target ~= nil and zombie.target.val.pos ~= zombie.actor:GetLastAIWaypoint() then
					zombie.actor:ClearAIWaypoints();
					zombie.actor:AddAISceneWaypoint(SceneMan:MovePointToGround(zombie.target.val.pos, 10, 5));
				--If the alert is immobile/not moving and the zombie is close to it, make it wander around the alert position instead
				else
					local curdist = SceneMan:ShortestDistance(zombie.target.val.pos, zombie.actor.Pos, self.Wrap).Magnitude;
					if curdist <= self.ZombieIdleDistance*2 then
						local offsetpos = math.random(0, self.ZombieIdleDistance);
						if zombie.actor.Pos.X > zombie.target.val.pos.X then
							offsetpos = -offsetpos;
						end
						zombie.actor:ClearAIWaypoints();
						zombie.actor:AddAISceneWaypoint(SceneMan:MovePointToGround(Vector(zombie.target.val.pos.X + offsetpos, zombie.target.val.pos.Y), 10, 5));
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
		end
	end
end
--Set a new position target with 0 weight for any zombies that are targeting the dead alert
function ModularActivity:RemoveZombieTargetsForDeadAlert(alert)
	for zombieID, zombie in pairs(self.ZombieTable) do
		if zombie.target.ttype == "alert" and zombie.target.val.pos == alert.pos then
			self:ClearZombieTarget(zombie, zombie.actor:GetLastAIWaypoint());
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Set the alert as the target for any zombies whose current target has lower weight, priority is completely ignored. Note that this method is done once when the alert is made, repeated override built into the regular targeting checks
function ModularActivity:ManageZombieOneTimeBehaviourForNewAlert(alert)
	for _, zombie in pairs(self.ZombieTable) do
		local curweight = self:GetCurrentTargetWeightForZombie(zombie);
		local alertweight = self:GetWeightOfTargetForZombie(zombie, alert, "alert");
		if alertweight > curweight then
			print (string.format("NEW ALERT caused zombie at %s to change target from %s with weight %d, to %s with weight %d", zombie.actor.Pos, zombie.target.ttype, curweight, "alert", alertweight));
			self:SetZombieTarget(zombie.actor, alert, "alert", zombie.spawner);
		end
	end
end
--Return the weight of the zombie's current target
function ModularActivity:GetCurrentTargetWeightForZombie(zombie)
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
	--Note that the weight of any target is 0 at or beyond max target distance, and can't be larger than max target weight
	if target ~= nil and target ~= false  then
		--Human target weight is based entirely on distance
		if targettype == "human" then
			dist = SceneMan:ShortestDistance(pos, target.Pos, self.Wrap).Magnitude;
			weight = math.max(0, self.ZombieMaxTargetWeight*(self.ZombieMaxTargetDistance - dist)/self.ZombieMaxTargetDistance);
			--print ("Weight for ACTOR target with distance "..tostring(dist).." = "..tostring(weight));
		--Alert target weight is based on the overall zombie awareness modifier and the strength of the alert (compared to the overall base alert strength)
		elseif targettype == "alert" then
			local alertcoefficient = self.ZombieAlertAwarenessModifier*self:RequestAlerts_GetAlertCurrentStrength(target)/self:RequestAlerts_GetBaseAlertStrength();
			dist = SceneMan:ShortestDistance(pos, target.pos, self.Wrap).Magnitude;
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
	print ("Cleared zombie target, zombie at "..tostring(zombie.actor.Pos).." with old "..zombie.target.ttype.." target now has 0 strength position target at "..tostring(pos));
	self:SetZombieTarget(zombie.actor, {pos = pos, weight = 0}, self.ZombieLowestPriorityTargetType, zombie.spawner);
end


--Shows objective arrows for zombies so their targets are clearly visible
function ModularActivity:DoDebugTargetDisplayForZombies()
	for _, zombie in pairs(self.ZombieTable) do
		local targetpos = self:GetZombieTargetPos(zombie.target.val, zombie.target.ttype);
		local st = targetpos == 0 and "Zombie has no target" or "Zombie has "..tostring(zombie.target.ttype).." target with weight "..tostring(self:GetCurrentTargetWeightForZombie(zombie, zombie.target.val, zombie.target.ttype));
		st = st.."\nPos: "..tostring(self:GetZombieTargetPos(zombie.target.val, zombie.target.ttype));
		if zombie.target.ttype == "alert" then
			local alert = zombie.target.val;
			st = st.."\nAlert Target: "..tostring(alert.target)..(alert.light.parent == nil and "" or ("\nAlert Light Parent: "..tostring(alert.light.parent)))..(alert.sound.parent == nil and "" or ("\nAlert Sound Parent: "..tostring(alert.sound.parent)))
		end
		local arrow = GameActivity.ARROWDOWN;
		if targetpos ~= 0 then
			local dist = SceneMan:ShortestDistance(zombie.actor.Pos, targetpos, self.Wrap).X;
			arrow = dist < 0 and GameActivity.ARROWLEFT or (dist > 0 and GameActivity.ARROWRIGHT or arrow);
		end
		self:AddObjectivePoint(st, zombie.actor.AboveHUDPos - Vector(0, 50), self.PlayerTeam, arrow);
	end
end