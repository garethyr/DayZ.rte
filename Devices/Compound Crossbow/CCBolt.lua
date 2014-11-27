function Create(self)

	self.actionPhase = 0;
	self.stuck = false;
	self.Payload = nil
	self.Once = false
	self.Once2 = false
	self.lifeTimer = Timer();
	
	self.guncurdist = 50;
	for i = 1,MovableMan:GetMOIDCount()-1 do
		self.gun = MovableMan:GetMOFromID(i);
		if self.gun.PresetName == "Compound Crossbow" and self.gun.ClassName == "HDFirearm" and SceneMan:ShortestDistance(self.gun.Pos,self.Pos - self.Vel,SceneMan.SceneWrapsX).Magnitude < self.guncurdist then
			self.RotAngle = self.gun.RotAngle
			if self.gun.HFlipped then
				self.RotAngle = self.RotAngle + math.pi
			end
--			self.Vel = Vector(math.cos(self.RotAngle) , math.sin(self.RotAngle)) * 40 + MovableMan:GetMOFromID(self.gun.RootID).Vel
			--[[if self.gun.Sharpness == 3 then
				for i = 1,MovableMan:GetMOIDCount()-1 do
					self.grenade = MovableMan:GetMOFromID(i);
					if self.grenade.ClassName == "TDExplosive" and SceneMan:ShortestDistance(self.grenade.Pos,self.gun.Pos + self.gun:RotateOffset(Vector(5 , -3)),SceneMan.SceneWrapsX).Magnitude < 80 then
						if self.Payload ~= nil and self.Payload.ID ~= 255 then
							self.Payload.HitMOs = false
							self.Payload.GetsHitByMOs = false
							self.Payload.HitsMOs = false						
						end
						self.Payload = self.grenade
						self.grenade.HitMOs = false
						self.grenade.GetsHitByMOs = false
						self.grenade.HitsMOs = false
					end
				end
			end
			self.gun.Sharpness = 4--]]
			break;
		end
	end
end

function Update(self)
	--Aerodynamic stuff
	if self.RotAngle > math.pi * 2 then
		self.RotAngle = self.RotAngle - math.pi*2
	end
	if self.RotAngle < 0 then
		self.RotAngle = self.RotAngle + math.pi*2
	end
	
	local direction = self.Vel.AbsRadAngle
	
	self.AngularVel = self.AngularVel - math.sin((self.RotAngle - direction)*2)*0.02*self.Vel.Magnitude

	local RotAngleVector = Vector(math.cos(self.RotAngle) , math.sin(self.RotAngle))
	local AirShadow = (RotAngleVector * (self.Vel.Normalized.X*RotAngleVector.X + self.Vel.Normalized.Y*RotAngleVector.Y)).Magnitude
	local RotAngleVectorPer = RotAngleVector.Perpendicular
	local DirectionalSpeed = (RotAngleVectorPer * (self.Vel.X*RotAngleVectorPer.X + self.Vel.Y*RotAngleVectorPer.Y)).Magnitude
	local negatore = 1
	if (self.Vel.Normalized.X*RotAngleVector.Y + self.Vel.Normalized.Y*RotAngleVector.X) < 0 then
		negatore = -1;
	end
			
	local AirRessistanceForce = AirShadow * 0.0005	* DirectionalSpeed^2
	self.Vel = self.Vel + RotAngleVectorPer*AirRessistanceForce * negatore

	local AirRessistanceForce = 0.00002 * self.Vel.Magnitude^2
	self.Vel = self.Vel - self.Vel.Normalized*AirRessistanceForce
	
	self.ToDelete = false;
	self.ToSettle = false;
	
	local DirectionalSpeed = (RotAngleVectorPer * (self.Vel.X*RotAngleVector.X + self.Vel.Y*RotAngleVector.Y)).Magnitude
	if self.actionPhase == 0 and (DirectionalSpeed > 10 or DirectionalSpeed < -40) then
		local rayHitPos = Vector(0,0);
		local rayHit = false;
		for i = 1, self.Vel.Magnitude do --Check for anything within the speed of the bolt
			local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude(i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			
			--if checkPix ~= 255 and (not MovableMan:ValidMO(self.Payload) or checkPix ~= self.Payload.ID) and (not MovableMan:ValidMO(self.gun) or checkPix ~= self.gun.ID) and MovableMan:GetMOFromID(checkPix).Team ~= self.Team then

			--If we have something and it's not a gun or an actor on our team
			if checkPix ~= 255 and (not MovableMan:ValidMO(self.gun) or checkPix ~= self.gun.ID) and MovableMan:GetMOFromID(checkPix).Team ~= self.Team then 
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickpositionX = checkPos.X-self.target.Pos.X;
				self.stickpositionY = checkPos.Y-self.target.Pos.Y;
				self.stickrotation = self.target.RotAngle;
				self.stickdirection = self.RotAngle;
				self.stuck = true;
				rayHit = true;
				local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
				fxa.Pos = self.Pos + self:RotateOffset(Vector(i , 0))
				fxa.Vel = self.Vel
				fxa.Sharpness = self.Vel.Magnitude
				fxa.LifeTime = self.Vel.Magnitude
				MovableMan:AddParticle(fxa);
				if self.Vel.Magnitude > 15 then
					local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
					fxa.Pos = self.Pos + self:RotateOffset(Vector(i , 0))
					fxa.Vel = self.Vel
					fxa.Sharpness = self.Vel.Magnitude
					fxa.LifeTime = self.Vel.Magnitude
					MovableMan:AddParticle(fxa);
				end
				if self.Vel.Magnitude > 30 then
					local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
					fxa.Pos = self.Pos + self:RotateOffset(Vector(i , 0))
					fxa.Vel = self.Vel
					fxa.Sharpness = self.Vel.Magnitude
					fxa.LifeTime = self.Vel.Magnitude
					MovableMan:AddParticle(fxa);
				end
				break;
			end
		end
		if rayHit == true then
			self.actionPhase = 1;
		else
			if SceneMan:CastStrengthRay(self.Pos,Vector(self.Vel.X,self.Vel.Y):SetMagnitude(self.Vel.Magnitude),0,rayHitPos,0,0,SceneMan.SceneWrapsX) == true then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				self.HitsMOs = false;
				local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
				fxa.Pos = self.Pos
				fxa.Vel = self.Vel
				fxa.Sharpness = self.Vel.Magnitude
				fxa.LifeTime = self.Vel.Magnitude
				MovableMan:AddParticle(fxa);
				if self.Vel.Magnitude > 15 then
					local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
					fxa.Pos = self.Pos
					fxa.Vel = self.Vel
					fxa.Sharpness = self.Vel.Magnitude
					fxa.LifeTime = self.Vel.Magnitude
					MovableMan:AddParticle(fxa);
				end
				if self.Vel.Magnitude > 30 then
					local fxa = CreateMOPixel("Autocannon Fragment Gray 2");
					fxa.Pos = self.Pos
					fxa.Vel = self.Vel
					fxa.Sharpness = self.Vel.Magnitude
					fxa.LifeTime = self.Vel.Magnitude
					MovableMan:AddParticle(fxa);
				end
				--[[if MovableMan:ValidMO(self.Payload) and self.Payload ~= nil then
					self.Payload.Pos = self.Pos
					self.Payload.Vel = self.Vel
				end--]]
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= 255 then
			local negatore = 1
			if self.HFlipped then
				negatore = -1;
			end
			self.Pos = self.target.Pos + Vector(self.stickpositionX * negatore,self.stickpositionY):RadRotate(self.target.RotAngle-self.stickrotation);
			self.RotAngle = self.stickdirection+(self.target.RotAngle + (negatore*math.pi-math.pi)*0.5-self.stickrotation);
			self.PinStrength = 1000;
			self.Vel = Vector(0,0);
			self.HitsMOs = false;
			self.lifeTimer:Reset()
			--BB Addition: Kill human targets instantly
			if self.target.ClassName == "AHuman" then
				if ToActor(self.target).Health > 0 then
					ToActor(self.target).Health = 0;
					self.target = nil;
				end
			end
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
			self.HitsMOs = true;
		end
	end
	if self.PinStrength > 0 and self.lifeTimer:IsPastSimMS(10000) then
		self.PinStrength = 0
		self.ToSettle = true;
	end
	--[[if MovableMan:ValidMO(self.Payload) and self.Payload ~= nil then
		if self.Once2 == false then
			self.Vel = self.Vel / math.max(1, self.Payload.Mass)
			self.Payload.Vel = self.Vel
			self.Once2 = true
		end
		if not self.stuck then
			self.Payload.Pos = self.Payload.Pos + SceneMan:ShortestDistance(self.Payload.Pos,self.Pos + self:RotateOffset(Vector(0 , -1)),SceneMan.SceneWrapsX) * self.Mass/(self.Payload.Mass+self.Mass)
			self.Pos = self.Payload.Pos
			self.Payload.Vel = self.Payload.Vel + (self.Vel - self.Payload.Vel) * self.Mass/(self.Payload.Mass+self.Mass)
			self.Vel = self.Payload.Vel
		else
			self.Payload.Pos = self.Pos
			self.Payload.Vel = self.Vel
		end
		self.Payload.RotAngle = self.RotAngle + math.pi/2*negatore
		self.Payload.HFlipped = self.HFlipped
		if self.Age > 200 and self.Once == false then
			ToTDExplosive(self.Payload):Activate()
			self.Once = true
		end
	end--]]
end