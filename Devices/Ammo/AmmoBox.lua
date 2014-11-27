function Create(self)

	if self.PresetName == "Makarov PM Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Makarov PM"
		self.Items[1]["AmmoPerBox"] = 8
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Makarov PM"
		self.Items[2]["AmmoPerBox"] = 8
		
		self.replacebox = "Makarov PM Magazine"
		
	elseif self.PresetName == ".45 ACP Speedloader" then

		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = ".45 Revolver"
		self.Items[1]["AmmoPerBox"] = 6
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] .45 Revolver"
		self.Items[2]["AmmoPerBox"] = 6
	
		self.replacebox = ".45 ACP Speedloader"
	
	elseif self.PresetName == "M1911A1 Magazine" then

		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M1911A1"
		self.Items[1]["AmmoPerBox"] = 7
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M1911A1"
		self.Items[2]["AmmoPerBox"] = 7
	
		self.replacebox = "M1911A1 Magazine"
		
	elseif self.PresetName == "G17 Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "G17"
		self.Items[1]["AmmoPerBox"] = 17

		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] G17"
		self.Items[2]["AmmoPerBox"] = 17
		
		self.replacebox = "G17 Magazine"
		
	elseif self.PresetName == "Metal Bolt" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Compound Crossbow"
		self.Items[1]["AmmoPerBox"] = 2
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Compound Crossbow"
		self.Items[2]["AmmoPerBox"] = 2
		
		self.replacebox = "Metal Bolts"
		
	elseif self.PresetName == "12 Gauge Buckshot (2)" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "MR43"
		self.Items[1]["AmmoPerBox"] = 2

		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] MR43"
		self.Items[2]["AmmoPerBox"] = 2

		self.replacebox = "12 Gauge Buckshot (2)"
		
	elseif self.PresetName == ".44 Henry Rounds" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Winchester 1866"
		self.Items[1]["AmmoPerBox"] = 15

		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Winchester 1866"
		self.Items[2]["AmmoPerBox"] = 15
		
		self.replacebox = ".44 Henry Rounds"
		
	elseif self.PresetName == "Lee Enfield Stripper Clip" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Lee Enfield"
		self.Items[1]["AmmoPerBox"] = 5
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Lee Enfield"
		self.Items[2]["AmmoPerBox"] = 5
		
		self.replacebox = "Lee Enfield Stripper Clip"
		
	elseif self.PresetName == "AKM Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "AKM"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] AKM"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "AKM Magazine"
		
	elseif self.PresetName == "STANAG Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M16A2"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M16A2"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "STANAG Magazine"
		
	elseif self.PresetName == "MP5SD6 Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "MP5SD6"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] MP5SD6"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "MP5SD6 Magazine"
		
	elseif self.PresetName == "STANAG SD Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M4A1 CCO SD"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M4A1 CCO SD"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "STANAG SD Magazine"
		
	elseif self.PresetName == "M240 Belt" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Mk 48 Mod 0"
		self.Items[1]["AmmoPerBox"] = 100
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Mk 48 Mod 0"
		self.Items[2]["AmmoPerBox"] = 100
		
		self.replacebox = "M240 Belt"
		
	elseif self.PresetName == "DMR Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M14 AIM"
		self.Items[1]["AmmoPerBox"] = 20
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M14 AIM"
		self.Items[2]["AmmoPerBox"] = 20
		
		self.replacebox = "DMR Magazine"
		
	elseif self.PresetName == "9.3x62 Mauser Rounds" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "CZ 550"
		self.Items[1]["AmmoPerBox"] = 5
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] CZ 550"
		self.Items[2]["AmmoPerBox"] = 5
		
		self.replacebox = "9.3x62 Mauser Rounds"
		
	elseif self.PresetName == "M107 Magazine" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M107"
		self.Items[1]["AmmoPerBox"] = 10
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M107"
		self.Items[2]["AmmoPerBox"] = 10
		
		self.replacebox = "M107 Magazine"
		
	end
end

function Update(self)
	--being dropped resets the "try applying ammo" indicator: sharpness
	if self.RootID == self.ID and self.Sharpness == 3 then
		self.Sharpness = 2
	elseif self.Sharpness == 2 then
		self.Sharpness = 1
		if self.RootID ~= self.ID then
			self.Sharpness = 3
		end
	end
	--make checking not go full auto if done via mouse click
	if self:IsActivated() then
		if self.nofullautochecks == 1 then
			self.Sharpness = 1
		end
		self.nofullautochecks = 0
	else
		self.nofullautochecks = 1
	end
	--determine the roots, self existance etc
	if self.RootID ~= 255 then
		self.y = MovableMan:GetMOFromID(self.RootID)
		if self.y then
			if self.y:IsActor() then
				self.z = ToActor(MovableMan:GetMOFromID(self.RootID))
				if self.z then
					if self.z:IsInventoryEmpty() == false then
						--if we've got an actor holding it and it is primed for being added, try to add ammo by gibbing and making the ammo adder
						if self.Sharpness == 1 then
							self:GibThis()
							self.Sharpness = 2
							self.z:GetController():SetState(Controller.WEAPON_CHANGE_PREV,true)
							if self.PresetName == "Makarov PM Magazine" then
								self.b = CreateMOPixel("Makarov PM Ammo Adder","DayZ.rte")
							elseif  self.PresetName == ".45 ACP Speedloader" then
								self.b = CreateMOPixel("Revolver Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "M1911A1 Magazine" then
								self.b = CreateMOPixel("M1911A1 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "G17 Magazine" then
								self.b = CreateMOPixel("G17 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "Metal Bolts" then
								self.b = CreateMOPixel("Compound Crossbow Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "12 Gauge Buckshot (2)" then
								self.b = CreateMOPixel("MR43 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == ".44 Henry Rounds" then
								self.b = CreateMOPixel("Winchester 1866 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "Lee Enfield Stripper Clip" then
								self.b = CreateMOPixel("Lee Enfield Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "AKM Magazine" then
								self.b = CreateMOPixel("AKM Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "STANAG Magazine" then
								self.b = CreateMOPixel("M16A2 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "MP5SD6 Magazine" then
								self.b = CreateMOPixel("MP5SD6 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "STANAG SD Magazine" then
								self.b = CreateMOPixel("M4A1 CCO SD Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "M240 Belt" then
								self.b = CreateMOPixel("Mk 48 Mod 0 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "DMR Magazine" then
								self.b = CreateMOPixel("M14 AIM Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "9.3x62 Mauser Rounds" then
								self.b = CreateMOPixel("CZ 550 Ammo Adder","DayZ.rte")
							elseif  self.PresetName == "M107 Magazine" then
								self.b = CreateMOPixel("M107 Ammo Adder","DayZ.rte")
							end
							--self.b.PresetName = self.z.PresetName
							self.b.Sharpness = self.z.ID
							self.b.Pos.X = self.z.Pos.X
							self.b.Pos.Y = -10
							MovableMan:AddParticle(self.b)
						end
					else
						self.Sharpness = 3
					end
				end
			end
		end
	end
	
	--[[autoapply to bots
	if self.ID == self.RootID and math.random(0,20) < 2 then
		
		self.found = 20
		self.checkvector = Vector(self.Pos.X, self.Pos.Y - 20)
		for actor in MovableMan.Actors do
			if self.found > (actor.Pos - self.checkvector).Magnitude then
				self.z = actor
				if actor.EquippedItem() then
					for b = 1, #self.Items do
						if self.Items[b]["PresetName"] == self.holding.PresetName then
							self.holding.Sharpness = self.holding.Sharpness + self.Items[b]["AmmoPerBox"]
--									print("Added ".. self.Items[b]["AmmoPerBox"] .." rounds to ".. self.operator.PresetName .."'s ".. self.Items[b]["PresetName"] ..", Deleting Adder Particle")
							self.Sharpness = 255
							self.Lifetime = 1
						end
					end
				end
			end
		end
	end]]
end