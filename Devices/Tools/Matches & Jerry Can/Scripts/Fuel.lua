function Create(self)
	self.Timer = Timer()

end

function Update(self)

	self.mapwrapx = SceneMan.SceneWrapsX;

	for particle in MovableMan.Particles do
		if (particle.ClassName == "MOPixel" or particle.ClassName == "MOSParticle" or particle.ClassName == "MOSRotating" or particle.ClassName == "AEmitter") and ( (string.find(particle.PresetName,"Fire") ~= nil) or (string.find(particle.PresetName,"Burn") ~= nil) or (string.find(particle.PresetName,"Pyro") ~= nil) or 
(string.find(particle.PresetName,"Flame") ~= nil) or (string.find(particle.PresetName,"Napalm") ~= nil) or (string.find(particle.PresetName,"Spark") ~= nil) ) and self.Timer:IsPastSimMS(1000) then 
			if SceneMan:ShortestDistance(self.Pos,particle.Pos,self.mapwrapx).Magnitude < 20 then
				self.ToDelete = true;
			local flame = CreateMOSParticle("Flame 1 Hurt", "DayZ.rte");
			flame.Pos = self.Pos;
			flame.Vel = self.Vel;
			local flame = CreateMOSParticle("Flame 1 Hurt", "DayZ.rte");
			flame.Pos = self.Pos;
			flame.Vel = self.Vel;
			MovableMan:AddParticle(flame);
			local sound = CreateMOSRotating("Fuel Igniting Sound", "DayZ.rte");
			sound.Pos = self.Pos;
			MovableMan:AddParticle(sound);
			sound:GibThis();
			local smoke = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte");
			smoke.Pos = self.Pos;
			smoke.Vel = Vector((math.random()*3)+3,0):RadRotate(math.random()*6.3728);
			MovableMan:AddParticle(smoke);
			end
		end
	end

end