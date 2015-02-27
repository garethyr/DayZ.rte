function RunUsageInclusions()
	local ItemScriptPath = "DayZ.rte/Devices/Tools/Miscellaneous Item Scripts.lua";
	dofile(ItemScriptPath);
end
--All the setup for easy useage checks and timer
function SetupUsage(self, usetable)
	SetupParent(self);
	
	self.UseTimer = Timer();
	self.ItemUsed = false; --Boolean for if the item has been successfully used
	self.ActionEffectsDone = false; --Boolean for whether or not action effects have been done
	
	--UseTable is a specifically formatted table with the main key being the used item's presetname and several values
	--junkitem - The empty item to replace this item with. No value means no item replacement
	--useinterval - The length of time it takes to use the item. No value means instant use
	--useable - Whether the item is currently useable by the current parent actor. No value defaults to always true
	--onuse - The action that occurs on use, usually sound playing. No value means no action
	--duringuse - The action performed continuously during use, usually limiting movement/shooting. No value means no continuous actions
	--afteruse - The result that occurs once the item has finished being used. No value means no result
	self.UseTable = usetable;
end
function MakeEffectParticle(particle, pos)
	particle.Pos = pos;
	MovableMan:AddParticle(particle);
end
function ManageItemUse(self)
	--Start use and reset the use delay timer
	if not self.ItemUsed and self:IsActivated() then
		if self.UseTable[self.PresetName].useable == nil or self.UseTable[self.PresetName].useable(self) then
			self.ItemUsed = true;
			self.UseTimer:Reset();
			--Perform actions on use
			if self.UseTable[self.PresetName].onuse ~= nil then
				self.UseTable[self.PresetName].onuse(self);
			end
		end
	elseif self.ItemUsed then
		local useinterval = self.UseTable[self.PresetName].useinterval or 0;
		if not self.UseTimer:IsPastSimMS(useinterval) then
			--Perform actions during use
			if self.UseTable[self.PresetName].duringuse ~= nil then
				self.UseTable[self.PresetName].duringuse(self);
			end
		else
			--Perform actions after use
			if self.UseTable[self.PresetName].afteruse ~= nil then
				self.UseTable[self.PresetName].afteruse(self);
			end
			--Add the junk item and remove the current item
			if self.UseTable[self.PresetName].junkitem ~= nil then
				self.Parent:AddInventoryItem(self.UseTable[self.PresetName].junkitem);
			end
			self.Parent:GetController():SetState(Controller.WEAPON_CHANGE_PREV, true);
			self.ToDelete = true;
		end
	end
end