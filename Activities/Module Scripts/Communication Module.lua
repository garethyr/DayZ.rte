-----------------------------------------------------------------------------------------
-- Communication Module, lets modules talk to each other
-----------------------------------------------------------------------------------------
------------
--REQUESTS--
------------
function Chernarus:RequestSustenance_AddToSustenanceTable(actor)
	if self.IncludeSustenance then
		self:AddToSustenanceTable(actor);
	end
end
function Chernarus:RequestIcons_AddToMeterTable(actor)
	if self.IncludeIcons then
		self:AddToMeterTable(actor);
	end
end
--Loot

--Sustenance

--DayNight

--Flashlight

--Icons
function Chernarus:IconsRequestAlerts_ActorActivityPercent(atype, actor)
	if self.IncludeAlerts then
		if self.AlertTable[actor.UniqueID] ~= nil and self.AlertTable[actor.UniqueID][atype].strength > 0 then
			return 1;
		elseif self.HumanTable.Players[actor.UniqueID] ~= nil then
			return self.HumanTable.Players[actor.UniqueID].activity[atype].total/self.AlertValue;
		end
	end
	return 0;
end
function Chernarus:IconsRequestSustenance_ActorSustenancePercent(susttype, actor)
	if self.IncludeSustenance then
		if self.SustTable[actor.UniqueID] ~= nil then
			return (self.InitialSust[susttype] - math.min(self.InitialSust[susttype], self.SustTable[actor.UniqueID][susttype]))/self.InitialSust[susttype];
		end
	end
	return 0;
end

--Audio

--Alerts
function Chernarus:AlertsRequestSpawns_SpawnAlertZombie(position)
	if self.IncludeSpawns then
		return self:SpawnZombie(position, position, "alert");
	end
	return false;
end
function Chernarus:AlertsRequestSpawns_GetZombieSpawnInterval()
	if self.IncludeSpawns then
		return self.ZombieSpawnInterval;
	end
	return 0;
end
function Chernarus:AlertsRequestDayNight_LightItemNotInTable(item)
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
function Chernarus:NotifySust_DeadPlayer(ID)
	if self.IncludeSustenance and self.SustTable[ID] ~= nil then
		self.SustTable[ID] = nil;
	end
end
function Chernarus:NotifyIcons_DeadPlayer(ID)
	if self.IncludeIcons and self.MeterTable[ID] ~= nil then
		self:IconsRemoveMeter(ID);
	end
end
function Chernarus:NotifyAlerts_DeadHuman(alert)
	if self.IncludeAlerts and alert ~= false then
		self:MoveAlertFromDeadActor(alert);
	end
end

--Loot

--Sustenance

--DayNight
function Chernarus:DayNightNotifyAlerts_DayNightCycle()
	if self.IncludeAlerts then
		self.AlertIsDay = not self.DayNightIsNight;
	end
end

--Flashlight

--Icons
function Chernarus:IconsNotifyDayNight_RevealIcons(corner)
	if self.IncludeDayNight then
		local box = Box(corner, Vector(corner.X + self.IconMeterSpacing*(self.IconNumMeters+1), corner.Y + self.IconMeterSpacing));
		table.insert(self.DayNightExtraRevealBoxes, box);
	end
end

--Audio

--Alerts
function Chernarus:AlertsNotifyDayNight_LightEmittingItemAdded(item)
	if self.IncludeDayNight then
		self:AddDayNightLightItem(item)
	end
end

--SpawnsAndBehaviours