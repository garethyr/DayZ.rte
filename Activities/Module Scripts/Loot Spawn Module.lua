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
	for i = 1, self.NumberOfCivilianLootAreas do
		self:LoadLootArea("Civilian", i);
	end
	for i = 1, self.NumberOfHospitalLootAreas do
		self:LoadLootArea("Hospital", i);
	end
	for i = 1, self.NumberOfMilitaryLootAreas do
		self:LoadLootArea("Military", i);
	end

	----------------------
	--STATIC LOOT TABLES--
	----------------------
	--This table stores all junk item names
	self.LootJunkTable = {"Empty Tin Can", "Empty Whiskey Bottle", "Empty Coke", "Empty Pepsi", "Empty Mountain Dew"};
	
	--This table stores all food item names
	self.LootFoodTable = {"Baked Beans",
							create = function(name) return CreateHDFirearm(name, self.RTE) end};
	
	--This table stores all drink item names
	self.LootDrinkTable = {"Coke", "Pepsi", "Mountain Dew",
							create = function(name) return CreateHDFirearm(name, self.RTE) end};
	
	--This table stores all light making throwable names
	self.LootLightTable = {"Red Chemlight", "Green Chemlight", "Blue Chemlight", "Flare",
							create = function(name) return CreateTDExplosive(name, self.RTE) end};
	
	--This table stores all the medical supply names
	self.LootMedicineTable = {"Bandage", "Bloodbag", "Medical Box",
							create = function(name) return CreateHDFirearm(name, self.RTE) end};
	
	--This table stores all civilian ammo names
	self.LootCAmmoTable = {"Makarov PM Magazine", ".45 ACP Speedloader", "M1911A1 Magazine", "Metal Bolts", "12 Gauge Buckshot (2)", ".44 Henry Rounds", "Lee Enfield Stripper Clip", "9.3x62 Mauser Rounds",
							create = function(name) return CreateHeldDevice(name, self.RTE) end};
	
	--This table stores all civilian weapons names
	self.LootCWeaponTable = {"Hunting Knife", "Crowbar", "Hatchet", "[DZ] Makarov PM", "[DZ] .45 Revolver", "[DZ] M1911A1", "[DZ] Compound Crossbow", "[DZ] MR43", "[DZ] Winchester 1866", "[DZ] Lee Enfield", "[DZ] CZ 550",
							create = function(name) return CreateHDFirearm(name, self.RTE) end};
	
	--This table stores all military ammo names
	self.LootMAmmoTable = {"G17 Magazine", "AKM Magazine", "STANAG Magazine", "STANAG SD Magazine", "MP5SD6 Magazine", "M240 Belt", "DMR Magazine", "M107 Magazine",
							create = function(name) return CreateHeldDevice(name, self.RTE) end};
	
	--This table stores all military weapons names
	self.LootMWeaponTable = {"[DZ] G17", "[DZ] AKM", "[DZ] M16A2", "[DZ] MP5SD6", "[DZ] M4A1 CCO SD", "[DZ] Mk 48 Mod 0", "[DZ] M14 AIM", {name = "[DZ] M107", chance = 0.25},
							create = function(name) return CreateHDFirearm(name, self.RTE) end};

	--This table stores the spawn chances for each type of loot item, based on the lootset of the area
	self.LootSpawnChances = {
		Civilian = {Food = 0.3, Drink = 0.3, Light = 0.2, Medicine = 0.15, CAmmo = 0.15, CWeapon = 0.15, MAmmo = 0.05, MWeapon = 0.05},
		Hospital = {Food = 0.3, Drink = 0.3, Light = 0.2, Medicine = 0.45, CAmmo = 0.05, CWeapon = 0.05, MAmmo = 0.05, MWeapon = 0.05},
		Military = {Food = 0.2, Drink = 0.2, Light = 0.2, Medicine = 0.15, CAmmo = 0.15, CWeapon = 0.15, MAmmo = 0.45, MWeapon = 0.45}
	}
	
	-----------------------
	--DYNAMIC LOOT TABLES--
	----------------------
	--A table of all unclaimed loot, organized by the area they belong to
	self.LootTable = {{}}; --Key based on areanum then number - self.LootTable[areanum][index] = loot item
	
end
--Load a loot area, given input to specify naming scheme and loot set
function ModularActivity:LoadLootArea(areaset, currentiteration)
	local tablenum = #self.LootAreas+1;
	self.LootAreas[tablenum] = {};
	self.LootAreas[tablenum].area = SceneMan.Scene:GetArea(areaset.." Loot Area "..tostring(currentiteration));
	self.LootAreas[tablenum].filled = false; --A value for whether the area has loot or not
	self.LootAreas[tablenum].lootSet = areaset; --The loot set, 1 = basic
	self.LootTimer[tablenum] = Timer();
	self.LootTimer[tablenum].ElapsedSimTimeMS = self.LootInterval; --Make sure first wave of loot always spawns
end
----------------------
--CREATION FUNCTIONS--
----------------------
--The actual loot spawning
function ModularActivity:SpawnLoot(area, areanum, set)
	--Make and add the loot item, defaulting to junk, to the correct position
	local loot = CreateTDExplosive(self.LootJunkTable[math.random(#self.LootJunkTable)], self.RTE);
	for itemtype, spawnchance in pairs(self.LootSpawnChances[set]) do
		if math.random() < spawnchance then
			local lootitemtable = self["Loot"..itemtype.."Table"]; --Get the loot item table for the itemtype (e.g. LootFoodTable, etc.)
			local lootitemvalue = lootitemtable[math.random(#lootitemtable)];
			--If we find a loot item with a table value, that means it has a low chance of spawning - if it randomly shouldn't spawn, spawn another item instead
			if type (lootitemvalue) == "table" then
				if math.random() >= lootitemvalue.chance then
					print ("Tried to spawn "..lootitemvalue.name.." but random number was more than the "..tostring(lootitemvalue.chance).." so replacing with new loot item instead.");
					self:SpawnLoot(area, areanum, set);
					return;
				end
				lootitemvalue = lootitemvalue.name;
			end
			loot = lootitemtable.create(lootitemvalue);
		end
	end
	loot.Pos = Vector(area:GetRandomPoint().X + math.random(-5,5), area:GetCenterPoint().Y);
	MovableMan:AddParticle(loot);
	--print ("Added loot item "..loot.PresetName.." to position "..tostring(loot.Pos).." in loot area "..tostring(areanum));
	
	--Create a loot table for this area if there's not one already
	if self.LootTable[areanum] == nil then
		self.LootTable[areanum] = {};
	end
	--Add the loot to the relevant table and set the area as filled
	self.LootTable[areanum][#self.LootTable[areanum]+1] = loot;
	self.LootAreas[areanum].filled = true;
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Run the loot update functions, cleanup first then check for spawning
function ModularActivity:DoLoot()
	self:DoLootDespawns();
	self:DoLootTableCleanup();
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
function ModularActivity:DoLootTableCleanup()
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