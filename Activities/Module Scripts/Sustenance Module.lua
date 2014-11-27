-----------------------------------------------------------------------------------------
-- Drain actor sustenance, add to it on item use and injure/kill them if they run out
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartSustenance()
	----------------------------
	--DYNAMIC SUSTENANCE TABLE--
	----------------------------
	--This table stores all sustenance information outside of delays, which are always the same. Key is actor.UniqueID
	--Keys - Values:
	--actor, hunger - hunger amount, thirst - thirst amount,
	--htimer - hunger timer for killing, ttimer - thirst timer for killing, drainMult - the multiplier for how much sustenance to drain, based on actor actions
	self.SustTable = {};
	
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
	self.MaxSust = {hunger = 11000, thirst = 11000}; --Maximum hunger and thirst values
	self.SustDrainMult = {hunger = 1, thirst = 1}; --Hunger and thirst extra drain multiplier
	self.SustDamageDelay = {hunger = 1000, thirst = 500}; --Hunger and thirst damage delay
	self.SustDrainMultAct = {move = 3, jump = 5} --Multipliers for moving and jumping
	self.SustItemGroups = {hunger = "Food", thirst = "Drink"} --The names of the different item groups for sust types
	self.SustVomitDrainMult = {hunger = 0.75, thirst = 0.75}; --The percentage mult vomiting drains each sust type (0.75 means actor ends up with 75% of previous sust)
end
---------------------
--CREATION FUNCTION--
---------------------
--Adding an actor to the table
function Chernarus:AddToSustenanceTable(actor)
	self.SustTable[actor.UniqueID] = {actor = ToActor(actor), hunger = self.InitialSust.hunger, thirst = self.InitialSust.thirst, htimer = Timer(), ttimer = Timer(), drainMult = 1};
	self.SustTable[actor.UniqueID].htimer:Reset();
	self.SustTable[actor.UniqueID].ttimer:Reset();
end
-------------------
--UPDATE FUNCTION--
-------------------
--Track stuff for killing
function Chernarus:DoSustenance()
	for k, v in pairs (self.SustTable) do
		--Do movement multipliers, base is 1, the rest are defined in create
		v.drainMult = 1;
		if v.actor:GetController():IsState(Controller.HOLD_LEFT) or v.actor:GetController():IsState(Controller.MOVE_LEFT) or v.actor:GetController():IsState(Controller.HOLD_RIGHT) or v.actor:GetController():IsState(Controller.MOVE_RIGHT)then
			v.drainMult = self.SustDrainMultAct.move;
		elseif v.actor:GetController():IsState(Controller.BODY_JUMPSTART) or v.actor:GetController():IsState(Controller.BODY_JUMP) then
			v.drainMult = self.SustDrainMultAct.jump;
		end
		if ToAHuman(v.actor) ~= nil then
			--Drain hunger and thirst and call the kill function if necessary
			local hasSust = false;
			for _, susttype in pairs(self.SustTypes) do
				if v[susttype] > 0 then
					v[susttype] = v[susttype] - v.drainMult*self.SustDrainMult[susttype];
					hasSust = true;
				end
			end
			if not hasSust then
				self:NoSustenanceKill(v.actor, k);
			end
			
			--TODO potentially refactor this into one universal item use check
			--Check for actors using food or drink items
			local ahuman = ToAHuman(v.actor);
			if ahuman.EquippedItem ~= nil and ahuman:GetController():IsState(Controller.PRESS_PRIMARY) then
				for susttype, itemgroup in pairs (self.SustItemGroups) do
					if ahuman.EquippedItem:HasObjectInGroup(itemgroup) then
						v[susttype] = v[susttype] + self.SustItems[itemgroup][ahuman.EquippedItem.PresetName];
						if v[susttype] > self.MaxSust[susttype] then
							self:DoSustenanceVomiting(v);
						end
						break; --No need to check the rest of them since one won't eat/drink more than one item per frame
					end
				end
			end
		end
	end
end
--The actual killing
function Chernarus:NoSustenanceKill(actor, key)
	local damage = 1;
	if actor.Health <= 25 or actor.Health >= 90 then
		damage = 3;
	elseif actor.Health >= 75 then
		damage = 2;
	end
	if self.SustTable[key].htimer:IsPastSimMS(self.SustDamageDelay.hunger*damage) then
		actor.Health = actor.Health - damage;
		actor:FlashWhite(100);
		self.SustTable[key].htimer:Reset();
	end
	if self.SustTable[key].ttimer:IsPastSimMS(self.SustDamageDelay.thirst*damage) then
		actor.Health = actor.Health - damage;
		actor:FlashWhite(100);
		self.SustTable[key].ttimer:Reset();
	end
end
--Makes the sust table entry's actor vomit and decreases all of his susts
--TODO make this act over time - either use htimer/ttimer or add a new vomit timer and make the actor keep vomitting til the timer's done
function Chernarus:DoSustenanceVomiting(sust)
	sust.actor:GetController():SetState(Controller.BODY_CROUCH, true);
	sust.actor:GetController():SetState(Controller.BODY_JUMP, false);
	sust.actor:GetController():SetState(Controller.BODY_JUMPSTART, false);
	for k, v in pairs(self.SustTypes) do
		sust[k] = self.MaxSust[k]*self.SustVomitDrainMult[k];
	end
end