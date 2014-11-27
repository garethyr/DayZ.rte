function Create(self)
	self.Timer = Timer()
end

function Update(self)

	self.mapwrapx = SceneMan.SceneWrapsX;

	for particle in MovableMan.Particles do
		if ( (string.find(particle.PresetName,"Fire") ~= nil) or (string.find(particle.PresetName,"Burn") ~= nil) or (string.find(particle.PresetName,"Pyro") ~= nil) or 
(string.find(particle.PresetName,"Flame") ~= nil) or (string.find(particle.PresetName,"Napalm") ~= nil) or (string.find(particle.PresetName,"Spark") ~= nil) or (string.find(particle.PresetName,"Blast") ~= nil) or(string.find(particle.PresetName,"Muzzle Flash") ~= nil) )  and self.Timer:IsPastSimMS(1500) then 
			if SceneMan:ShortestDistance(self.Pos,particle.Pos,self.mapwrapx).Magnitude < 40 then
				self.ToDelete = true;
				particle.ToDelete = true;
				local i;
				for i = 1,1 do
				local sound = CreateMOSRotating("Gas Igniting Sound", "DayZ.rte")
				sound.Pos = self.Pos;
				MovableMan:AddParticle(sound);
				sound:GibThis();
				local igniting = CreateMOPixel("Matches Spark", "DayZ.rte")
				igniting.Pos = self.Pos;
				--igniting.Vel = Vector((math.random()*3)+10,0):RadRotate(math.random()*6.3728);
				MovableMan:AddParticle(igniting);
				end
				for i = 1,1 do
				local flame = CreateMOSParticle("Gas Fumes", "DayZ.rte")
				flame.Pos = self.Pos;
				flame.Vel = Vector((math.random()*6)+6,0):RadRotate(math.random()*2.3728);
				--flame.Vel = self.Vel*3;
				MovableMan:AddParticle(flame);
				end
			end
		end
	end
end