function Create(self)
	self.Parent = nil;
	self.ClickTimer = Timer();
	self.State = 0;
	
	self.BatteryLevel = self.Sharpness;
	self.BatteryTimer = Timer();
	self.DelayTimer = Timer();
	self.PrevFlash = 0;
	
	--BALANCE STUFF
	self.NumRevealBoxes = 4;
	self.RevealBoxSize = 100;
	--BALANCE STUFF DONE
	
	if self.RootID ~= 255 and self.RootID ~= self.ID and MovableMan:IsActor(MovableMan:GetMOFromID(self.RootID)) then
		self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
	end
end
function Update(self)
	if UInputMan:KeyPressed(3) then
		self:ReloadScripts();
	end
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
		ToGameActivity(ActivityMan:GetActivity()):AddObjectivePoint(tostring(self.BatteryLevel).."  "..tostring(self.Parent.Sharpness), Vector(self.Parent.Pos.X, self.Parent.Pos.Y - 100), self.Parent.Team, GameActivity.ARROWDOWN);

		--Swap on/off
		if self:IsActivated() then-- and self.State == 0 then
			--if self.ClickTimer:IsPastSimMS(100) then
				if self.Parent.Sharpness == 0 then
					self.Parent.Sharpness = 1;
				else
					self.Parent.Sharpness = 0;
				end
			--	self.ClickTimer:Reset();
			--end
			--self.State = 1;
		--else
		--	self.State = 0;
		end
		--Drain battery when on
		if self.Parent.Sharpness > 0 then
			if self.BatteryTimer:IsPastSimMS(500) then
				self.BatteryLevel = self.BatteryLevel - 1;
				self.BatteryTimer:Reset();
			end
			--Keep on steadily
			if self.Parent.Sharpness == 1 then
				--Change to low battery mode
				if self.BatteryLevel <= 20 then
					self.Parent.Sharpness = 2;
				else
					MakeLight(self);
				end
			elseif self.Parent.Sharpness == 2 then
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
					self.Parent.Sharpness = 0;
				end
			end
		--Replenish battery when off
		elseif self.Parent.Sharpness == 0 then
			if self.BatteryTimer:IsPastSimMS(50) and self.BatteryLevel < 100 then
				self.BatteryLevel = self.BatteryLevel + 1;
				self.BatteryTimer:Reset();
			end
		end
		self.Sharpness = self.BatteryLevel;
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
		