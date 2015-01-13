-----------------------------------------------------------------------------------------
-- Communication Module, lets modules talk to each other
-----------------------------------------------------------------------------------------
------------
--REQUESTS--
------------
function DayZActivity:RequestSustenance_AddToSustenanceTable(actor)
	if self.IncludeSustenance then
		self:AddToSustenanceTable(actor);
	end
end
function DayZActivity:RequestIcons_AddToMeterTable(actor)
	if self.IncludeIcons then
		self:AddToMeterTable(actor);
	end
end
--TODO make this also take a maxdist so alerts can trigger things like zombie spawns by being visible within the max spawndist???
function DayZActivity:RequestAlerts_CheckForVisibleAlerts(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:CheckForVisibleAlerts(pos, awarenessmod, mindist);
	end
	return false;
end
function DayZActivity:RequestAlerts_NearestVisibleAlert(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
	if self.IncludeAlerts then
		return self:NearestVisibleAlert(pos, awarenessmod, mindist);
	end
	return nil;
end
function DayZActivity:RequestAlerts_VisibleAlerts(pos, awarenessmod, mindist) --awareness mod < 1 lowers awareness distance, > 1 raises it
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
function DayZActivity:IconsRequestAlerts_ActorActivityPercent(atype, actor)
	if self.IncludeAlerts then
		if self.AlertTable[actor.UniqueID] ~= nil and self.AlertTable[actor.UniqueID][atype].strength > 0 then
			return 1;
		elseif self.HumanTable.Players[actor.UniqueID] ~= nil then
			return self.HumanTable.Players[actor.UniqueID].activity[atype].total/self.AlertValue;
		end
	end
	return 0;
end
function DayZActivity:IconsRequestSustenance_ActorSustenancePercent(susttype, actor)
	if self.IncludeSustenance then
		if self.SustTable[actor.UniqueID] ~= nil then
			return (self.MaxSust[susttype] - math.min(self.MaxSust[susttype], self.SustTable[actor.UniqueID][susttype]))/self.MaxSust[susttype];
		end
	end
	return 0;
end

--Audio
function DayZActivity:AudioRequestDayNight_DayOrNightCapitalizedString()
	if self.IncludeDayNight then
		return self.DayNightIsNight and "Night" or "Day";
	end
	return "Day";
end

--Alerts
function DayZActivity:AlertsRequestSpawns_SpawnAlertZombie(position)
	if self.IncludeSpawns then
		return self:SpawnZombie(position, position, "alert");
	end
	return false;
end
function DayZActivity:AlertsRequestSpawns_GetZombieSpawnInterval()
	if self.IncludeSpawns then
		return self.ZombieSpawnInterval;
	end
	return 0;
end
function DayZActivity:AlertsRequestDayNight_LightItemNotInTable(item)
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
function DayZActivity:NotifySust_DeadPlayer(ID)
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		self.SustTable[ID] = nil;
	end
end
function DayZActivity:NotifyIcons_DeadPlayer(ID)
	if self.IncludeIcons and self.MeterTable[ID] ~= nil then
		self:IconsRemoveMeter(ID);
	end
end
function DayZActivity:NotifyAlerts_DeadHuman(alert)
	if self.IncludeAlerts and alert ~= false then
		self:MoveAlertFromDeadActor(alert);
	end
end

--Loot

--Sustenance

--DayNight
function DayZActivity:DayNightNotifyMany_DayNightCycle()
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
function DayZActivity:IconsNotifyDayNight_RevealIcons(corner)
	if self.IncludeDayNight then
		local box = Box(corner, Vector(corner.X + self.IconMeterSpacing*(self.IconNumMeters+1), corner.Y + self.IconMeterSpacing));
		table.insert(self.DayNightExtraRevealBoxes, box);
	end
end

--Audio

--Alerts
function DayZActivity:AlertsNotifyDayNight_LightEmittingItemAdded(item)
	if self.IncludeDayNight then
		self:AddDayNightLightItem(item)
	end
end

--SpawnsAndBehaviours