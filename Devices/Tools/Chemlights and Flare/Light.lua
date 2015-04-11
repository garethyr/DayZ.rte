function Create(self)
	self.LightParticles = {};
	if string.find(self.PresetName,"Chemlight") then
		self.RevealSize = 300;
	elseif string.find(self.PresetName, "Flare") then
		self.RevealSize = 600;
	end
	self.State = 0;
	self.Lifetime = self.RevealSize*20; --Lifetime is in MS, based on item strength
end
--A function to remake the light so it can keep up to the moving object
function ReMakeLightParticles(self)
	for k, v in pairs(self.LightParticles) do
		v.ToDelete = true;
		self.LightParticles[k] = nil;
	end
	local particlename = "";
	if string.find(self.PresetName,"Chemlight") then
		particlename = "Chemlight "..string.gsub(self.PresetName, " Chemlight", "").." Emitter";
	elseif string.find(self.PresetName, "Flare") then
		particlename = "Flare Emitter";
	end
	for i = 1, 2 do
		self.LightParticles[i] = CreateAEmitter(particlename, "DayZ.rte");
		self.LightParticles[i].Pos = self.Pos;
		self.LightParticles[i].Lifetime = self.Lifetime;
		MovableMan:AddParticle(self.LightParticles[i]);
	end
end
function Update(self)
	--Sharpness values: 0 - not activated, 1 - activated and detached, 2 - activated and attached
	--Illuminate the area when it's activated, reset its age when it's not
	if self.Sharpness == 0 then
		self.Age = 0;
		if self:IsActivated() and not self:IsAttached() then
			self.Sharpness = 1;
		end
	else
		--If its sharpness isn't 0, add an alert for it
		if ModularActivity ~= nil and ModularActivity.IncludeAlerts and ModularActivity.AlertItemTable[self.UniqueID] ~= nil then
			ModularActivity:AddAlertFromAlertItem(self);
		end
		--Handle sharpness if the item is picked up or thrown
		if self.Sharpness == 1 and self:IsAttached() then
			self.Sharpness = 2;
			print ("Light item picked up, set Sharpness to 2");
		elseif self.Sharpness >= 2 and not self:IsAttached() then
			self.Sharpness = 1;
			print ("Light item thrown again, set Sharpness to 1");
		end
		--Do active stuff if the item is moving
		if self.Vel.Magnitude > 0.5 then
			--Lets the item reveal fog on non Modular activities, and lets it make light
			if ModularActivity == nil then
				for i = 0, ToGameActivity(ActivityMan:GetActivity()).TeamCount do
					SceneMan:RevealUnseenBox(self.Pos.X - self.RevealSize/2, self.Pos.Y - self.RevealSize/2, self.RevealSize, self.RevealSize, i);
				end
			end
			--ReMakeLightParticles(self);
		end
	end
end
function Destroy(self)
	print ("Light.lua - OBJECT DESTROYED, Age: "..tostring(self.Age)..", Lifetime: "..tostring(self.Lifetime));
end