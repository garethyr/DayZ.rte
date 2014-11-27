function Create(self)
	self.Parent = nil;
	if self.RootID ~= 255 then
		self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
	end
	
	self.BatteryLevel = 100;
	self.BatteryTimer = Timer();
	self.DelayTimer = Timer();
	self.PrevFlash = 0;
	
	--BALANCE STUFF
	self.NumRevealBoxes = 4;
	self.RevealBoxSize = 100;
	--BALANCE STUFF DONE
end
function Update(self)
	if UInputMan:KeyPressed(3) then
		self:ReloadScripts()
	end
	if UInputMan:KeyPressed(2) then
		self.BatteryLevel = 40;
	end
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
		ToGameActivity(ActivityMan:GetActivity()):AddObjectivePoint(tostring(self.BatteryLevel).."  "..tostring(self.Sharpness), Vector(self.Parent.Pos.X, self.Parent.Pos.Y - 100), self.Parent.Team, GameActivity.ARROWDOWN);

		--Do the item effects
		if self.Parent ~= nil then
			--Swap on/off
			if self:IsActivated() then
				if self.Sharpness == 0 then
					self.Sharpness = 1;
				elseif self.Sharpness > 0 then
					self.Sharpness = 0;
				end
			end
			--Drain battery when on
			if self.Sharpness > 0 then
				if self.BatteryTimer:IsPastSimMS(100) then
					self.BatteryLevel = self.BatteryLevel - 1;
					self.BatteryTimer:Reset();
				end
				--Keep on steadily
				if self.Sharpness == 1 then
					--Change to low battery mode
					if self.BatteryLevel <= 20 then
						self.Sharpness = 2;
					else
						MakeLight(self);
					end
				elseif self.Sharpness == 2 then
					local n = 250 --Flash time
					if not self.DelayTimer:IsPastSimMS(n) then
						if self.PrevFlash == 0 then
							MakeLight(self);
						end
					elseif self.DelayTimer:IsPastSimMS(n) then
						if self.PrevFlash == 0 then
							self.PrevFlash = 1;
						elseif self.PrevFlash == 1 then
							self.PrevFlash = 0
						end
						self.DelayTimer:Reset();
					end
					if self.BatteryLevel <= 0 then
						self.Sharpness = 0;
					end
				end
			--Replenish battery when off
			elseif self.Sharpness == 0 then
				if self.BatteryTimer:IsPastSimMS(50) and self.BatteryLevel < 100 then
					self.BatteryLevel = self.BatteryLevel + 1;
					self.BatteryTimer:Reset();
				end
			end
		end
	end
end
function MakeLight(self)
	--Some important shorthands
	local n = self.NumRevealBoxes;
	local m = self.RevealBoxSize;
	local xmult = math.cos(self.Parent:GetAimAngle(true));
	local ymult = -math.sin(self.Parent:GetAimAngle(true));
	
	--Make light show
	local l = CreateMOSParticle("Flashlight Glow","DayZ.rte");
	l.LifeTime = 100;
	l.Pos = Vector(self.Pos.X + 5*xmult, self.Pos.Y + 5*ymult);
	MovableMan:AddParticle(l);
	
	--Reveal fog
	print (ymult)
	for i = 0, ToGameActivity(ActivityMan:GetActivity()).TeamCount do
		for j = 1, n do
			for k = -1 , 1 do
				--Formula: Position + size*2*number*directionmult
				ymult = ymult + 0.25*k;
				xmult = xmult + 0.25*k;
				if ymult > 1 then
					ymult = 1;
				elseif ymult < -1 then
					ymult = -1;
				end
				if xmult > 1 then
					xmult = 1;
				elseif xmult < -1 then
					xmult = -1;
				end
				local pos = Vector(self.Parent.Pos.X + m*2*j*xmult, self.Parent.Pos.Y + m*2*j*ymult)
				SceneMan:RevealUnseenBox(pos.X - m, pos.Y - m, m*2, m*2, i);
			end
		end
	end
end
		