function DropAmmo(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		if gun.PresetName == "Makarov PM" then--6x50mm
			actor.DropAmmoCount = 8
			actor.ammobox = "Makarov PM Magazine"
		elseif gun.PresetName == "[DZ] Makarov PM" then--6x30mm
			actor.DropAmmoCount = 8
			actor.ammobox = "Makarov PM Magazine"
		elseif gun.PresetName == ".45 Revolver" then--6x30mm
			actor.DropAmmoCount = 6
			actor.ammobox = ".45 ACP Speedloader"
		elseif gun.PresetName == "[DZ] .45 Revolver" then--6x30mm
			actor.DropAmmoCount = 6
			actor.ammobox = ".45 ACP Speedloader"
		elseif gun.PresetName == "M1911A1" then--6x30mm
			actor.DropAmmoCount = 7
			actor.ammobox = "M1911A1 Magazine"
		elseif gun.PresetName == "[DZ] M1911A1" then--6x30mm
			actor.DropAmmoCount = 7
			actor.ammobox = "M1911A1 Magazine"
		elseif gun.PresetName == "G17" then--12x25mm
			actor.DropAmmoCount = 17
			actor.ammobox = "G17 Magazine"
		elseif gun.PresetName == "[DZ] G17" then--12x25mm
			actor.DropAmmoCount = 17
			actor.ammobox = "G17 Magazine"
		elseif gun.PresetName == "Compound Crossbow" then--6x80mm
			actor.DropAmmoCount = 2
			actor.ammobox = "Metal Bolts"
		elseif gun.PresetName == "[DZ] Compound Crossbow" then--6x80mm
			actor.DropAmmoCount = 2
			actor.ammobox = "Metal Bolts"
		elseif gun.PresetName == "MR43" then--6x80mm
			actor.DropAmmoCount = 2
			actor.ammobox = "12 Gauge Buckshot (2)"
		elseif gun.PresetName == "[DZ] MR43" then--6x80mm
			actor.DropAmmoCount = 2
			actor.ammobox = "12 Gauge Buckshot (2)"
		elseif gun.PresetName == "Winchester 1866" then--6x80mm
			actor.DropAmmoCount = 15
			actor.ammobox = ".44 Henry Rounds"
		elseif gun.PresetName == "[DZ] Winchester 1866" then--6x80mm
			actor.DropAmmoCount = 15
			actor.ammobox = ".44 Henry Rounds"
		elseif gun.PresetName == "Lee Enfield" then--6x80mm
			actor.DropAmmoCount = 5
			actor.ammobox = "Lee Enfield Stripper Clip"
		elseif gun.PresetName == "[DZ] Lee Enfield" then--6x80mm
			actor.DropAmmoCount = 5
			actor.ammobox = "Lee Enfield Stripper Clip"
		elseif gun.PresetName == "AKM" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "AKM Magazine"
		elseif gun.PresetName == "[DZ] AKM" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "AKM Magazine"
		elseif gun.PresetName == "M16A2" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "STANAG Magazine"
		elseif gun.PresetName == "[DZ] M16A2" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "STANAG Magazine"
		elseif gun.PresetName == "MP5SD6" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "MP5SD6 Magazine"
		elseif gun.PresetName == "[DZ] MP5SD6" then--6x80mm
			actor.DropAmmoCount = 30
			actor.ammobox = "MP5SD6 Magazine"
		elseif gun.PresetName == "M4A1 CCO SD" then--12x25mm
			actor.DropAmmoCount = 30
			actor.ammobox = "STANAG SD Magazine"
		elseif gun.PresetName == "[DZ] M4A1 CCO SD" then--12x25mm
			actor.DropAmmoCount = 30
			actor.ammobox = "STANAG SD Magazine"
		elseif gun.PresetName == "Mk 48 Mod 0" then--6x80mm
			actor.DropAmmoCount = 100
			actor.ammobox = "M240 Belt"
		elseif gun.PresetName == "[DZ] Mk 48 Mod 0" then--6x80mm
			actor.DropAmmoCount = 100
			actor.ammobox = "M240 Belt"
		elseif gun.PresetName == "M14 AIM" then--12x25mm
			actor.DropAmmoCount = 20
			actor.ammobox = "DMR Magazine"
		elseif gun.PresetName == "[DZ] M14 AIM" then--12x25mm
			actor.DropAmmoCount = 20
			actor.ammobox = "DMR Magazine"
		elseif gun.PresetName == "CZ 550" then--12x120mm
			actor.DropAmmoCount = 5
			actor.ammobox = "9.3x62 Mauser Rounds"
		elseif gun.PresetName == "[DZ] CZ 550" then--12x120mm
			actor.DropAmmoCount = 5
			actor.ammobox = "9.3x62 Mauser Rounds"
		elseif gun.PresetName == "M107" then--12x25mm
			actor.DropAmmoCount = 10
			actor.ammobox = "M107 Magazine"
		elseif gun.PresetName == "[DZ] M107" then--12x25mm
			actor.DropAmmoCount = 10
			actor.ammobox = "M107 Magazine"
		end
	
	
		if gun.Sharpness > actor.DropAmmoCount then
			gun.Sharpness = gun.Sharpness - actor.DropAmmoCount
			if actor.ammobox ~= "SE 30x40mm Grenade Can" then
				actor.k = CreateHeldDevice(actor.ammobox,"DayZ.rte")
			else
				actor.k = CreateHDFirearm(actor.ammobox,"DayZ.rte")
			end
			actor.k.Vel = gun.Vel
			actor.k.Pos = gun.Pos
			actor.k:SetWhichMOToNotHit(actor, -1)
			MovableMan:AddParticle(actor.k)
		end
	end
end