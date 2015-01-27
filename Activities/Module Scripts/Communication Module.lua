-----------------------------------------------------------------------------------------
-- NECESSARY MODULE: Communication Module, lets modules talk to each other
-----------------------------------------------------------------------------------------
------------
--REQUESTS--
------------
function ModularActivity:RequestSustenance_AddToSustenanceTable(actor)
	if self.IncludeSustenance then
		self:AddToSustenanceTable(actor);
	end
end
function ModularActivity:RequestIcons_AddToMeterTable(actor)
	if self.IncludeIcons then
		self:AddToMeterTable(actor);
	end
end
--TODO make this also take a maxdist so alerts can trigger things like zombie spawns by being visible within the max spawndist???
function ModularActivity:RequestAlerts_CheckForVisibleAlerts(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:CheckForVisibleAlerts(pos, awarenessmod, mindist);
	end
	return false;
end
function ModularActivity:RequestAlerts_NearestVisibleAlert(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:NearestVisibleAlert(pos, awarenessmod, mindist);
	end
	return nil;
end
function ModularActivity:RequestAlerts_VisibleAlerts(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:VisibleAlerts(pos, awarenessmod, mindist);
	end
	return {};
end
--Loot

--Sustenance

--DayNight

--Flashlight

--Icons
function ModularActivity:IconsRequestAlerts_ActorActivityPercent(atype, actor)
	if self.IncludeAlerts then
		if self.AlertTable[actor.UniqueID] ~= nil and self.AlertTable[actor.UniqueID][atype].strength > 0 then
			return 1;
		elseif self.HumanTable.Players[actor.UniqueID] ~= nil then
			return self.HumanTable.Players[actor.UniqueID].activity[atype].total/self.AlertValue;
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

--Audio
function ModularActivity:AudioRequestDayNight_DayOrNightCapitalizedString()
	if self.IncludeDayNight then
		return self.DayNightIsNight and "Night" or "Day";
	end
	return "Day";
end

--Alerts
function ModularActivity:AlertsRequestSpawns_SpawnAlertZombie(position)
	if self.IncludeSpawns then
		return self:SpawnZombie(position, position, "alert");
	end
	return false;
end
function ModularActivity:AlertsRequestSpawns_GetZombieSpawnInterval()
	if self.IncludeSpawns then
		return self.ZombieSpawnInterval;
	end
	return 0;
end
function ModularActivity:AlertsRequestDayNight_LightItemNotInTable(item)
	if self.IncludeDayNight then
		return self.DayNightLightItemTable[item.UniqueID] == nil;
	end
	return false;
end

--SpawnsAndBehaviours

-----------------
--NOTIFICATIONS--
-----------------
--Main
function ModularActivity:NotifySust_DeadPlayer(ID)
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		self.SustTable[ID] = nil;
	end
end
function ModularActivity:NotifyIcons_DeadPlayer(ID)
	if self.IncludeIcons and self.MeterTable[ID] ~= nil then
		self:IconsRemoveMeter(ID);
	end
end
function ModularActivity:NotifyAlerts_DeadHuman(alert)
	if self.IncludeAlerts and alert ~= false then
		self:MoveAlertFromDeadActor(alert);
	end
end
function ModularActivity:NotifyDayNight_ResetBackgroundPosition()
	self:DayNightResetBackgroundPosition();
end

--Loot

--Sustenance

--DayNight
function ModularActivity:DayNightNotifyMany_DayNightCycle()
	if self.IncludeAlerts then
		self.AlertIsDay = not self.DayNightIsNight;
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
		local box = Box(corner, Vector(corner.X + self.IconMeterSpacing*(self.IconNumMeters+1), corner.Y + self.IconMeterSpacing));
		table.insert(self.DayNightExtraRevealBoxes, box);
	end
end

--Audio

--Alerts
function ModularActivity:AlertsNotifyDayNight_LightEmittingItemAdded(item)
	if self.IncludeDayNight then
		self:AddDayNightLightItem(item)
	end
end

--SpawnsAndBehaviours