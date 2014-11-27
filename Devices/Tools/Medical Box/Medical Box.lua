function Create(self)
	self.maxcopyitems = 15; -- maximum number of items to copy from the original actor
	self.sameitem = false;

	self.curdist = 20
   for i = 1,MovableMan:GetMOIDCount()-1 do
   	self.gun = MovableMan:GetMOFromID(i);
    if self.gun.PresetName == "Medical Box" and self.gun.ClassName == "HDFirearm" and (self.gun.Pos-self.Pos).Magnitude < self.curdist then
   	self.actor = MovableMan:GetMOFromID(self.gun.RootID);
     if MovableMan:IsActor(self.actor) then
	self.parent = ToActor(self.actor);
	self.parentname = self.parent.PresetName;
	self.repairedactor = CreateAHuman(self.parentname);

	self.itemblocker = CreateTDExplosive("Stone","Ronin.rte");
	self.itemblocker.PresetName = "Medical Box Blocker Rock";
	self.parent:AddInventoryItem(self.itemblocker);

	self.parent:GetController():SetState(Controller.WEAPON_CHANGE_PREV,true);

--	self.inventorychecker = self.parent:Inventory();
--      if self.inventorychecker ~= nil then
--	self.parent:SwapNextInventory(self.inventorychecker,true);
--      end

      for i = 1, self.maxcopyitems do

	self.potentialwep = self.parent:Inventory();
       if self.potentialwep ~= nil and self.potentialwep.PresetName ~= "Medical Box Blocker Rock" then

        if self.potentialwep.ClassName == "HDFirearm" then
	self.repairedactor:AddInventoryItem(CreateHDFirearm(self.potentialwep.PresetName));
        elseif self.potentialwep.ClassName == "TDExplosive" then
	self.repairedactor:AddInventoryItem(CreateTDExplosive(self.potentialwep.PresetName));
        elseif self.potentialwep.ClassName == "HeldDevice" then
	self.repairedactor:AddInventoryItem(CreateHeldDevice(self.potentialwep.PresetName));
        end

	self.parent:SwapNextInventory(self.potentialwep,true);
       else
	break;
       end
      end

      if self.parent:IsPlayerControlled() == true then
	self.parentplayer = self.parent:GetController().Player;
      end

	self.repairedactor.Pos = self.parent.Pos;
	self.repairedactor.Team = self.parent.Team;
	self.repairedactor.AIMode = Actor.AIMODE_SENTRY;
	self.parent.ToDelete = true;
	MovableMan:AddActor(self.repairedactor);
      if self.parentplayer ~= nil then
	ActivityMan:GetActivity():SwitchToActor(self.repairedactor,self.parentplayer,self.repairedactor.Team);
      end
	local sparticle = CreateAEmitter("Medical Box Sound Repair","DayZ.rte");
	sparticle.Pos = self.repairedactor.Pos;
	MovableMan:AddParticle(sparticle);
--	self.repairedactor:FlashWhite(610);
	ActivityMan:GetActivity():ReportDeath(self.repairedactor.Team,-1);

     end
    end
   end

	self.ToDelete = true;
end