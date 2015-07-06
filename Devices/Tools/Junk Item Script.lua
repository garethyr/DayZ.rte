--Call relevant function from the activity we want to check (DayZ) when the item hits the ground
function Create(self)
	---------------------------------------------------------------------------------
	--The name of the global variable for the activity we want to try to add alert to
	self.ActivityToCheck = ModularActivity;
	---------------------------------------------------------------------------------
end
function Update(self)
end
function Destroy(self)
	--If we're running the activity we want to check (DayZ) then let it know the item is ready to become an alert
	if self.ActivityToCheck ~= nil and self.ActivityToCheck.IncludeAlerts and self.ActivityToCheck.AlertItemTable[self.UniqueID] ~= nil then
		self.ActivityToCheck:AddAlertFromAlertItem(self);
	end
end

function SilentlyDiscard(actor)
	actor = ToAHuman(actor);
	print ("Silent discard for "..tostring(actor).." with equipped item "..tostring (actor.EquippedItem));
	if actor.EquippedItem ~= nil then
		actor.EquippedItem.ToDelete = true;
		actor:GetController():SetState(Controller.WEAPON_CHANGE_PREV, true);
	end
end