-----------------------------------------------------------------------------------------
-- Drain actor sustenance, add to it on item use and injure/kill them if they run out
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartSustenance()
	-----------------------------
	--DYNAMIC SUSTENANCE TABLES--
	-----------------------------
	--This table stores all sustenance information outside of delays, which are always the same. Key is actor.UniqueID
	--Keys - Values:
	--actor, hunger/thirst/etc. - numerical value for each sust type
	--timers = {hunger/thirst/etc. - timer for each sust type, vomit - timer for vomitting}
	--activitydrainmult - the multiplier for how much sustenance to drain from all susttype, based on actor actions
	self.SustTable = {};
	
	--This table stores actors in the process of vomiting, they get removed when they hit the end point for all drain types
	self.SustVomitTable = {};
	
	----------------------------
	--STATIC SUSTENANCE TABLES--
	----------------------------
	--This table stores all sustenance items and their values
	self.SustItems = {
		Food = {["Baked Beans"] = 5000},
		Drink = {["Coke"] = 5000, ["Pepsi"] = 5000, ["Mountain Dew"] = 5000} --Note: ["name"] = value is the same as name = value, brackets are need for multiple words
	};
	------------------------
	--SUSTENANCE CONSTANTS--
	------------------------
	self.SustTypes = {"hunger", "thirst"}; --The different sustenance types. Must be updated
	self.InitialSust = {hunger = 10000, thirst = 10000}; --Initial hunger and thirst values
	self.MaxSust = {hunger = 15000, thirst = 15000}; --Maximum hunger and thirst values
	self.SustDrainMult = {hunger = .30, thirst = .30}; --Hunger and thirst extra drain multiplier, smaller number means slower drains
	self.SustActivityDrainMult = {move = 1.75, jump = 40} --Multipliers for moving and jumping - Note: jumping is high since it's only applied once
	self.SustDamageDelay = {hunger = 1000, thirst = 500}; --Hunger and thirst damage delay
	self.SustItemGroups = {hunger = "Food", thirst = "Drink"} --The names of the different item groups for sust types
	--Vomiting
	self.SustVomitRequirementMult = {hunger = 1.5, thirst = 2} --The multiple of self.MaxSust required for either sustenance type to cause vomiting.
	self.SustVomitDrainEndPoint = {hunger = 0.75, thirst = 0.75}; --The percentage mult vomiting drains each sust type to (0.75 means actor ends up with 75% of max sust for tha susttype)
	self.SustVomitDrainTimer = Timer(); --The timer for vomit sustenance draining
	self.SustVomitDrainInterval = 1000; --The interval after which sustenance drains again for vomiting
	self.SustVomitDrainRate = 0.1; --The rate (as a percent of max sust for each type) at which vomiting drains sust every drain interval
end
---------------------
--CREATION FUNCTIONS--
---------------------
--Adding an actor to the table
function ModularActivity:AddToSustenanceTable(actor)
	self.SustTable[actor.UniqueID] = {actor = ToActor(actor), timers = {vomit = Timer()}, activitydrainmult = 1};
	self.SustTable[actor.UniqueID].timers.vomit:Reset();
	--Add values and timers for each sust type
	for _, susttype in pairs(self.SustTypes) do
		self.SustTable[actor.UniqueID][susttype] = self.InitialSust[susttype];
		self.SustTable[actor.UniqueID].timers[susttype] = Timer();
		self.SustTable[actor.UniqueID].timers[susttype]:Reset();
	end
end
--Add an actor to the vomit table
function ModularActivity:AddToVomitTable(actor)
	table.insert(self.SustVomitTable, actor.UniqueID);
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Do everything for sustenance
function ModularActivity:DoSustenance()
	for _, sust in pairs (self.SustTable) do
		--Get the current activity multiplier for the actor - base is 1, the rest are defined in create
		self:GetCurrentActivitySustenanceDrain(sust);
		
		--Drain hunger and thirst and call the damage function if necessary
		self:DrainSustenance(sust);
		
		--TODO potentially refactor this into one universal item use check
		--Check for actors using food or drink items
		self:CheckForActorSustItemUse(sust);
	end
	self:DoVomiting();
end
--Do vomiting effects for any vomiting actors
function ModularActivity:DoVomiting()
	local stillvomiting;
	for i = #self.SustVomitTable, 0, -1 do
		local tab = self.SustTable[self.SustVomitTable[i]];
		stillvomiting = true; --Set as true for when the timer isn't ready to check for trueness
		if tab ~= nil then
			--If the actor is not at the vomit end point, drain all types of sust and flag as still vomiting
			if self.SustVomitDrainTimer:IsPastSimMS(self.SustVomitDrainInterval) then
				stillvomiting = false; --Set as false so it can be triggered by checks
				for _, susttype in pairs(self.SustTypes) do
					if tab[susttype] ~= nil then
						if tab[susttype] >= self.MaxSust[susttype]*self.SustVomitDrainEndPoint[susttype] then
							tab[susttype] = tab[susttype] - self.MaxSust[susttype]*self.SustVomitDrainRate;
							stillvomiting = true;
						end
					end
				end
				self.SustVomitDrainTimer:Reset();
			end
			--If the actor is still vomiting, keep it prone
			if stillvomiting then
				tab.actor:GetController():SetState(Controller.BODY_CROUCH, true);
				tab.actor:GetController():SetState(Controller.BODY_JUMP, false);
				tab.actor:GetController():SetState(Controller.BODY_JUMPSTART, false);
			--If the actor is not still vomiting, remove it from the vomiting table
			else
				table.remove(self.SustVomitTable, i);
			end
		end
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
function ModularActivity:RemoveFromSustTable(ID)
	self.SustTable[ID] = nil;
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Update the sust mult for the given sust table
function ModularActivity:GetCurrentActivitySustenanceDrain(sust)
	sust.activitydrainmult = 1;
	if sust.actor:GetController():IsState(Controller.MOVE_LEFT) or sust.actor:GetController():IsState(Controller.MOVE_RIGHT)then
		sust.activitydrainmult = self.SustActivityDrainMult.move;
	elseif sust.actor:GetController():IsState(Controller.BODY_JUMPSTART) or sust.actor:GetController():IsState(Controller.BODY_JUMP) then
		sust.activitydrainmult = self.SustActivityDrainMult.jump;
	end
end
--Drain sust for each type for sust for the actor based on activity drain and the base drain speed for the sust type, also damage actor if needed
function ModularActivity:DrainSustenance(sust)
	for _, susttype in pairs(self.SustTypes) do
		if sust[susttype] > 0 then
			sust[susttype] = sust[susttype] - sust.activitydrainmult*self.SustDrainMult[susttype];
		else
			self:NoSustenanceDamage(sust.actor, susttype);
		end
	end
end
--Damage the actor as necessary
function ModularActivity:NoSustenanceDamage(actor, susttype)
	--Determine the amount of damage to deal, double damage at medium-high healths
	local damage = 1;
	if actor.Health >= 65 and actor.Health < 90 then
		damage = 2;
	end
	--Deal damage and reset damage timer
	local timer = self.SustTable[actor.UniqueID].timers[susttype];
	if timer:IsPastSimMS(self.SustDamageDelay[susttype]) then
		actor.Health = actor.Health - damage;
		actor:FlashWhite(100); --TODO instead of flashing, play some sust lacking sound, maybe have a different one for each sust type?
		timer:Reset();
	end
end
--Check if a sust item has been used and apply its sust gain if it has, also vomit if necessary
function ModularActivity:CheckForActorSustItemUse(sust)
	local ahuman = ToAHuman(sust.actor);
	if ahuman ~= nil and ahuman.EquippedItem ~= nil and ahuman:GetController():IsState(Controller.WEAPON_FIRE) then
		for susttype, itemgroup in pairs (self.SustItemGroups) do
			if ahuman.EquippedItem:HasObjectInGroup(itemgroup) then
				sust[susttype] = sust[susttype] + self.SustItems[itemgroup][ahuman.EquippedItem.PresetName];
				if sust[susttype] > self.MaxSust[susttype]*self.SustVomitRequirementMult[susttype] then
					self:AddToVomitTable(sust.actor);
				end
				break; --No need to check the rest of them since one won't eat/drink more than one item per frame
			end
		end
	end
end