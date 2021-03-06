-----------------------------------------------------------------------------------------
-- Do everything for flashlights
-----------------------------------------------------------------------------------------
--------------------
--CREATE FUNCTIONS--
--------------------
function ModularActivity:StartFlashlight()
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Turn flashlights on or off for players and npcs
function ModularActivity:DoFlashlights()
	for _, humantable in pairs(self.HumanTable) do
		for k, v in pairs(humantable) do
			--Flag for the flashlight on or off based on its actor's sharpness
			v.lightOn = (v.actor.Sharpness > 0);
			
			--Stop the player from dropping the flashlight
			if v.actor.EquippedItem ~= nil and v.actor.EquippedItem.PresetName == "Flashlight" then
				v.actor:GetController():SetState(Controller.WEAPON_DROP, false);
			end
			
			--Add flashlights if actors don't have them
			if not v.actor:HasObject("Flashlight") then
				self:ReAddFlashlight(v.actor);
			end
			
			--Swap to flashlight if we're supposed to but it's not equipped or set as unequipped if it's swapped away from
			if v.lightOn == true and v.actor:HasObject("Flashlight") then
				if v.actor.EquippedItem ~= nil then
					if v.actor.EquippedItem.PresetName ~= "Flashlight" then
						v.actor:GetController():SetState(Controller.WEAPON_CHANGE_PREV, true);
					else
						if v.actor:GetController():IsState(Controller.WEAPON_CHANGE_NEXT) or v.actor:GetController():IsState(Controller.WEAPON_CHANGE_PREV) then
							v.actor.Sharpness = 0;
						end
					end
				end
			end
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Adds a flashlight to the actor's inventory if there's not one there already
function ModularActivity:AddFlashlightForActor(actor)
	if not actor:HasObject("Flashlight") then
		actor:AddInventoryItem(CreateHDFirearm("Flashlight" , self.RTE));
	end
end
--Add a new flashlight to the actor's inventory, flashlight battery starts off very low as punishment for losing it
function ModularActivity:ReAddFlashlight(actor)
	local newlight = CreateHDFirearm("Flashlight", self.RTE);
	actor:AddInventoryItem(newlight);
	newlight.Sharpness = newlight.Sharpness/10;
end