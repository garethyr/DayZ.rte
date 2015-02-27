--All the setup for easy parent checks
function SetupParent(self)
	self.Parent = nil;
	if self.RootID ~= 255 and self.RootID ~= self.ID and MovableMan:IsActor(MovableMan:GetMOFromID(self.RootID)) then
		self.Parent = ToActor(MovableMan:GetMOFromID(self.RootID));
	end
end
--All the update for easy parent checks
function HasParent(self)
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
		--Just in case, if the parent doesn't exist, set parent as nil
		elseif not MovableMan:IsActor(self.Parent) or self.RootID == self.ID then
			self.Parent = nil;
			return false;
		end
		--Return true since we do have a parent
		return true;
	end
	return false;
end



-----------------------------------------------------------
--TODO: Move this to a global script in the next version!--
-----------------------------------------------------------

-------------------
--Disable Weapons--
-------------------
--Stop an actor from firing
function DisableFiring(actor)
	actor:GetController():SetState(Controller.WEAPON_FIRE,false);
end
--Stop an actor from reloading
function DisableReloading(actor)
	actor:GetController():SetState(Controller.WEAPON_RELOAD,false);
end
--Stop an actor from picking up or dropping weapons
function DisablePickupAndDrop(actor)
	actor:GetController():SetState(Controller.PIE_MENU_ACTIVE,false);
	actor:GetController():SetState(Controller.WEAPON_DROP,false);
	actor:GetController():SetState(Controller.WEAPON_PICKUP,false);
end
--Stop an actor from swappning weapons
function DisableWeaponSwap(actor)
	actor:GetController():SetState(Controller.PIE_MENU_ACTIVE,false);
	actor:GetController():SetState(Controller.WEAPON_CHANGE_PREV,false);
	actor:GetController():SetState(Controller.WEAPON_CHANGE_NEXT,false);
end
--Stop an actor from performing any weapon actions (i.e. all of the above)
function DisableAllWeaponActions(a)
	for actor in MovableMan.Actors do
	DisableFiring(actor);
	DisableReloading(actor);
	DisablePickupAndDrop(actor);
	DisableWeaponSwap(actor);
	end
end

--------------------
--Disable Movement--
--------------------
--Stop an actor from moving
function DisableMoving(actor)
	actor:GetController():SetState(Controller.MOVE_LEFT,false);
	actor:GetController():SetState(Controller.MOVE_RIGHT,false);
end
--Stop an actor from jumping
function DisableJumping(actor)
	actor:GetController():SetState(Controller.BODY_JUMPSTART,false);
	actor:GetController():SetState(Controller.BODY_JUMP,false);
end
--Stop an actor from crouching
function DisableCrouching(actor)
	actor:GetController():SetState(Controller.BODY_CROUCH,false);
end
--Stop an actor from performing any movement actions (i.e. all of the above)
function DisableAllMovementActions(actor)
	DisableMoving(actor);
	DisableJumping(actor);
	DisableCrouching(actor);
end