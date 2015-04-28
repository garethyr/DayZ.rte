-----------------------------------------------------------------------------------------
-- Play global and location based audio for the players
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartAudio()
	AudioMan:StopMusic();
	
	-------------------
	--AUDIO CONSTANTS--
	-------------------
	--Global
	self.AudioGlobalFadeSpeed = AudioMan.MusicVolume/125; --The speed at which to fade in and out audio, the divisor determines the speed
	self.AudioGlobalMaxVolume = AudioMan.MusicVolume; --The maximum volume to fade-in to, based on the volume set by the player
	self.AudioGlobalMinVolume = 0; --The minimum volume to fade-out to, when the volume reaches this level the next track fades in
	--Localized
	self.AudioDefaultLocalizedAreaName = self.AudioDefaultLocalizedAreaName; --The default area that's not other areas, defined in the scene datafile
	self.AudioLocalizedBaseSoundInterval = 15000; --The base number of MS between playing localized sounds for each player
	self.AudioLocalizedSoundIntervalModifier = self.AudioLocalizedBaseSoundInterval/3; --The randomizing modifier for the localized sound interval, adds between 0 and this many MS to the interval
	--Suspense
	--NOTE: There's no way to tell if a suspense sound is playing so the timer resets once the sound starts playing. Thus no sound should ever be longer than the base interval
	self.AudioSuspenseBaseSoundInterval = 45000; --The base number of MS between playing suspense sounds
	self.AudioSuspenseSoundIntervalModifier = self.AudioSuspenseBaseSoundInterval/3; --The randomizing modifier for the suspense sound interval, adds between 0 and this many MS to the interval
	self.AudioSuspenseTimer = Timer();
	
	self.AudioPath = "DayZ.rte/Sounds/" --The path to the audio folder
	self.AudioTableSetup =  {Localized = {
								["Nature Day"] = {17, "DAmbient "},
								["Nature Night"] = {18, "NAmbient "},
								["Civilization"] = {9, "CAmbient "},
								["Beach"] = {3, "BAmbient "},
								["Underground"] = {1, "UAmbient "}},
							Suspense = {16, "Suspense "}};
								
	
	---------------
	--AUDIO AREAS--
	---------------
	self.AudioAreas = {["Civilization Areas"] = {}, ["Beach Areas"] = {}};
	for i = 1, self.NumberOfAudioCivilizationAreas do
		self.AudioAreas["Civilization Areas"][i] = {area = SceneMan.Scene:GetArea("Civilization Area "..tostring(i)), name = "Civilization"};
	end
	for i = 1, self.NumberOfAudioBeachAreas do
		self.AudioAreas["Beach Areas"][i] = {area = SceneMan.Scene:GetArea("Beach Area "..tostring(i)), name = "Beach"};
	end
	
	-----------------------
	--STATIC AUDIO TABLES--
	-----------------------
	--Global
	self.AudioGlobalSoundTable = {day = self.AudioPath.."Global/Day Loop.ogg",
								  night = self.AudioPath.."Global/Night Loop.ogg",
								  storm = self.AudioPath.."Global/Stormy Loop.ogg"};
	self.AudioGlobalSoundOverrideTable = {beach = self.AudioPath.."Global/Beach Loop.ogg", underground = self.AudioPath.."Global/Underground Loop.ogg"}
	--Localized and suspense
	self.AudioLocalizedSoundDefinitionTable = {};
	self.AudioSuspenseSoundDefinitionTable = {};
	for k, v in pairs(self.AudioTableSetup) do
		--Setup name table for localized sound emitters
		if (k == "Localized") then
			for subtype, subtable in pairs(v) do
				self.AudioLocalizedSoundDefinitionTable[subtype] = {size = subtable[1]};
				for i = 1, subtable[1] do
					table.insert(self.AudioLocalizedSoundDefinitionTable[subtype], subtable[2]..tostring(i));
				end
			end
		--Setup name table for non-localized suspense sounds
		elseif (k == "Suspense") then
			self.AudioSuspenseSoundDefinitionTable = {size = v[1]};
			for i = 1, v[1] do
				table.insert(self.AudioSuspenseSoundDefinitionTable, self.AudioPath..k.."/"..v[2]..tostring(i)..".ogg");
			end
		end
	end
	
	------------------------
	--DYNAMIC AUDIO TABLES--
	------------------------
	--Localized
	--A table of all localized sounds, the key is the player number (i.e. 0 - 3)
	--Keys - Values
	--sound = the sound emitter, target = the actor target, stype = the type of sound (i.e. Nature, Civilization, etc.),
	--timer = the timer to delay playing sounds, interval = the interval in between each sound, randomly defined on sound creation
	self.AudioLocalizedSoundTable = {};
	
	-------------------
	--AUDIO VARIABLES--
	-------------------
	--Global
	self.AudioGlobalCurrentSound = nil;
	self.AudioGlobablOverrideSound = nil;
	self.AudioGlobalSoundStatus = "ready";
	--Localized
	--Suspense
	self.AudioSuspenseSoundInterval = self.AudioSuspenseBaseSoundInterval; --The current number of MS between playing suspense sounds
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an audio emitter to the table
function ModularActivity:AudioAddLocalizedSound(actor, areaname)
	local choice = math.random(1, self.AudioLocalizedSoundDefinitionTable[areaname].size);
	local emitter = CreateAEmitter(self.AudioLocalizedSoundDefinitionTable[areaname][choice], self.RTE);
	emitter.Pos = actor.Pos;
	MovableMan:AddParticle(emitter);
	
	local player = actor:GetController().Player;
	--Remake the table if it got completely removed cause its actor died
	if self.AudioLocalizedSoundTable[player] == nil then
		self.AudioLocalizedSoundTable[player] = {target = actor, timer = Timer()};
	end
	self.AudioLocalizedSoundTable[player].sound = emitter;
	self.AudioLocalizedSoundTable[player].stype = areaname;
	self.AudioLocalizedSoundTable[player].timer:Reset();
	self.AudioLocalizedSoundTable[player].interval = self.AudioLocalizedBaseSoundInterval + math.floor(math.random(0, self.AudioLocalizedSoundIntervalModifier));
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Manage and play all audio
function ModularActivity:DoAudio()
	self:CleanupAudio();
	self:AudioDoLocalSounds();
	self:AudioDoSuspenseSounds();
	
	if self.AudioGlobalSoundStatus:find("fade") then
		self:AudioDoGlobalSoundTransitions();
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Find any audio emitters that need to be removed
function ModularActivity:CleanupAudio()
	for k, v in pairs (self.AudioLocalizedSoundTable) do
		if not MovableMan:IsActor(v.target) then
			self.AudioLocalizedSoundTable[k] = nil;
		elseif v.sound ~= nil and not MovableMan:IsParticle(v.sound) then
			v.sound = nil;
			v.timer:Reset();
		end
	end
end
--------------------
--ACTION FUNCTIONS--
--------------------
--GLOBAL--
--Deal with global audio, based on time of day and weather
function ModularActivity:AudioChangeGlobalSound(soundtype) --Called by notifications from DayNight and Weather module
	if self.AudioGlobalCurrentSound ~= soundtype then
		self.AudioGlobalCurrentSound = soundtype;
		self.AudioGlobalSoundStatus = "fadeout";
	end
end
function ModularActivity:AudioChangeGlobalOverrideSound(overridesound)
	if self.AudioGlobalCurrentOverrideSound ~= overridesound then
		self.AudioGlobalCurrentOverrideSound = overridesound;
		self.AudioGlobalSoundStatus = "fadeout";
	end
end
--Fade in and out sound and transition between it when it's done fading
function ModularActivity:AudioDoGlobalSoundTransitions()
	if self.AudioGlobalSoundStatus == "fadeout" and AudioMan.MusicVolume >= self.AudioGlobalMinVolume then
		AudioMan.MusicVolume = AudioMan.MusicVolume - self.AudioGlobalFadeSpeed;
		if AudioMan.MusicVolume <= self.AudioGlobalMinVolume then
			AudioMan.MusicVolume = self.AudioGlobalMinVolume;
			self.AudioGlobalSoundStatus = "fadein";
			AudioMan:StopMusic();
			if self.AudioGlobalCurrentOverrideSound ~= nil then
				AudioMan:PlayMusic(self.AudioGlobalSoundOverrideTable[self.AudioGlobalCurrentOverrideSound], -1, -1); --Play infinitely with no volume override
			else
				AudioMan:PlayMusic(self.AudioGlobalSoundTable[self.AudioGlobalCurrentSound], -1, -1); --Play infinitely with no volume override
			end
		end
	elseif self.AudioGlobalSoundStatus == "fadein" and AudioMan.MusicVolume <= self.AudioGlobalMaxVolume then
		AudioMan.MusicVolume = AudioMan.MusicVolume + self.AudioGlobalFadeSpeed;
		if AudioMan.MusicVolume >= self.AudioGlobalMaxVolume then
			AudioMan.MusicVolume = self.AudioGlobalMaxVolume;
			self.AudioGlobalSoundStatus = "ready";
		end
	end
end
--LOCAL--
--Deal with local sounds, add them and move them as necessary
function ModularActivity:AudioDoLocalSounds()
	for i = 0, Activity.MAXPLAYERCOUNT do
		if self:PlayerHuman(i) then
			local tab = self.AudioLocalizedSoundTable[i];
			if tab == nil or (tab ~= nil and tab.timer:IsPastSimMS(tab.interval)) then
				local actor = self:GetControlledActor(i);
				if actor ~= nil and actor.ClassName == "AHuman" then
					local areaname = self:GetActorAudioArea(actor);
					self:AudioAddLocalizedSound(actor, areaname);
				end
			else
				if MovableMan:IsParticle(tab.sound) and MovableMan:IsActor(tab.target) then
					tab.sound.Pos = tab.target.Pos;
				end
			end
		end
	end
end
--Get the audio area the actor is in
function ModularActivity:GetActorAudioArea(actor)
	for areatype, areatable in pairs (self.AudioAreas) do
		for i, v in ipairs(areatable) do
			if v.area:IsInside(actor.Pos) then
				if v.name == "Beach" then
					self:AudioChangeGlobalOverrideSound("beach");
				else
					self:AudioChangeGlobalOverrideSound(nil);
				end
				return v.name;
			end
		end
	end
	--If not in an area, return the default audio accounting for day or night
	return self.AudioDefaultLocalizedAreaName..self:AudioRequestDayNight_DayOrNightOrEmptyFormattedString();
end
-- function ModularActivity:GetActorAudioArea(actor)
		-- print ("A1");
		-- ConsoleMan:SaveAllText("output");
	-- for _, areatype in pairs (self.AudioAreas) do
		-- print ("A2");
		-- ConsoleMan:SaveAllText("output");
		-- for i, v in ipairs(areatype) do
		-- print ("A3");
		-- ConsoleMan:SaveAllText("output");
			-- if v.area:IsInside(actor.Pos) then
		-- print ("A4");
		-- ConsoleMan:SaveAllText("output");
				-- if v.name == "Beach" then
		-- print ("A51");
		-- ConsoleMan:SaveAllText("output");
					-- self:AudioChangeGlobalOverrideSound("beach");
		-- print ("A61");
		-- ConsoleMan:SaveAllText("output");
				-- else
		-- print ("A52");
		-- ConsoleMan:SaveAllText("output");
					-- self:AudioChangeGlobalOverrideSound(nil);
		-- print ("A62");
		-- ConsoleMan:SaveAllText("output");
				-- end
		-- print ("A7");
		-- ConsoleMan:SaveAllText("output");
				-- return v.name;
			-- end
		-- print ("An inner loop done");
		-- ConsoleMan:SaveAllText("output");
		-- end
		-- print ("An outer loop done");
		-- ConsoleMan:SaveAllText("output");
	-- end
		-- print ("A8");
		-- ConsoleMan:SaveAllText("output");
	-- If not in an area, return the default audio accounting for day or night
	-- return self.AudioDefaultLocalizedAreaName..self:AudioRequestDayNight_DayOrNightOrEmptyFormattedString();
-- end
--SUSPENSE--
--Deal with suspense sounds, play them randomly over time
function ModularActivity:AudioDoSuspenseSounds()
	if self.AudioSuspenseTimer:IsPastSimMS(self.AudioSuspenseSoundInterval) then
		local choice = math.random(1, self.AudioSuspenseSoundDefinitionTable.size);
		AudioMan:PlaySound(self.AudioSuspenseSoundDefinitionTable[choice]);
		self.AudioSuspenseSoundInterval = self.AudioSuspenseBaseSoundInterval + math.random(0, self.AudioSuspenseSoundIntervalModifier);
		self.AudioSuspenseTimer:Reset();
	end
end