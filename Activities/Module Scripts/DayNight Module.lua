-----------------------------------------------------------------------------------------
-- Use FOW to fake night
-----------------------------------------------------------------------------------------
--Setup
function DayZ:StartDayNight()
	----------------------
	--DAYNIGHT CONSTANTS--
	----------------------
	--Fog of war
	self.DayNightNumRevealBoxes = 2;
	self.DayNightRevealBoxSize = 72;
	self.DayNightLightItemBaseRevealSize = {["Chemlight"] = 300, ["Flare"] = 600};

	--Day/Night
	self.DayNightTimer = Timer(); --Don't change
	self.DayNightInterval = 60000; --60 seconds for every day/night change
	self.DayNightTimer.ElapsedSimTimeMS = self.DayNightInterval*0.5; --Initial start time for the game, best defined as some < 1 multiplier of the interval
	self.DayNightCheckDone = false; --A flag for whether the various once-off things that need checking on day/night change have been checked
	self.DayNightIsNight = false; --Flag for whether it's night, true starts the game off during the night, false starts it off during the day
	
	--Changing background
	self.BackgroundChanges = true; --Whether or not the background should change, as defined by the scene's datafile
	self.BackgroundTotalNumber = 3; --The total number of backgrounds per day/night, as defined by the scene's datafile
	self.BackgroundCurrentNumber = 0; --The current background, must start at 0 to load the first background
	self.BackgroundNames = {[false] = "DayBG", [true] = "NightBG"} --The naming scheme for backgrounds, day is false, night is true
	self.BackgroundPos = Vector(SceneMan.SceneWidth/2, SceneMan.SceneHeight/2); --The position to place backgrounds at (presumably the centre of the scene)
	
	---------------------------
	--DYNAMIC DAYNIGHT TABLES--
	---------------------------
	self.DayNightLightItemTable = {} --Key is item.UniqueID, value = {item = light item, reveal = how much the item reveals}
	self.DayNightExtraRevealBoxes = {} --Key is array index, value is box
end
--------------------
--CREATE FUNCTIONS--
--------------------
--Add a light item so we can reveal it
function DayZ:AddDayNightLightItem(item)  --TODO Decide if I want daynight to handle this and flashlight, or let the items do it by themselves
	if self.DayNightLightItemTable[item.UniqueID] == nil then
		local str = string.find(item.PresetName,"Chemlight") and "Chemlight" or item.PresetName;
		self.DayNightLightItemTable[item.UniqueID] = {item = item, reveal = self.DayNightLightItemBaseRevealSize[str]};
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Swap day and night and act accordingly
function DayZ:DoDayNight()
	self:DoDayNightCleanup();
	--Swap from day to night after a certain amount of time
	--TODO Have a more smooth swapping, gradual darkness etc. Use numbers instead of booleans to determine when alerts will have effects/how effective they'll be?
	if self.DayNightTimer:IsPastSimMS(self.DayNightInterval) then
		self:CycleDayNight();
		self.DayNightTimer:Reset();
	end
	
	if self.DayNightCheck == false then
		self:DoDayNightChangeActions();
		self.DayNightCheck = true;
	end
	
	if self.BackgroundChanges then
		self:DoDayNightBackgroundChanges();
	end
	
	self:DoDayNightContinuousActions();
	
	--TODO: Remove light alerts during day, increase alert distances for zombies.
	if self.DayNightIsNight == false then
	--Make nighttime when in night
	elseif self.DayNightIsNight == true then
		--If we haven't done the once off checks
		if self.DayNightCheck == false then
			self.DayNightCheck = true;
		end
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Cleanup any dead items
function DayZ:DoDayNightCleanup()
	for k, v in pairs(self.DayNightLightItemTable) do
		if v.item.RootID == 255 or (v.item.RootID ~= 255 and v.item.RootID ~= v.item.ID and ToAHuman(MovableMan:GetMOFromID(v.item.RootID)).EquippedItem.UniqueID ~= v.item.UniqueID) then
			print ("REMOVING ITEM FROM DAYNIGHT ITEM TABLE: "..v.item.UniqueID);
			self.DayNightLightItemTable[k] = nil;
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Cycle the day and night
function DayZ:CycleDayNight()
	self.DayNightIsNight = not self.DayNightIsNight;
	self.BackgroundCurrentNumber = 0; --Reset the background number
	self:DayNightNotifyMany_DayNightCycle();
	self.DayNightCheck = false;
end
--Actions performed once whenever the game changes from night to day
function DayZ:DoDayNightChangeActions()
	if self.DayNightIsNight == true then --During the night
	else --During the day
		--Reveal the map (only for Players and NPCs)
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.PlayerTeam);
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.NPCTeam);
	end
end
--Change the map background based on time of day/night
function DayZ:DoDayNightBackgroundChanges()
	local curtime = self.DayNightTimer.ElapsedSimTimeS;
	if curtime/self.DayNightInterval > self.BackgroundCurrentNumber/self.BackgroundTotalNumber then
		print (tostring(curtime/self.DayNightInterval).." > "..tostring(self.BackgroundCurrentNumber/self.BackgroundTotalNumber));
		self.BackgroundCurrentNumber = self.BackgroundCurrentNumber + 1;
        local obj = CreateTerrainObject(self.BackgroundNames[self.DayNightIsNight]..tostring(self.BackgroundCurrentNumber), "DayZ.rte");
        if obj then
            obj.Pos = self.BackgroundPos;
            obj.Team = -1;
            SceneMan:AddTerrainObject(obj);
        end
	end
end
--Actions performed continuously during day or night
function DayZ:DoDayNightContinuousActions()
	if self.DayNightIsNight == true then --During the night
		--Make everything invisible for humans
		SceneMan:MakeAllUnseen(Vector(24, 24), self.PlayerTeam);
		SceneMan:MakeAllUnseen(Vector(24, 24), self.NPCTeam);
		--Reveal all human visibility areas TODO make flashlight simply affect this instead of working on its own
		for _, humantable in pairs(self.HumanTable) do
			for k, v in pairs(humantable) do
				local xmult = math.cos(v.actor:GetAimAngle(true));
				local ymult = -math.sin(v.actor:GetAimAngle(true));
				local size = self.DayNightRevealBoxSize;
				
				for j = 0, self.DayNightNumRevealBoxes do
					local pos = Vector(v.actor.Pos.X + size*2*j*xmult, v.actor.Pos.Y + size*2*j*ymult);
					SceneMan:RevealUnseenBox(pos.X - size, pos.Y - size, size*2, size*2, self.PlayerTeam);
					SceneMan:RevealUnseenBox(pos.X - size, pos.Y - size, size*2, size*2, self.NPCTeam);
				end
			end
		end
		--Reveal all areas lit up by items
		for _, v in pairs(self.DayNightLightItemTable) do
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.PlayerTeam);
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.NPCTeam);
		end
		--Reveal all extra reveal boxes created by anything else
		if #self.DayNightExtraRevealBoxes > 0 then
			local v;
			for i = #self.DayNightExtraRevealBoxes, 1, -1 do
				v = self.DayNightExtraRevealBoxes[i];
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.PlayerTeam);
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.NPCTeam);
				table.remove(self.DayNightExtraRevealBoxes, i);
			end
		end
	end
end