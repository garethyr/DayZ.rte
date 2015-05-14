function Create(self)
	---------------------------------------------------------------------------------
	--The name of the global variable for the activity we want to try to add alert to
	self.ActivityToCheck = ModularActivity;
	---------------------------------------------------------------------------------
	
	self.GenericName = self.PresetName;
	self.ManualRevealSize = 0;
	if string.find(self.PresetName,"Chemlight") then
		self.ManualRevealSize = 300;
		self.GenericName = "Chemlight";
	elseif string.find(self.PresetName, "Flare") then
		self.ManualRevealSize = 600;
		self.GenericName = "Flare";
	end
	--Set the lifetime based on the LifetimeMult and the item's reveal size, either in activity or defined here
	self.LifetimeMult = 20;
	if self.ActivityToCheck and self.ActivityToCheck.IncludeDayNight then
		self.Lifetime = self.LifetimeMult*self.ActivityToCheck.DayNightLightItemBaseRevealSize[self.GenericName];
	else
		self.Lifetime = self.LifetimeMult*self.ManualRevealSize;
	end
	
	--State is used internally and UseState is updated to match it for communication with the activity
	--Values: 0 - not used yet, 1 - used and unheld, 2 - used and held
	self.State = 0;
	self:SetNumberValue("UseState", self.State); --Used for communicating state to DayZ
	self:SetNumberValue("OverrideTargetPriority", 0); --Used for overriding alerts for zombies in DayZ
	
	--A table for the light particles, only used when not in ModularActivity
	self.LightParticles = {};
end
function Update(self)
	--Sharpness values: 0 - not activated, 1 - activated and detached, 2 - activated and attached
	--Illuminate the area when it's activated, reset its age when it's not
	if self.State == 0 then
		self.Age = 0;
		if self:IsActivated() and not self:IsAttached() then
			self.State = 1;
			self:SetNumberValue("OverrideTargetPriority", 1);
		end
	else
		--Ensure the item deletes itself when it's past its lifetime, even if it's held
		if self.Age > self.Lifetime then
			self.ToDelete = true;
		end
		--If its State isn't 0, it's been thrown so add an alert for it if needed
		if self.ActivityToCheck ~= nil and self.ActivityToCheck.IncludeAlerts and self.ActivityToCheck.AlertItemTable[self.UniqueID] ~= nil and self.ActivityToCheck.AlertTable[self.UniqueID] == nil and self.State == 1 then
			self.ActivityToCheck:AddAlertFromAlertItem(self);
		end
		--Handle sharpness if the item is picked up after being thrown
		if self.State == 1 and self:IsAttached() then
			self.State = 2;
		--Handle sharpness if the item is thrown again after being picked up
		elseif self.State == 2 and not self:IsAttached() then
			self.State = 1;
		end
		--If it's moving and it's not ModularActivity, light up the place
		if self.Vel.Magnitude > 0.5 then
			--Lets the item reveal fog on non Modular activities, and lets it make light
			if self.ActivityToCheck == nil or not self.ActivityToCheck.IncludeDayNight then
				DoManualLighting(self);
			end
		--If it's not moving, set it to stop overriding target priority
		else
			self:SetNumberValue("OverrideTargetPriority", 0);
		end
	end
	self:SetNumberValue("UseState", self.State)
end
function DoManualLighting(self)
	for i = 0, ToGameActivity(ActivityMan:GetActivity()).TeamCount do
		SceneMan:RevealUnseenBox(self.Pos.X - self.RevealSize/2, self.Pos.Y - self.RevealSize/2, self.RevealSize, self.RevealSize, i);
	end
	ReMakeLightParticles(self);
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
function Destroy(self)
	print ("Light.lua - OBJECT DESTROYED, Age: "..tostring(self.Age)..", Lifetime: "..tostring(self.Lifetime));
end