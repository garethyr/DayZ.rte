function Create(self)
	if not DayZHumanWoundTable then
		DayZHumanWoundTable = {}
	end
	self.Parent = nil;
	self.DelayTimer = Timer();
	self.Counter = 0;
	self.SParticle = CreateAEmitter("Bandage Sound Heal","DayZ.rte"); --The sound particle that plays on use
	--Junk is the empty version of the item, if there is one
	self.Junk = nil
	if self.RootID ~= 255 then
		self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
	end
end
function Update(self)
	--Various parent checks
	--If we have no parent or no non-self root
	if self.Parent == nil or self.RootID == self.ID or self.RootID == 255 then
		--Check if there's a parent to be had
		if self.RootID ~= 255 and self.RootID ~= self.ID then
			self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
		else
			self.Parent = nil;
		end
	--Otherwise, if we have a parent and a non-self root
	elseif self.Parent ~= nil and self.RootID ~= self.ID then
		--If the root isn't the parent, change the parent
		if self.RootID ~= self.Parent.ID then
			self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
		end
		--Just in case, if the parent doesn't exist, remove it
		if not MovableMan:IsActor(self.Parent) or self.RootID == self.ID then
			self.Parent = nil;
		end

		--Do the item effects
		if self:IsActivated() and self.Parent ~= nil then
			self.Counter = 1;
		end
		if self.Counter > 0 then
			--Reset the timer on use
			if self.Counter == 1 then
				self.DelayTimer:Reset();
				self.Counter = 2;
			end
			if self.DelayTimer:IsPastSimMS(100) then
				if self.Counter == 2 then
				
					--Stop wounds on this actor from emitting
					if #DayZHumanWoundTable > 0 then
						local used = false; --Flag true if it's actually useable
						for i = #DayZHumanWoundTable, 1, -1 do
							if DayZHumanWoundTable[i][2].ID == self.Parent.ID then
								DayZHumanWoundTable[i][1]:EnableEmission(false);
								table.remove(DayZHumanWoundTable, k);
								used = true;
							end
						end
						--If it's been used, get rid of it
						if used == true then
							self.SParticle.Pos = self.Pos;
							MovableMan:AddParticle(self.SParticle);

							if self.Junk ~= nil then
								self.Parent:AddInventoryItem(self.Junk);
							end
							
							self.Counter = 3;
						else
							self.Counter = 0;
						end
					end
				
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
