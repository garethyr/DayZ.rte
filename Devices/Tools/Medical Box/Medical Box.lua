function Create(self)
	---------------------------------------------------------------------------------
	--The name of the global variable for the activity we want to try to respawn with
	local activitytocheck = ModularActivity;
	---------------------------------------------------------------------------------


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
		["Medical Box"] = {useinterval = 5000,
					onuse = function(self)
						local p = CreateAEmitter("Medical Box Sound Repair","DayZ.rte"); 
						MakeEffectParticle(p, self.Pos);
					end,
					duringuse = function(self)
						DisableAllWeaponActions(self.Parent);
						DisableAllMovementActions(self.Parent);
					end,
					afteruse = function(self)
						--Respawn the parent actor
						local parentplayer = self.Parent:GetController().Player;
						local parentpos = self.Parent.Pos;
						local newactor;
						--If we're not in activitytocheck, which has its own actor respawning, manually respawn
						if activitytocheck == nil then
							newactor = MedicalBoxSimpleRespawn(self.Parent, parentplayer);
						--Otherwise, use the activity's respawning for this
						else
							print ("Activity based respawn from medbox");
							activitytocheck:SavePlayerForTransition(self.Parent);
							activitytocheck:LoadPlayersAfterTransition();
							newactor = activitytocheck.PlayerRespawnTable[#activitytocheck.PlayerRespawnTable].actor;
							activitytocheck:SpawnPlayerActor(nil, newactor, parentplayer, 0);
							table.remove(activitytocheck.PlayerRespawnTable, #activitytocheck.PlayerRespawnTable);
						end
						newactor.Pos = parentpos;
						ActivityMan:GetActivity():ReportDeath(newactor.Team,-1);
					end}
	}
	SetupUsage(self, usetable);
end
function Update(self)
	if HasParent(self) then
		ManageItemUse(self);
	end
end

function MedicalBoxSimpleRespawn(actor, player)
	local newactor;
	local inventory = {};
	
	--Save equipped item
	if actor.EquippedItem ~= nil then
		local obj = actor.EquippedItem;
		local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
		table.insert(inventory, item);
	end
	--Save inventory
	if not actor:IsInventoryEmpty() then
		for i = 1, actor.InventorySize do
			local obj = actor:Inventory();
			local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
			table.insert(inventory, item);
			actor:SwapNextInventory(nil, true);
		end
	end
	
	local newactor = CreateAHuman(actor.PresetName);
	newactor.Team = actor.Team;
	newactor.Sharpness = actor.Sharpness;
	newactor.AIMode = Actor.AIMODE_SENTRY;
	
	--Load equipped item and/or inventory
	local itemcreatetable = {HDFirearm = function(name) return CreateHDFirearm(name) end,
							 TDExplosive = function(name) return CreateTDExplosive(name) end,
							 HeldDevice = function(name) return CreateHeldDevice(name) end,
							 ThrownDevice = function(name) return CreateThrownDevice(name) end}
	for _, item in ipairs(inventory) do
		local newitem = itemcreatetable[item.itype](item.name);
		newitem.Sharpness = item.sharpness;
		newactor:AddInventoryItem(newitem);
	end
	--MovableMan:RemoveActor(actor);
	actor.ToDelete = true;
	
	MovableMan:AddActor(newactor);
	ActivityMan:GetActivity():SwitchToActor(newactor, player, newactor.Team);
	return newactor;
end