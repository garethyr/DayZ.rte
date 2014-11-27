function Create(self)
	self.Parent = nil;
	self.ConsumeDelayTimer = Timer();
	self.ConsumeDelayInterval = 100; --How long it should take to consume the item
	self.Counter = 0; --Starts at 0, 1 when activated, 2 when finished eating/drinking, 3 when ready to delete
	self.SParticle = CreateAEmitter("Soda Sound Heal","DayZ.rte"); --The sound particle that plays on use
	--Junk is a table with the empty version of the item and an effect function for any special effects
	self.Junk = {
		["Coke"] = {item = CreateTDExplosive("Empty Coke", "DayZ.rte"), effect = function(self) end},
		["Pepsi"] = {item = CreateTDExplosive("Empty Pepsi", "DayZ.rte"), effect = function(self) end},
		["Mountain Dew"] = {item = CreateTDExplosive("Empty Mountain Dew", "DayZ.rte"), effect = function(self) end},
		["Baked Beans"] = {item = CreateTDExplosive("Empty Tin Can", "DayZ.rte"),
							effect = function(self)
								self.SParticle = CreateAEmitter("Baked Beans Sound Heal","DayZ.rte");
								self.Parent.Health = math.min(self.Parent.Health + 5, 100);
							end}
	}
	if self.RootID ~= 255 and self.RootID ~= self.ID and MovableMan:IsActor(MovableMan:GetMOFromID(self.RootID)) then
		self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
	end
end
function Update(self)
	--Various parent checks
	--If we have no parent or no non-self root
	if self.Parent == nil or self.RootID == self.ID or self.RootID == 255 then
		--Check if there's a parent to be had
		if self.RootID ~= 255 and self.RootID ~= self.ID and MovableMan:IsActor(MovableMan:GetMOFromID(self.RootID)) then
			self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
		else
			self.Parent = nil;
		end
	--Otherwise, if we have a parent and a non-self root
	elseif self.Parent ~= nil and self.RootID ~= self.ID then
		--If the root isn't the parent but exists and is an actor, change the parent
		if self.RootID ~= 255 and self.RootID ~= self.ID and MovableMan:IsActor(MovableMan:GetMOFromID(self.RootID)) then
			self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
		--Just in case, if the parent doesn't exist, remove it
		elseif not MovableMan:IsActor(self.Parent) or self.RootID == self.ID then
			self.Parent = nil;
			return;
		end

		--Do the item effects
		if self:IsActivated() and self.Parent ~= nil then
			self.Counter = 1;
		end
		if self.Counter > 0 then
			--Reset the timer on use
			if self.Counter == 1 then
				self.ConsumeDelayTimer:Reset();
				self.Counter = 2;
			end
			if self.ConsumeDelayTimer:IsPastSimMS(self.ConsumeDelayInterval) then
				if self.Counter == 2 then
					--Can't fire, swap weapon or drop/pickup while eating or drinking
					ToActor(self.Parent):GetController():SetState(Controller.WEAPON_CHANGE_PREV, false);
					ToActor(self.Parent):GetController():SetState(Controller.WEAPON_CHANGE_NEXT, false);
					ToActor(self.Parent):GetController():SetState(Controller.WEAPON_FIRE, false);
					ToActor(self.Parent):GetController():SetState(Controller.WEAPON_DROP, false);
					ToActor(self.Parent):GetController():SetState(Controller.WEAPON_PICKUP, false);
					self.Junk[self.PresetName].effect(self); --Do any special effects for the item
					self.SParticle.Pos = self.Pos;
					MovableMan:AddParticle(self.SParticle);
					self.Parent:AddInventoryItem(self.Junk[self.PresetName].item);
					
					self.Counter = 3;
				elseif self.Counter == 3 then
					self.Parent:GetController():SetState(Controller.WEAPON_CHANGE_PREV, true);
					self.ToDelete = true;
				end
			else
				self.Parent:GetController():SetState(Controller.WEAPON_FIRE,false);
			end
		end
	end
end
	