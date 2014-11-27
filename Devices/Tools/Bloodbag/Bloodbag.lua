function Create(self)
	self.curdist = 20
   for i = 1,MovableMan:GetMOIDCount()-1 do
   	self.gun = MovableMan:GetMOFromID(i);
    if self.gun.PresetName == "Bloodbag" and self.gun.ClassName == "HDFirearm" and (self.gun.Pos-self.Pos).Magnitude < self.curdist then
   	self.actor = MovableMan:GetMOFromID(self.gun.RootID);
     if MovableMan:IsActor(self.actor) then
	self.parent = ToActor(self.actor);
	self.parentgun = ToHDFirearm(self.gun);
      if self.parent.Health < 100 then
	self.parentgun.ToDelete = true;
--	self.parent:FlashWhite(760);
	local sparticle = CreateAEmitter("Bloodbag Sound Heal","DayZ.rte");
	sparticle.Pos = self.parent.Pos;
	MovableMan:AddParticle(sparticle);
       if self.parent.Health <= 0 then
       self.parent.Health = self.parent.Health + 100;
       else
       self.parent.Health = 100;
       end
      end
     end
    end
   end
	self.ToDelete = true;
end