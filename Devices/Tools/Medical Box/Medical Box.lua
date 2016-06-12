function Create(self)
	---------------------------------------------------------------------------------
	--The name of the global variable for the activity we want to try to respawn with
	self.ActivityToCheck = ModularActivity;
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
						--If we're not playing ActivityToCheck, which has its own actor respawning, manually respawn
						if self.ActivityToCheck == nil then
							newactor = MedicalBoxSimpleRespawn(self.Parent, parentplayer);
						--Otherwise, use the activity's respawning for this
						else
							newactor = MedicalBoxActivityRespawn(self.Parent, parentplayer, self.ActivityToCheck);
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

function MedicalBoxActivityRespawn(oldactor, player, activity) --TODO this only works for players at the moment as it needs to be implemented for NPCs too. A lot of similar functions can probably be reused
	print ("Activity based respawn from medbox");
	--Save the actor but don't save his health or wounds, then force load him
	activity:SavePlayerForTransition(oldactor, false, false);
	activity:LoadPlayersAfterTransition();
	
	--Get the human table entry for the old actor and the respawn table entry for the new actor
	local respawntableentry = activity.PlayerRespawnTable[#activity.PlayerRespawnTable];
	local humantype = activity.HumanTable.Players[oldactor.UniqueID] ~= nil and "Players" or "NPCs";
	local oldhumantableentry = activity.HumanTable[humantype][oldactor.UniqueID];
	newactor = respawntableentry.actor;
	--Add any alert and activity values to the new actor's respawn table args so they'll be automatically moved over on spawning
	respawntableentry.args.activity = oldhumantableentry.activity;
	respawntableentry.args.alert = oldhumantableentry.alert;
	activity:SpawnPlayerActorWithoutRemovingFromRespawnTable(nil, newactor, player, respawntableentry.args, 0);
	table.remove(activity.PlayerRespawnTable, #activity.PlayerRespawnTable);
	
	--Delete the old actor and remove it from whichever human table it was in, so it doesn't get removed by the activity and trigger communications
	oldactor.ToDelete = true;
	activity:NotifyMany_DeadHuman(nil, player, oldactor.UniqueID, false); --Pass in nil for the first argument so the actor won't auto respawn and false for the last because it no longer has alerts
	activity.HumanTable[humantype][oldactor.UniqueID] = nil;
	return newactor;
end

function MedicalBoxSimpleRespawn(oldactor, player)
	local newactor;
	local inventory = {};
	
	--Save equipped item
	if oldactor.EquippedItem ~= nil then
		local obj = oldactor.EquippedItem;
		local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
		table.insert(inventory, item);
	end
	--Save inventory
	if not oldactor:IsInventoryEmpty() then
		for i = 1, oldactor.InventorySize do
			local obj = oldactor:Inventory();
			local item = {itype = obj.ClassName, name = obj.PresetName, sharpness = obj.Sharpness};
			table.insert(inventory, item);
			oldactor:SwapNextInventory(nil, true);
		end
	end
	
	local newactor = CreateAHuman(oldactor.PresetName);
	newactor.Team = oldactor.Team;
	newactor.Sharpness = oldactor.Sharpness;
	newactor.AIMode = oldactor.AIMODE_SENTRY;
	
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
	--MovableMan:RemoveActor(oldactor);
	oldactor.ToDelete = true;
	
	MovableMan:AddActor(newactor);
	ActivityMan:GetActivity():SwitchToActor(newactor, player, newactor.Team);
	return newactor;
end