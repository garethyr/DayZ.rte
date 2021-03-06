-----------------------------------------------------------------------------------------
-- NECESSARY MODULE: Communication Module, lets modules talk to each other
-----------------------------------------------------------------------------------------
------------
--REQUESTS--
------------
function ModularActivity:____REQUESTS____() end --Used for organization of notepad++ function list
function ModularActivity:RequestSustenance_AddToSustenanceTable(actor)
	if self.IncludeSustenance then
		self:AddToSustenanceTable(actor);
	end
end
function ModularActivity:RequestSustenance_GetSustenanceValuesForID(ID)
	local tab = {};
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		for _, susttype in pairs(self.SustTypes) do
			tab[susttype] = self.SustTable[ID][susttype];
		end
	end
	return tab;
end
function ModularActivity:RequestDayNight_GetCurrentStateAndTime()
	if self.IncludeDayNight then
		return {cstate = self.DayNightIsNight, ctime = self.DayNightTimer.ElapsedSimTimeMS};
	end
end
function ModularActivity:RequestIcons_AddToMeterTable(actor)
	if self.IncludeIcons then
		print ("Adding "..tostring(actor).." with UniqueID "..tostring(actor.UniqueID).." to meter table");
		self:AddToMeterTable(actor);
	end
end
function ModularActivity:RequestIcons_RemoveAllMeters()
	if self.IncludeIcons then
		self.MeterTable = {};
	end
end
function ModularActivity:RequestAlerts_GetAlertParents(alert)
	if self.IncludeAlerts then
		return self:GetAlertParents(alert);
	end
	return {};
end
function ModularActivity:RequestAlerts_GetAlertCurrentStrength(alert)
	if self.IncludeAlerts then
		return alert.strength;
	end
	return 0;
end
function ModularActivity:RequestAlerts_GetBaseAlertStrength()
	if self.IncludeAlerts then
		return self.AlertBaseStrength;
	end
	return 0;
end
function ModularActivity:RequestAlerts_CheckForVisibleAlerts(pos, awarenessmod, ...) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:CheckForVisibleAlerts(pos, awarenessmod, select(1, ...));
	end
	return false;
end
function ModularActivity:RequestAlerts_NearestVisibleAlert(pos, awarenessmod, ...) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:NearestVisibleAlert(pos, awarenessmod, select(1, ...));
	end
	return nil;
end
function ModularActivity:RequestAlerts_AllVisibleAlerts(pos, awarenessmod, ...) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:AllVisibleAlerts(pos, awarenessmod, select(1, ...));
	end
	return {};
end
--Loot

--Sustenance

--Spawns

--DayNight

--Flashlight

--Icons
function ModularActivity:IconsRequestAlerts_ActorActivityPercent(atype, actor)
	if self.IncludeAlerts then
		if self.AlertTable[actor.UniqueID] ~= nil and self.AlertTable[actor.UniqueID][atype].strength > 0 then
			return 1;
		elseif self.HumanTable.Players[actor.UniqueID] ~= nil then
			return self.HumanTable.Players[actor.UniqueID].activity[atype].total/self.ActorActivityToAlertValue;
		end
	end
	return 0;
end
function ModularActivity:IconsRequestSustenance_ActorSustenancePercent(susttype, actor)
	if self.IncludeSustenance then
		if self.SustTable[actor.UniqueID] ~= nil then
			return (self.MaxSust[susttype] - math.min(self.MaxSust[susttype], self.SustTable[actor.UniqueID][susttype]))/self.MaxSust[susttype];
		end
	end
	return 0;
end

--Behaviours

--Audio
function ModularActivity:AudioRequestDayNight_DayOrNightOrEmptyFormattedString()
	if self.IncludeDayNight and self.IsOutside then
		return self.DayNightIsNight and " Night" or " Day";
	else
		if self.IsOutside then
			return " Day";
		else
			return "";
		end
	end
end

--Alerts
function ModularActivity:AlertsRequestSpawns_GetZombieMinSpawnDistance()
	if self.IncludeSpawns then
		return self.ZombieSpawnMinDistance;
	end
end
function ModularActivity:AlertsRequestSpawns_GetZombieSpawnInterval()
	if self.IncludeSpawns then
		return self.ZombieSpawnInterval;
	end
	return 0;
end
function ModularActivity:AlertsRequestSpawns_SpawnAlertZombie(alert, offset)
	if self.IncludeSpawns and self.SpawnAlertZombies then
		return self:SpawnZombie(offset, alert, "alert", alert); --args: (spawnpos, target, targettype, spawner), offset used instead of position for alerts
	end
	return false;
end
function ModularActivity:AlertsRequestDayNight_LightItemNotInTable(item)
	if self.IncludeDayNight then
		return self.DayNightLightItemTable[item.UniqueID] == nil;
	end
	return false;
end

-----------------
--NOTIFICATIONS--
-----------------
function ModularActivity:____NOTIFICATIONS____() end --Used for organization of notepad++ function list
--Main
function ModularActivity:NotifyMany_DeadHuman(humantype, player, ID, alert)
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		self:RemoveFromSustTable(ID);
	end
	if self.IncludeIcons and self.MeterTable[ID] ~= nil then
		self:IconsRemoveMeters(ID);
	end
	if self.IncludeBehaviours then
		self:RemoveZombieTargetsForDeadActor(ID);
	end
	if self.IncludeAlerts and alert ~= false then
		self:MoveAlertFromDeadActor(alert);
	end
	if humantype == "Players" then
		print ("humantype for "..tostring(ID).." is "..tostring(humantype));
		self:AddPlayerToRespawnTable(self:CreateNewPlayerActor(player), player);
	end
end
function ModularActivity:NotifySust_SetActorSust(ID, newsust)
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		for _, susttype in pairs(self.SustTypes) do
			self.SustTable[ID][susttype] = newsust[susttype];
		end
	end
end
function ModularActivity:NotifyDayNight_SceneTransitionOccurred(isnight, currenttime)
	if self.IncludeDayNight then
		if isnight ~= nil and currenttime ~= nil then
			self.DayNightIsNight = isnight;
			self.DayNightTimer.ElapsedSimTimeMS = currenttime;
		end
		self:DoDayNightChangeActions();
		self:DayNightResetBackgroundPosition();
	end
end
function ModularActivity:NotifyAlerts_UpdateDisabledAlertTypes()
	if self.IncludeAlerts then
		self:UpdateDisabledAlertTypes();
	end
end

--Loot

--Sustenance

--Spawns

--DayNight
function ModularActivity:DayNightNotifyMany_DayNightCycle()
	if self.IncludeAlerts then
		self:NotifyAlerts_UpdateDisabledAlertTypes();
	end
	if self.IncludeAudio then
		local soundtype = self.DayNightIsNight and "night" or "day";
		self:AudioChangeGlobalSound(soundtype);
	end
	--Every morning, increment the nights survived count
	if self.DayNightIsNight == false then
		self.NightsSurvived = self.NightsSurvived + 1;
	end
end

--Flashlight

--Icons
function ModularActivity:IconsNotifyDayNight_RevealIcons(corner)
	if self.IncludeDayNight then
		local box = Box(corner, Vector(corner.X + self.IconsMeterSpacing*(self.IconsNumMeters+1), corner.Y + self.IconsMeterSpacing));
		table.insert(self.DayNightExtraRevealBoxes, box);
	end
end

--Behaviours

--Audio

--Alerts
function ModularActivity:AlertsNotifyMany_NewAlertAdded(alert)
	if alert.target ~= nil then
		for _, humantable in pairs(self.HumanTable) do
			if humantable[alert.target.UniqueID] ~= nil then
				humantable[alert.target.UniqueID].alert = alert;
				break;
			end
		end
	end
	--This is done once for targetless alerts but is repeated multiple times elsewhere for targetted alerts like light items
	if self.IncludeBehaviours then
		self:ManageZombieOneTimeBehaviourForNewAlert(alert);
	end
end
function ModularActivity:AlertsNotifyDayNight_LightEmittingItemAdded(item)
	if self.IncludeDayNight then
		self:AddDayNightLightItem(item)
	end
end
function ModularActivity:AlertsNotifyMany_DeadAlert(alert)
	--If the target is an actor, remove the alert from its humantable entry
	if alert.target ~= nil then
		for _, humantable in pairs(self.HumanTable) do
			if humantable[alert.target.UniqueID] ~= nil then
				humantable[alert.target.UniqueID].alert = false;
			end
		end
	end
	if self.IncludeBehaviours then
		--Clear the target for any zombies that have this alert as a target
		self:RemoveZombieTargetsForDeadAlert(alert);
	end
end

--Spawns

--Behaviours