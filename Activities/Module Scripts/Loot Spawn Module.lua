-----------------------------------------------------------------------------------------
-- Everything for loot
-----------------------------------------------------------------------------------------
function Chernarus:StartLoot()
	------------------
	--LOOT CONSTANTS--
	------------------
	self.LootSpawnChance = 0.3; --The chance to spawn any loot at all
	self.LootSpawnChanceModifier = 0.2; --The random additive modifier for loot spawn chance, so 0.3 Chance and 0.2 Modifier will have somewhere between 30% and 50% chance of spawning loot 
	self.LootInterval = 90000; --90 second loot spawn interval
	self.LootLifetime = self.LootInterval*0.5; --The time after which loot despawns if not picked up
	self.LootSpawnMinDistance = FrameMan.PlayerScreenWidth/2 + 100; --1/2 of screen width + 100 for the innermost distance where loot spawns
	self.LootSpawnMaxDistance = FrameMan.PlayerScreenWidth/2 + 300; --1/2 of screen width + 300 for the outermost distance where loot spawns
	self.LootMinSpawnAmount = 2; --The minimum amount of loot that can spawn per batch, must be greater than 0
	self.LootMaxSpawnAmount = 5; --The maximum amount of loot that can spawn per batch
	
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
		self.LootAreas[i].lootSet = 1; --The loot set, 1 = basic
		
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
	
	--This table stores all ammo
	self.LootAmmoTable = {}
	
	--This table stores all civilian weapons
	self.LootCWeaponTable = {"Hunting Knife", "Crowbar", "Hatchet", "[DZ] Makarov PM", "[DZ] .45 Revolver", "[DZ] M1911A1", "[DZ] Compound Crossbow", "[DZ] MR43", "[DZ] Winchester 1866", "[DZ] Lee Enfield", "[DZ] CZ 550"};
	
	--This table stores all military weapons
	self.LootMWeaponTable = {"[DZ] G17", "[DZ] AKM", "[DZ] M16A2", "[DZ] MP5SD6", "[DZ] M4A1 CCO SD", "[DZ] Mk 48 Mod 0", "[DZ] M14 AIM", "[DZ] M107"};
	
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
function Chernarus:SpawnLoot(area, areanum, set)
	if MovableMan:GetMOIDCount() <= self.MOIDLimit+30 then
		local loot;
		if set == 1 then --Basic loot set: junk, food, drinks, sometimes melee weapons
			if math.random() < 0.4 then --TODO remove magic numbers, replace with constants to be defined somwhere
				loot = CreateTDExplosive(self.LootJunkTable[math.random(#self.LootJunkTable)], "DayZ.rte");
			elseif math.random() < 0.3 then
				loot = CreateHDFirearm(self.LootFoodTable[math.random(#self.LootFoodTable)], "DayZ.rte");
			elseif math.random() < 0.3 then
				loot = CreateHDFirearm(self.LootDrinkTable[math.random(#self.LootDrinkTable)], "DayZ.rte");
			elseif math.random() < 0.3 then
				loot = CreateTDExplosive(self.LootLightTable[math.random(#self.LootLightTable)], "DayZ.rte");
			elseif math.random() < 0.15 then
				loot = CreateHDFirearm(self.LootMedicineTable[math.random(#self.LootMedicineTable)], "DayZ.rte");
			else
				loot = CreateHDFirearm(self.LootCWeaponTable[math.random(#self.LootCWeaponTable)], "DayZ.rte");
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
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Run the loot update functions, cleanup first then check for spawning
function Chernarus:DoLoot()
	self:DoLootDespawns();
	self:DoLootCleanup();
	self:DoLootSpawning();
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Kill loot that's been sitting around past the loot lifetime
function Chernarus:DoLootDespawns()
	for areanum, tab in ipairs(self.LootTable) do
		for _, item in ipairs(tab) do
			if item.Age > self.LootLifetime and not self:CheckForNearbyHumans(item.Pos, 0, LootSpawnMaxDistance) then
				item.ToDelete = true; --Delete it, it will be removed in the cleanup function
			end
		end
	end
end
--Remove loot from table when picked up or destroyed
function Chernarus:DoLootCleanup()
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
function Chernarus:DoLootSpawning()
	for i, v in ipairs(self.LootAreas) do
		--If there's no loot in the area, a player nearby but not too close and the timer's ready, spawn loot
		if v.filled == false and self.LootTimer[i]:IsPastSimMS(self.LootInterval) then
			if math.random() < (self.LootSpawnChance + RangeRand(0, self.LootSpawnChanceModifier)) and self:CheckForNearbyHumans(v.area:GetCenterPoint(), self.LootSpawnMinDistance, self.LootSpawnMaxDistance) then
				for j = self.LootMinSpawnAmount, math.random(self.LootMinSpawnAmount,self.LootMaxSpawnAmount) do
					self:SpawnLoot(v.area, i, v.lootSet);
					self.LootTimer[i]:Reset();
					v.filled = true;
				end
			end
		end
	end
end