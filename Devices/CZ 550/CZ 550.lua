function Create(self)
	self.name = "CZ 550"

	self.recoilrisefactor = 0.1 --radians
	self.recoilriserecovery = 0.1 --radians per second
	self.recoilrise = 0
	
	self.recoilspreadfactor = 0.28 --radians
	self.recoilspreadrecovery = 1.0 --radians per second
	self.recoilspread = 0
	self.reloadendspread = 0.35
	
	self.recoilsharplengthfactor = 20 --px
	self.recoilsharplengthrecovery = 250 --px/s
	self.recoilsharplengthoriginal = 625 --original aim distance
	
	self.recoiltimer = Timer()
	
	self.basemass = 10 --weight of gun
	self.roundmass = 0.03 --weight of a round
	
	self.CyclingTimer = Timer()
	self.CyclingMS = 1000 --ms
	self.RoundChambered = false
	self.CycleNoiseEmitter = "Manual Cycle Sound"
	self.Module = "DayZ.rte"
	
	self.ammobox = "9.3x62 Mauser Rounds"
	self.roundsperbox = 5
	
	--------------------------------
	--Shot by shot reloading start--
	--------------------------------
	self.reloadTimer = Timer();
	self.loadedShell = false;
	self.reloadCycle = false;

	self.reloadDelay = 500;

	if self.Magazine then
		self.ammoCounter = self.Magazine.RoundCount;
	else
		self.ammoCounter = 0;
	end
	------------------------------
	--Shot by shot reloading end--
	------------------------------
end

function Update(self)
	--determine the root object.
	if self.RootID ~= 255 then
		self.y = MovableMan:GetMOFromID(self.RootID)
		if self.y then
			if self.y:IsActor() then
				self.z = ToActor(MovableMan:GetMOFromID(self.RootID))
				
				--------------------------------
				--Shot by shot reloading start--
				--------------------------------
				if self.Magazine ~= nil then
					if self.loadedShell == false then
						self.ammoCounter = self.Magazine.RoundCount;
						--Make sure we don't lose ammo through reloading when we only have the bullets in the gun left.
						if self.Sharpness <= self.Magazine.Capacity and self.Sharpness <= self.Magazine.RoundCount then
							self.ammoCounter = self.Magazine.RoundCount - 1;
							self.reloadCycle = false;
						end
					else
						self.loadedShell = false;
						self.Magazine.RoundCount = self.ammoCounter + 1;
					end
				else
					self.reloadTimer:Reset();
					--Start reload cycle if we've got more than 1 clip of bullets or more bullets in pocket than in gun
					if self.Sharpness > self.ammoCounter then
						self.reloadCycle = true;
					end
					self.loadedShell = true;
				end

				if self:IsActivated() then
					self.reloadCycle = false;
				end

				--Make sure we only try to reload when there's ammo in the ammo pool
				if self.reloadCycle == true and self.reloadTimer:IsPastSimMS(self.reloadDelay) and self:IsFull() == false and self.Sharpness > 0 then
					self.z:GetController():SetState(Controller.WEAPON_RELOAD,true);
				end
				------------------------------
				--Shot by shot reloading end--
				------------------------------
				
				if self.Magazine then
				
					--JUST RELOADED? Detect if this is the first script update where the magazine's existed 
					self.justreloaded = false
					if self.hasmag == false then
						self.justreloaded = true
						--RELOAD RECOIL RECOVER when there's a new mag and no manual round chambering is needed, point the rifle at the aim position again immediately and add some shake because the actor's weapon manipulation has thrown off his aim, so firing as soon as possible afterward won't be accurate.
						if self.RoundChambered == true then
							self.recoilrise = 0
							self.SharpLength = self.recoilsharplengthoriginal
							self.recoilspread = self.reloadendspread
						end
					end
					self.hasmag = true
					
					--MAGCOUNT NIL? Without this, the script thinks the gun jsut fired when the map gets reloaded, because the map reloading nullified this var.
					if self.magcount == nil then
						self.magcount = self.Magazine.RoundCount
					end
				
					--JUST FIRED? Determine if, since the last script update, the gun was fired, through detecting a decrease in the mag's round count
					if self:IsReloading() then
						self.justfired = 0
					else
						if self.magcount ~= self.Magazine.RoundCount and self.justreloaded == false then
							self.justfired = 1
							if self.Magazine.RoundCount == 0 and self.Sharpness > 1 then
								self.RoundChambered = false
							else
								self.RoundChambered = true
							end
							
							self.Sharpness = self.Sharpness - 1
						else
							self.justfired = 0
							--LIMIT MAG. if the total ammo is less than what's loaded, change what's loaded to be the total
							if math.floor(self.Sharpness) < self.Magazine.RoundCount then
								self.Magazine.RoundCount = math.floor(self.Sharpness)
							end
						end
						
						
						
						--CHAMBERED ROUND? If there wasn't a round chambered when you reloaded, there is a penalty of additional reloading time and 1 capacity. Really, an already chambered round is more like a bonus, but in CC it works better to handle it this way; reload time can't be shortened, and you can't reload when the game thinks you're at full capacity.
						if self.justreloaded == true then
							if not self.RoundChambered then
								self.CyclingTimer:Reset()
								self.RoundChambered = true
								if math.floor(self.Magazine.RoundCount) ~= math.floor(self.Sharpness) then
									self.Magazine.RoundCount = self.Magazine.RoundCount - 0
								end
								self.b = CreateAEmitter(self.CycleNoiseEmitter,self.Module)
								self.b.Pos = self.Pos
								MovableMan:AddParticle(self.b)
							end
						end
						
						--MANUALLY CHAMBER ROUND DELAY. Delay before firing, for chambering the round.
						if self.CyclingTimer.ElapsedSimTimeMS < self.CyclingMS then
							self:Deactivate()
							--RELOADING RECOIL RECOVERY, stop pointing the weapon upwards now that reloading is finishing, but all this weapon manipulation will cause some inaccuracy if you fire before allowing the actor to reaccquire the target.
							if self.recoilrise > 0 then
								self.recoilrise = self.recoilrise - 0.2
							end
							self.recoilspread = self.reloadendspread
						end
						
						--AI LAST SHOT? AI actors worth over 100 "know" it's better to reload before firing the last round, so they don't need to manually cycle the weapon. 
						self.ailastshot = true
						if self.z:IsPlayerControlled() == false and self.z:GetGoldValue(0,0) > 100 and self.Magazine.RoundCount == 1 and self.Sharpness > 1 then
							self.z:GetController():SetState(Controller.WEAPON_RELOAD,true)
							self:Deactivate()
							self.ailastshot = false
						end
						
						--NO INFINITE just in case any of the weapons happen to want to go all hollywood on us
						if self.Sharpness < 0 or self.Magazine.RoundCount < 0 then
							self.Sharpness = 0
							self.Magazine.RoundCount = 0
						end
						
						self.magcount = self.Magazine.RoundCount
					end
				else--NO MAG
				
					self.hasmag = false
					self.justfired = 0
					
					--AI LAST SHOT AMMO LOSS, because AI relaod after firing their last round too quickly for scripts to detect roundcount having ever been 0
					if self.z:IsPlayerControlled() == false and self.ailastshot == true and self.recoiltimer.ElapsedSimTimeMS < 75 then
						self.Sharpness = self.Sharpness - 1
						self.ailastshot = false
						if self.Sharpness > 1 then
							self.RoundChambered = false
						end
					end
					
					--RELOADING RECOIL, tilts the gun while reloading. Looks nice, I think, and makes relaoding more obvious, compensating for SE weapons having nondiscardable mags.
					self.SharpLength = 0
					if self.recoilrise < 0.6 then
						self.recoilrise = self.recoilrise + 0.2
					end
				end
				
				
				
				
				
					--Recoil
						--add recoils
				if self.justfired == 1 then
					self.recoilrise = self.recoilrise  + self.recoilrisefactor
					self.recoilspread = self.recoilspread + self.recoilspreadfactor
					self.SharpLength = self.SharpLength - self.recoilsharplengthfactor
				end
						--recover from rise
				if self.recoilrise < (self.recoilriserecovery * self.recoiltimer.ElapsedSimTimeS) and self.recoilrise > -(self.recoilriserecovery * self.recoiltimer.ElapsedSimTimeS) then		
					self.recoilrise = 0
				elseif self.recoilrise > 0 then --if recoil's above 0, there's still recoil to recover from
					self.recoilrise = (self.recoilrise - (self.recoilriserecovery * self.recoiltimer.ElapsedSimTimeS)) * 0.98
				elseif self.recoilrise < 0 then
					self.recoilrise = (self.recoilrise + (self.recoilriserecovery * self.recoiltimer.ElapsedSimTimeS)) * 0.98
				end
						--recover from shake
				if self.recoilspread < (self.recoilspreadrecovery * self.recoiltimer.ElapsedSimTimeS) and self.recoilspread > -(self.recoilspreadrecovery * self.recoiltimer.ElapsedSimTimeS) then		
					self.recoilspread = 0
				elseif self.recoilspread > 0 then
					self.recoilspread = (self.recoilspread - (self.recoilspreadrecovery * self.recoiltimer.ElapsedSimTimeS)) * 0.98
				elseif self.recoilspread < 0 then
					self.recoilspread = (self.recoilspread + (self.recoilspreadrecovery * self.recoiltimer.ElapsedSimTimeS)) * 0.98
				end
						--recover from sharp length decrease
				if self.SharpLength < (self.recoilsharplengthoriginal - (self.recoilsharplengthrecovery / 1000)) then
					self.SharpLength = self.SharpLength + (self.recoilsharplengthrecovery * self.recoiltimer.ElapsedSimTimeS)
				elseif self.SharpLength < 0 then
					self.SharpLength = 0
					self.z:GetController():SetState(Controller.AIM_SHARP,false);
				else
					self.SharpLength = self.recoilsharplengthoriginal
				end
						--actually recoil
				if self.z.HFlipped == true then	-- Facing Left
					self.RotAngle = self.RotAngle + (math.random(-self.recoilspread * 1000, self.recoilspread * 1000)/1000)
					self.RotAngle = self.RotAngle  - self.recoilrise
				else	-- Right
					self.RotAngle = self.RotAngle + (math.random(-self.recoilspread * 1000, self.recoilspread * 1000)/1000)
					self.RotAngle = self.RotAngle  + self.recoilrise
				end
				self.recoiltimer:Reset()
				
				
				--displays the ammo
				if self.z:IsPlayerControlled() then
					self.b = CreateHeldDevice("Null Device","DayZ.rte")
					if math.floor(self.Sharpness) > 0 then
						self.b.PresetName = math.floor(self.Sharpness).." Rds"
					else
						self.b.PresetName = "Empty!"
					end
					self.b.Vel = self.y.Vel
					self.b.Pos.X = self.y.Pos.X
					if self.y:IsDevice() then
						self.b.Pos.Y = self.y.Pos.Y + 36
					else
						self.b.Pos.Y = self.y.Pos.Y - 2
					end
					self.b:SetWhichMOToNotHit(self.y, -1)
					MovableMan:AddParticle(self.b)
				end
				
				
				--EMPTY guns get replaced with a held device, if the actor has no ammo and the player isn't controlling it
				if self.PresetName == self.name and self.Sharpness == 0 and not self.z:HasObject(self.ammobox) and not self.z:IsPlayerControlled() then
					self.Lifetime = 1
					self.PresetName = "Nope"
					self.e = CreateHeldDevice(("Empty ".. self.name),"DayZ.rte")
					self.e.Sharpness = 0
					self.z:AddInventoryItem(self.e)
				end
				--if this is an empty variant and you either have ammo or are player controlled, become a regular gun
				if self.PresetName == ("Empty ".. self.name) then
					if self.z:HasObject(self.ammobox) or self.z:IsPlayerControlled() then
						self.Lifetime = 1
						self.PresetName = "Nope"
						self.f = CreateHDFirearm(self.name,"DayZ.rte")
						self.f.Sharpness = 0
						self.z:AddInventoryItem(self.f)
					end
				end
				
				
			else --if y is not an actor, the device must be dropped
			
				--[[drop ammo if unheld and has enough ammo
				if self.Sharpness > self.roundsperbox then
					self.Sharpness = self.Sharpness - self.roundsperbox
					self.k = CreateHeldDevice(self.ammobox,"Shadow Echelon.rte")
					self.k.Vel.X = self.Vel.X + math.random(-100, 100)/300
					self.k.Vel.Y = self.Vel.Y - 3
					self.k.Pos = self.Pos
					self.k:SetWhichMOToNotHit(self.y, -1)
					MovableMan:AddParticle(self.k)
				end]]
			
			end
			
			
			
		end
	end
	self.Mass = self.basemass + self.roundmass *  math.floor(self.Sharpness)

end
function Destroy(self)
	self.found = 4
	for particle in MovableMan.Particles do
		if particle.PresetName == "DayZ Device Gibbed" then
			if self.found > (particle.Pos - self.Pos).Magnitude then
				if self.ToDelete == true then
					self.partList = {}
					for i = 1, math.ceil(self.Sharpness/self.roundsperbox) do
						if self.Sharpness > self.roundsperbox then
							self.Sharpness = self.Sharpness - self.roundsperbox
							self.partList[i] = CreateHeldDevice(self.ammobox,"DayZ.rte")
							self.partList[i].Vel = self.Vel
							self.partList[i].Pos = self.Pos
							MovableMan:AddParticle(self.partList[i])
						end
					end
				end
			end
		end
	end
end