function Create(self)

	--Maximum allowed change in the speed's magnitude.
	self.maxchange = 5;

	--The velocity, last frame.
	self.lastvel = Vector(self.Vel.X,self.Vel.Y);
	
	local smoke = CreateMOSParticle("Igniting Flame");
	smoke.Pos = self.Pos - (self.lastvel*0.4);
	--smoke.Vel = self.Vel*0.2;
	--smoke.Vel.X = smoke.Vel.X + ((math.random() - 0.5) * 7);
	--smoke.Vel.Y = smoke.Vel.Y + ((math.random() - 0.5) * 7);
	
	MovableMan:AddParticle(smoke);
	
end

function Update(self)

	local change = self.lastvel.Magnitude - self.Vel.Magnitude;
	
	if change > self.maxchange then
		--If it is, spawn the dust particle.
		local dust = CreateMOSParticle("Fuel Flame");
		dust.Pos = self.Pos;
		MovableMan:AddParticle(dust);
	end

	self.lastvel = Vector(self.Vel.X,self.Vel.Y);
end



	