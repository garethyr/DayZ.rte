--Call relevant ModularActivity (DayZ) function when the item hits the ground
function Create(self)
end
function Update(self)
end
function Destroy(self)
	--If we're running a ModularActivity (DayZ) then let it know the item is ready to become an alert
	if ModularActivity ~= nil and ModularActivity.IncludeAlerts and ModularActivity.AlertItemTable[self.UniqueID] ~= nil then
		ModularActivity:AddAlertFromAlertItem(self);
	end
end