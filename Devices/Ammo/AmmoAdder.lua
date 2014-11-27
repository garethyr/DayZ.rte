function Create(self)

	if self.PresetName == "Makarov PM Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Makarov PM"
		self.Items[1]["AmmoPerBox"] = 8
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Makarov PM"
		self.Items[2]["AmmoPerBox"] = 8
		
		self.replacebox = "Makarov PM Magazine"
		
	elseif self.PresetName == "Revolver Ammo Adder" then

		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = ".45 Revolver"
		self.Items[1]["AmmoPerBox"] = 6
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] .45 Revolver"
		self.Items[2]["AmmoPerBox"] = 6
	
		self.replacebox = ".45 ACP Speedloader"
	
	elseif self.PresetName == "M1911A1 Ammo Adder" then

		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M1911A1"
		self.Items[1]["AmmoPerBox"] = 7
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M1911A1"
		self.Items[2]["AmmoPerBox"] = 7
	
		self.replacebox = "M1911A1 Magazine"
		
	elseif self.PresetName == "G17 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "G17"
		self.Items[1]["AmmoPerBox"] = 17
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] G17"
		self.Items[2]["AmmoPerBox"] = 17
		
		self.replacebox = "G17 Magazine"
		
	elseif self.PresetName == "Compound Crossbow Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Compound Crossbow"
		self.Items[1]["AmmoPerBox"] = 2
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Compound Crossbow"
		self.Items[2]["AmmoPerBox"] = 2
		
		self.replacebox = "Metal Bolts"
		
	elseif self.PresetName == "MR43 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "MR43"
		self.Items[1]["AmmoPerBox"] = 2
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] MR43"
		self.Items[2]["AmmoPerBox"] = 2
		
		self.replacebox = "12 Gauge Buckshot (2)"
		
	elseif self.PresetName == "Winchester 1866 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Winchester 1866"
		self.Items[1]["AmmoPerBox"] = 15
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Winchester 1866"
		self.Items[2]["AmmoPerBox"] = 15
		
		self.replacebox = ".44 Henry Rounds"
		
	elseif self.PresetName == "Lee Enfield Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Lee Enfield"
		self.Items[1]["AmmoPerBox"] = 5
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Lee Enfield"
		self.Items[2]["AmmoPerBox"] = 5
		
		self.replacebox = "Lee Enfield Stripper Clip"
		
	elseif self.PresetName == "AKM Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "AKM"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] AKM"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "AKM Magazine"
		
	elseif self.PresetName == "M16A2 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M16A2"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M16A2"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "STANAG Magazine"
		
	elseif self.PresetName == "MP5SD6 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "MP5SD6"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] MP5SD6"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "MP5SD6 Magazine"
		
	elseif self.PresetName == "M4A1 CCO SD Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M4A1 CCO SD"
		self.Items[1]["AmmoPerBox"] = 30
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M4A1 CCO SD"
		self.Items[2]["AmmoPerBox"] = 30
		
		self.replacebox = "STANAG SD Magazine"
		
	elseif self.PresetName == "Mk 48 Mod 0 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "Mk 48 Mod 0"
		self.Items[1]["AmmoPerBox"] = 100
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] Mk 48 Mod 0"
		self.Items[2]["AmmoPerBox"] = 100
		
		self.replacebox = "M240 Belt"
		
	elseif self.PresetName == "M14 AIM Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M14 AIM"
		self.Items[1]["AmmoPerBox"] = 20
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M14 AIM"
		self.Items[2]["AmmoPerBox"] = 20
		
		self.replacebox = "DMR Magazine"
		
	elseif self.PresetName == "CZ 550 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "CZ 550"
		self.Items[1]["AmmoPerBox"] = 5
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] CZ 550"
		self.Items[2]["AmmoPerBox"] = 5
		
		self.replacebox = "9.3x62 Mauser Rounds"
		
	elseif self.PresetName == "M107 Ammo Adder" then
		
		self.Items = {}
		
		self.Items[1] = {}
		self.Items[1]["PresetName"] = "M107"
		self.Items[1]["AmmoPerBox"] = 10
		
		self.Items[2] = {}
		self.Items[2]["PresetName"] = "[DZ] M107"
		self.Items[2]["AmmoPerBox"] = 10
		
		self.replacebox = "M107 Magazine"

	end
	
	
	
	
	
	if self.Sharpness ~= 255 then
		self.Age = 1
		for actor in MovableMan.Actors do
			if actor.ID == self.Sharpness then --and actor.PresetName == self.PresetName then
--				print(actor.PresetName .." picked up ammo")
				self.rootofdevice = MovableMan:GetMOFromID(actor.ID)
				if self.rootofdevice then
					if self.rootofdevice:IsActor() then
						self.operator = ToAHuman(self.rootofdevice)
						self.holding = ToHDFirearm(self.operator.EquippedItem)
						if self.holding then
--							print(actor.PresetName .." is holding a ".. self.holding.PresetName)

								
							--OTHER GUNS
							if self.Sharpness ~= 255 then
								for b = 1, #self.Items do
									if self.Items[b]["PresetName"] == self.holding.PresetName then
										self.holding.Sharpness = self.holding.Sharpness + self.Items[b]["AmmoPerBox"]
	--									print("Added ".. self.Items[b]["AmmoPerBox"] .." rounds to ".. self.operator.PresetName .."'s ".. self.Items[b]["PresetName"] ..", Deleting Adder Particle")
										self.Sharpness = 255
										self.Lifetime = 1
									end
								end
								if self.Sharpness ~= 255 then
									self.j = CreateHeldDevice(self.replacebox,"DayZ.rte")
									self.j.Sharpness = 3
									self.operator:AddInventoryItem(self.j)
	--								print("applicible weapon not equipped, ammo not applied, restoring ammo box")
									self.Sharpness = 255
									self.Lifetime = 1
								end
							end
						else
							self.j = CreateHeldDevice(self.replacebox,"DayZ.rte")
							self.j.Sharpness = 3
							self.operator:AddInventoryItem(self.j)
--							print(self.actor.PresetName .." had no weapon equipped, ammo not applied, restoring ammo box")
							self.Sharpness = 255
							self.Lifetime = 1
						end
					end
				end
			end
		end
	end
end