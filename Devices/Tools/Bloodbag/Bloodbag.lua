function Create(self)
	local UseScriptPath = "DayZ.rte/Devices/Tools/Usage Item Scripts.lua";
	dofile(UseScriptPath);
	RunUsageInclusions();
	
	--UseTable is a specifically formatted table with the main key being the used item's presetname and several values
	--item - The empty item to replace this item with. No value means no item replacement
	--useinterval - The length of time it takes to use the item. No value means instant use
	--useable - Whether the item is currently useable by the current parent actor. No value defaults to always true
	--onuse - The action that occurs on use, usually sound playing. No value means no action
	--duringuse - The action performed continuously during use, usually limiting movement/shooting. No value means no continuous actions
	--afteruse - The result that occurs once the item has finished being used. No value means no result
	local usetable = {
		["Bloodbag"] = {useinterval = 3000,
						useable = function(self)
							return self.Parent.Health < 100;
						end,
						onuse = function(self)
							local p  = CreateAEmitter("Bloodbag Sound Heal","DayZ.rte");
							MakeEffectParticle(p, self.Pos);
						end,
						duringuse = function(self)
							DisableAllWeaponActions(self.Parent);
							DisableMoving(self.Parent);
							DisableJumping(self.Parent);
						end,
						afteruse = function(self)
							self.Parent.Health = 100;
						end}
	};
	SetupUsage(self, usetable);
end
function Update(self)
	if HasParent(self) then
		ManageItemUse(self);
	end
end