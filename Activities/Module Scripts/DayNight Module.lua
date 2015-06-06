-----------------------------------------------------------------------------------------
-- Use FOW to fake night
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartDayNight()
	----------------------
	--DAYNIGHT CONSTANTS--
	----------------------
	--Defined by the scene datafile
	self.IsOutside = self.IsOutside; --If it's not outdoors (i.e. indoors/underground) no BG transitions will occur and no celestial bodies will be placed
	
	--Fog of war
	self.DayNightNumRevealBoxes = 2; --Number of reveal boxes an unassisted human will make
	self.DayNightRevealBoxMinSize = 80; --Minimum size of the reveal boxes an unassisted human will make
	self.DayNightRevealBoxMaxSize = FrameMan.PlayerScreenWidth/2; --Maximum size of the reveal boxes an unassisted human will make
	self.DayNightRevealAbsoluteDarknessPercent = 0.5; --The percent of the night which will stay at the lowest light level, the rest of the night will darken and brighten accordingly. E.g. 0.2 means 1/5th of the night is lowest light
	self.DayNightLightItemBaseRevealSize = {["Chemlight"] = 300, ["Flare"] = 600};

	--Day/Night
	self.DayNightTimer = Timer(); --Don't change
	self.DayNightInterval = 60000; --60 seconds for every day/night change
	self.DayNightTimer.ElapsedSimTimeMS = self.DayNightInterval*0.5; --Initial start time for the game, best defined as some < 1 multiplier of the interval
	self.DayNightCheck = false; --A flag for whether the various once-off things that need checking on day/night change have been checked
	self.DayNightIsNight = false; --Flag for whether it's night, true starts the game off during the night, false starts it off during the day
	
	--Changing background
	self.BackgroundChanges = self.BackgroundChanges and self.IsOutside; --Whether or not the background should change, as defined by the scene's datafile
	self.BackgroundTotalNumber = self.BackgroundTotalNumber; --The total number of backgrounds per day/night, as defined by the scene's datafile
	self.BackgroundCurrentNumber = 0; --The current background, must start at 0 to load the first background
	self.BackgroundNames = {[false] = "DayBG", [true] = "NightBG"} --The naming scheme for backgrounds; day is false, night is true
	self.BackgroundPos = self.BackgroundPos; --The position to place backgrounds at (presumably the centre of the scene)
	
	--Sun and moon
	self.CelestialBodies = self.CelestialBodies and self.IsOutside; --Whether or not to have celestial bodies, as defined by the scene's datafile
	self.CelestialBodyName = {[false] = "Sun", [true] = "Moon"} --The naming scheme for mobile celestial bodies; day is false, night is true
	self.CelestialBody = nil; --The actual celestial body object, do not edit this
	self.CelestialBodyWidthVariance = FrameMan.PlayerScreenWidth + 64; --The x distance the celestial body will travel throughout the day, best left as FrameMan.PlayerScreenWidth + CelestialBody's Size*2 so it travels the full screen
	self.CelestialBodyHeight = 100; --The lowest height for the celestial body, where it starts and ends its arc
	self.CelestialBodyHeightVariance = 75 --The maximum height the celestial body rises, the peak of its arc (making it greater than self.CelestialBodyHeight will send it off the screen)
	self.CelestialBodyPathSmoothness = 0.05; --The smoothness/flatness of the path the celestial body travels, any number above 1 will have no effect
	self.CelestialBodyRevealSize = 96; --The width and height of the box of fog the moon will reveal, must be bigger than the moon to work well
	self.CelestialBodySunFrameTotal = self.CelestialBodySunFrameTotal; --The number of frames the sun goes through
	self.CelestialBodyMoonFrameTotal = self.CelestialBodyMoonFrameTotal; --The number of frames the moon goes through
	
	----------------------
	--DAYNIGHT VARIABLES--
	----------------------
	self.CelestialBodyScreenToUse = 0; --The screen to use for celestial body positioning, updated based on which players are dead
	--TODO when it comes out, remove this since each player will have their own celestial body visible only to them. OR if it won't happen, make it check update itself to follow the lowest number living player
	
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
function ModularActivity:AddDayNightLightItem(item)  --TODO Decide if I want daynight to handle this and flashlight, or let the items do it by themselves
	if self.DayNightLightItemTable[item.UniqueID] == nil then
		local str = string.find(item.PresetName,"Chemlight") and "Chemlight" or item.PresetName;
		self.DayNightLightItemTable[item.UniqueID] = {item = item, reveal = self.DayNightLightItemBaseRevealSize[str]};
	end
end
--Add the correct celestial body
function ModularActivity:AddCelestialBody()
	self.CelestialBody = CreateMOSRotating(self.CelestialBodyName[self.DayNightIsNight], self.RTE);
	self.CelestialBody.Pos = self:GetCelestialBodyOffset(self.CelestialBodyScreenToUse);
	MovableMan:AddParticle(self.CelestialBody);
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Swap day and night and act accordingly
function ModularActivity:DoDayNight()
	self:DoDayNightCleanup();
	--Swap from day to night after a certain amount of time
	if self.DayNightTimer:IsPastSimMS(self.DayNightInterval) then
		self:CycleDayNight();
		self.DayNightTimer:Reset();
	end
	
	local timenum = 6 + math.ceil(12*self.DayNightTimer.ElapsedSimTimeMS/self.DayNightInterval);
	local timestring = self.DayNightIsNight and "PM" or "AM";
	if timenum > 12 then
		timenum = timenum - 12;
		timestring = timestring == "PM" and "AM" or "PM";
	end
	self:AddScreenText("The current time is "..tostring(timenum).." "..timestring);
	
	if self.DayNightCheck == false then
		self:DoDayNightChangeActions();
		self.DayNightCheck = true;
	end
	
	--Decorative day/night stuff
	if self.BackgroundChanges then
		self:DoDayNightBackgroundChanges();
	end
	if self.CelestialBodies then --NOTE: Celestial body revealing done in self:DoDayNightContinuousActions()
		if self.CelestialBody == nil or not MovableMan:IsParticle(self.CelestialBody) then
			self:AddCelestialBody();
		end
		--Move the celestial body (accounting for gravity), stopping its rotationg and changing its frame
		self.CelestialBody.Pos = self:GetCelestialBodyOffset(self.CelestialBodyScreenToUse);
		self.CelestialBody.Pos.Y = self.CelestialBody.Pos.Y-((SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs)/3);
		self.CelestialBody.Vel.Y = self.CelestialBody.Vel.Y - SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs;
		self.CelestialBody.RotAngle = 0;
		self.CelestialBody.AngularVel = 0;
		self.CelestialBody.Frame = self:GetCelestialBodyFrame();
	end
	
	--Non-decorative day/night stuff
	self:DoDayNightContinuousActions();
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Cleanup any dead items
function ModularActivity:DoDayNightCleanup()
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
function ModularActivity:DayNightResetBackgroundPosition()
	self.BackgroundPos = Vector(SceneMan.SceneWidth/2, SceneMan.SceneHeight/2);
end
--Cycle the day and night
function ModularActivity:CycleDayNight()
	self.DayNightIsNight = not self.DayNightIsNight;
	if self.BackgroundChanges then
		self.BackgroundCurrentNumber = 0; --Reset the background number
	end
	if self.CelestialBodies then
		self.CelestialBody.ToDelete = true; --Remove the current celestial body
		self.CelestialBody = nil;
	end
	self:DayNightNotifyMany_DayNightCycle();
	self.DayNightCheck = false;
end
--Actions performed once whenever the game changes from night to day
function ModularActivity:DoDayNightChangeActions()
	if self.DayNightIsNight == true then --During the night
	else --During the day
		--Reveal the map (only for Players and NPCs)
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.PlayerTeam);
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.BanditTeam);
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.MilitaryTeam);
		SceneMan:RevealUnseenBox(0,0,SceneMan.Scene.Width,SceneMan.Scene.Height, self.UnknownTeam);
	end
end
--Change the map background based on time of day/night
function ModularActivity:DoDayNightBackgroundChanges()
	local curtime = self.DayNightTimer.ElapsedSimTimeS;
	if curtime/self.DayNightInterval > self.BackgroundCurrentNumber/self.BackgroundTotalNumber then
		self.BackgroundCurrentNumber = self.BackgroundCurrentNumber + 1;
        local obj = CreateTerrainObject(self.BackgroundNames[self.DayNightIsNight]..tostring(self.BackgroundCurrentNumber), self.RTE);
        if obj then
            obj.Pos = self.BackgroundPos;
            obj.Team = -1;
            SceneMan:AddTerrainObject(obj);
        end
	end
end
--Actions performed continuously during day or night, also reveals celestial body
function ModularActivity:DoDayNightContinuousActions()
	if self.DayNightIsNight or not self.IsOutside then --During the night
		--Make everything invisible for humans
		SceneMan:MakeAllUnseen(Vector(24, 24), self.PlayerTeam);
		SceneMan:MakeAllUnseen(Vector(24, 24), self.BanditTeam);
		SceneMan:MakeAllUnseen(Vector(24, 24), self.MilitaryTeam);
		SceneMan:MakeAllUnseen(Vector(24, 24), self.UnknownTeam);
		--Reveal all human visibility areas TODO make flashlight simply affect this instead of working on its own
		for _, humantable in pairs(self.HumanTable) do
			for k, v in pairs(humantable) do
				local xmult = math.cos(v.actor:GetAimAngle(true));
				local ymult = -math.sin(v.actor:GetAimAngle(true));
				
				--Calculate the size of the boxes to reveal based on time of night if outside, or just use the smallest size if not
				local size = self.DayNightRevealBoxMinSize;
				if self.IsOutside then
					local completion = math.max(self.DayNightTimer.ElapsedSimTimeMS/self.DayNightInterval, 0.01); --Make sure we can't divide by 0
					local darknesspercents = {lessthan = 0.5 - self.DayNightRevealAbsoluteDarknessPercent*0.5, greaterthan = 0.5 + self.DayNightRevealAbsoluteDarknessPercent*0.5}
					local diff = self.DayNightRevealBoxMaxSize - self.DayNightRevealBoxMinSize;
					--One fifth of the night remains completely dark
					if completion < darknesspercents.lessthan then
						size = self.DayNightRevealBoxMaxSize - diff*completion/darknesspercents.lessthan;
					elseif completion > darknesspercents.greaterthan then
						size = self.DayNightRevealBoxMinSize + diff*(completion - darknesspercents.greaterthan)/(1-darknesspercents.greaterthan);
					end
				end
				--Place the actual reveal boxes, including one right on top of the player
				for i = 0, self.DayNightNumRevealBoxes do
					local pos = Vector(v.actor.Pos.X + size*2*i*xmult, v.actor.Pos.Y + size*2*i*ymult);
					SceneMan:RevealUnseenBox(pos.X - size, pos.Y - size, size*2, size*2, v.actor.Team);
				end
			end
		end
		--Reveal all areas lit up by items
		for _, v in pairs(self.DayNightLightItemTable) do
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.PlayerTeam);
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.BanditTeam);
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.MilitaryTeam);
			SceneMan:RevealUnseenBox(v.item.Pos.X - v.reveal/2, v.item.Pos.Y - v.reveal/2, v.reveal, v.reveal, self.UnknownTeam);
		end
		--Reveal all extra reveal boxes created by anything else
		if #self.DayNightExtraRevealBoxes > 0 then
			local v;
			for i = #self.DayNightExtraRevealBoxes, 1, -1 do
				v = self.DayNightExtraRevealBoxes[i];
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.PlayerTeam);
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.BanditTeam);
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.MilitaryTeam);
				SceneMan:RevealUnseenBox(v.Corner.X, v.Corner.Y, v.Width, v.Height, self.UnknownTeam);
				table.remove(self.DayNightExtraRevealBoxes, i);
			end
		end
		--Reveal the celestial body if applicable
		if self.CelestialBodies then
			SceneMan:RevealUnseenBox(self.CelestialBody.Pos.X - self.CelestialBodyRevealSize*0.5, self.CelestialBody.Pos.Y - self.CelestialBodyRevealSize*0.5, self.CelestialBodyRevealSize, self.CelestialBodyRevealSize, self.PlayerTeam);
		end
	end
end
--Return the correct position for the celestial body
function ModularActivity:GetCelestialBodyOffset(screen)
	local completion = self.DayNightTimer.ElapsedSimTimeMS/self.DayNightInterval;
	local posx, posy, offsetx, offsety, ylessnum, ygreaternum;
	
	offsetx = SceneMan:GetOffset(screen).X + FrameMan.PlayerScreenWidth/2 - self.CelestialBodyWidthVariance/2;
	posx = offsetx + self.CelestialBodyWidthVariance*completion;
	
	offsety = self.CelestialBodyHeightVariance;
	ylessnum = 0.5 - self.CelestialBodyPathSmoothness*0.5;
	ygreaternum = 0.5 + self.CelestialBodyPathSmoothness*0.5;
	if completion < ylessnum then
		offsety = self.CelestialBodyHeightVariance*((1/ylessnum)*completion);
	elseif completion > ygreaternum then
		offsety = self.CelestialBodyHeightVariance*(ygreaternum/completion);
	end	
	posy = self.CelestialBodyHeight - offsety;
	
	return Vector(posx, posy);
end
--Return the correct frame for the celestial body, based on the time of day/night
function ModularActivity:GetCelestialBodyFrame()
	local framevalues = {[false] = self.CelestialBodySunFrameTotal, [true] = self.CelestialBodyMoonFrameTotal}
	return math.floor(framevalues[self.DayNightIsNight]*self.DayNightTimer.ElapsedSimTimeMS/self.DayNightInterval);
end