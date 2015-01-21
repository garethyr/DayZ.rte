-----------------------------------------------------------------------------------------
-- Everything for loot
-----------------------------------------------------------------------------------------
function ModularActivity:StartLoot()
	------------------
	--LOOT CONSTANTS--
	------------------
	self.LootSpawnChance = 0.3; --The chance to spawn any loot at all
	self.LootSpawnChanceModifier = 0.2; --The random additive modifier for loot spawn chance, so 0.3 Chance and 0.2 Modifier will have somewhere between 30% and 50% chance of spawning loot 
	self.LootInterval = 60000; --90 second loot spawn interval
	self.LootLifetime = self.LootInterval*0.5; --The time after which loot despawns if not picked up
	self.LootSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --1/2 of screen width + 100 for the innermost distance where loot spawns
	self.LootSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --1/2 of screen width + 300 for the outermost distance where loot spawns
	self.LootMinSpawnAmount = 1; --The minimum amount of loot that can spawn per batch, must be greater than 0
	self.LootMaxSpawnAmount = 3; --The maximum amount of loot that can spawn per batch
	
	--------------
	--LOOT AREAS--
	--------------
	self.LootAreas = {};
	self.LootTimer = {};
	for i = 1, self.NumberOfLootAreas do
		self.LootAreas[i] = {};
		local s = "Loot Area "..tostring(i);
		self.LootAreas[i].area = SceneMan.Scene:GetArea(s);
		self.LootAreas[i].filled = false; --A value for whether the area has loot or not
		self.LootAreas[i].lootSet = "civilian"; --The loot set, 1 = basic
		
		self.LootTimer[i] = Timer();
		self.LootTimer[i].ElapsedSimTimeMS =  self.LootInterval; --Make sure first wave of loot always spawns
	end

	----------------------
	--STATIC LOOT TABLES--
	----------------------
	--This table stores all the medical supplies
	self.LootMedicineTable = {"Bandage", "Blood Bag", "Medical Box"};
	
	--This table stores all junk items
	self.LootJunkTable = {"Empty Tin Can", "Empty Whiskey Bottle", "Empty Coke", "Empty Pepsi", "Empty Mountain Dew"};
	
	--This table stores all food items and their hunger value
	self.LootFoodTable = {"Baked Beans"};
	
	--This table stores all water items and their thirst value
	self.LootDrinkTable = {"Coke", "Pepsi", "Mountain Dew"};
	
	--This table stores all light making throwables
	self.LootLightTable = {"Red Chemlight", "Green Chemlight", "Blue Chemlight", "Flare"};
	
	--These tables store all ammo
	self.LootCAmmoTable = {"Makarov PM Magazine", ".45 ACP Speedloader", "M1911A1 Magazine", "Metal Bolts", "12 Gauge Buckshot (2)", ".44 Henry Rounds", "Lee Enfield Stripper Clip", "9.3x62 Mauser Rounds"};
	
	self.LootMAmmoTable = {"G17 Magazine", "AKM Magazine", "STANAG Magazine", "STANAG SD Magazine", "MP5SD6 Magazine", "M240 Belt", "DMR Magazine", "M107 Magazine"};
	
	--This table stores all civilian weapons
	self.LootCWeaponTable = {"Hunting Knife", "Crowbar", "Hatchet", "[DZ] Makarov PM", "[DZ] .45 Revolver", "[DZ] M1911A1", "[DZ] Compound Crossbow", "[DZ] MR43", "[DZ] Winchester 1866", "[DZ] Lee Enfield", "[DZ] CZ 550"};
	
	--This table stores all military weapons
	self.LootMWeaponTable = {"[DZ] G17", "[DZ] AKM", "[DZ] M16A2", "[DZ] MP5SD6", "[DZ] M4A1 CCO SD", "[DZ] Mk 48 Mod 0", "[DZ] M14 AIM", "[DZ] M107"};

	--These tables store the spawn chances for each type of loot item, based on the lootset of the area
	self.LootSpawnChances = { --IMPORTANT NOTE: Leave the last value as 1 so something will always spawn when loot is supposed to spawn
		civilian = {junk = 0.4, food = 0.3, drink = 0.3, light = 0.3, medicine = 0.15, cammo = 0.15, mammo = 0.15, weapon = 1},
		hospital = {junk = 0.4, food = 0.3, drink = 0.3, light = 0.3, medicine = 0.45, ammo = 0.05, mammo = 0.05, weapon = 1},
		military = {junk = 0.3, food = 0.2, drink = 0.2, light = 0.3, medicine = 0.15, ammo = 0.15, mammo = 0.45, weapon = 1}
	}
	
	----------------------
	--DYNAMIC LOOT TABLE--
	---------------------
	--A table of all unclaimed loot, organized by the area they belong to
	self.LootTable = {{}}; --Key based on areanum then number - self.LootTable[areanum][index] = loot item
	
end
----------------------
--CREATION FUNCTIONS--
----------------------
--The actual loot spawning
function ModularActivity:SpawnLoot(area, areanum, set)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit+30 then
		local loot;
		local chance = self.LootSpawnChances[set];
		if math.random() < chance.junk then
			loot = CreateTDExplosive(self.LootJunkTable[math.random(#self.LootJunkTable)], self.RTE);
		elseif math.random() < chance.food then
			loot = CreateHDFirearm(self.LootFoodTable[math.random(#self.LootFoodTable)], self.RTE);
		elseif math.random() < chance.drink then
			loot = CreateHDFirearm(self.LootDrinkTable[math.random(#self.LootDrinkTable)], self.RTE);
		elseif math.random() < chance.light then
			loot = CreateTDExplosive(self.LootLightTable[math.random(#self.LootLightTable)], self.RTE);
		elseif math.random() < chance.medicine then
			loot = CreateHDFirearm(self.LootMedicineTable[math.random(#self.LootMedicineTable)], self.RTE);
		elseif math.random() < chance.cammo then
			loot = CreateHeldDevice(self.LootCAmmoTable[math.random(#self.LootCAmmoTable)], self.RTE);
		elseif math.random() < chance.mammo then
			loot = CreateHeldDevice(self.LootMAmmoTable[math.random(#self.LootMAmmoTable)], self.RTE);
		elseif math.random() < chance.weapon then
			loot = CreateHDFirearm(self.LootCWeaponTable[math.random(#self.LootCWeaponTable)], self.RTE);
		end
		loot.Pos = Vector(area:GetRandomPoint().X + math.random(-5,5), area:GetCenterPoint().Y);
		MovableMan:AddParticle(loot);
		print ("Added loot item "..loot.PresetName.." to position "..tostring(loot.Pos).." in loot area "..tostring(areanum));
		--Create a loot table for this area if there's not one already
		if self.LootTable[areanum] == nil then
			self.LootTable[areanum] = {};
		end
		--Add the loot to the relevant table and set the area as filled
		self.LootTable[areanum][#self.LootTable[areanum]+1] = loot;
		self.LootAreas[areanum].filled = true;
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Run the loot update functions, cleanup first then check for spawning
function ModularActivity:DoLoot()
	self:DoLootDespawns();
	self:DoLootCleanup();
	self:DoLootSpawning();
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Kill loot that's been sitting around past the loot lifetime
function ModularActivity:DoLootDespawns()
	for areanum, tab in ipairs(self.LootTable) do
		for _, item in ipairs(tab) do
			if item.Age > self.LootLifetime and not self:CheckForNearbyHumans(item.Pos, 0, LootSpawnMaxDistance) then
				item.ToDelete = true; --Delete it, it will be removed in the cleanup function
			end
		end
	end
end
--Remove loot from table when picked up or destroyed
function ModularActivity:DoLootCleanup()
	local v;
	--Iterate through each area section of the loot table
	for areanum, tab in ipairs(self.LootTable) do
		--Iterate through each item in that section
		if #tab > 0 then
			for i = #tab, 1, -1 do
				v = tab[i];
				--Remove nonexistant loot
				if not MovableMan:IsDevice(v) then
					table.remove(tab, i);
				end
			end
		end
		--Set the area's filled value as true if it contains any items
		self.LootAreas[areanum].filled = (#tab > 0);
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Pick where to spawn loot based on nearby humans (players or NPCs)
function ModularActivity:DoLootSpawning()
	for i, v in ipairs(self.LootAreas) do
		--If there's no loot in the area, a player nearby but not too close and the timer's ready, spawn loot
		if v.filled == false and self.LootTimer[i]:IsPastSimMS(self.LootInterval) then
			if self:CheckForNearbyHumans(v.area:GetCenterPoint(), self.LootSpawnMinDistance, self.LootSpawnMaxDistance) then
				if math.random() < (self.LootSpawnChance + RangeRand(0, self.LootSpawnChanceModifier)) then
					for j = self.LootMinSpawnAmount, math.random(self.LootMinSpawnAmount, self.LootMaxSpawnAmount) do
						self:SpawnLoot(v.area, i, v.lootSet);
						v.filled = true;
					end
				end
				self.LootTimer[i]:Reset(); --Only reset the timer if we actually have a human close enough to try to trigger loot
			end
		--Otherwise if there's loot in the area, reset the timer to avoid instant loot spawning
		elseif v.filled == true then
			self.LootTimer[i]:Reset();
		end
	end
end