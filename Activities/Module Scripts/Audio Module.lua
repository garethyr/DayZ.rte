-----------------------------------------------------------------------------------------
-- Play global and location based audio for the players
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartAudio()
	AudioMan:StopMusic();
	
	-------------------
	--AUDIO CONSTANTS--
	-------------------
	--Global
	self.AudioGlobalFadeSpeed = AudioMan.MusicVolume/125; --The speed at which to fade in and out audio, the divisor determines the speed
	self.AudioGlobalMaxVolume = AudioMan.MusicVolume; --The maximum volume to fade-in to, based on the volume set by the player
	self.AudioGlobalMinVolume = 0; --The minimum volume to fade-out to, when the volume reaches this level the next track fades in
	--Localized
	self.AudioDefaultLocalizedAreaName = "Nature"; --The default area that's not other areas
	self.AudioLocalizedBaseSoundInterval = 15000; --The base number of MS between playing localized sounds for each player
	self.AudioLocalizedSoundIntervalModifier = self.AudioLocalizedBaseSoundInterval/3; --The randomizing modifier for the localized sound interval, adds between 0 and this many MS to the interval
	--Suspense
	--NOTE: There's no way to tell if a suspense sound is playing so the timer resets once the sound starts playing. Thus no sound should ever be longer than the base interval
	self.AudioSuspenseBaseSoundInterval = 45000; --The base number of MS between playing suspense sounds
	self.AudioSuspenseSoundIntervalModifier = self.AudioSuspenseBaseSoundInterval/3; --The randomizing modifier for the suspense sound interval, adds between 0 and this many MS to the interval
	self.AudioSuspenseTimer = Timer();
	
	self.AudioPath = "DayZ.rte/Sounds/" --The path to the audio folder
	self.AudioTableSetup =  {Localized = {
								["Nature Day"] = {19, "DAmbient "},
								["Nature Night"] = {21, "NAmbient "},
								["Civilization"] = {9, "CAmbient "},
								["Beach"] = {1, "DAmbient "}},
							Suspense = {17, "Suspense "}};
								
	
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
	self.AudioGlobalSoundTable = {day = self.AudioPath.."Non-Localized/Day Loop.ogg",
								  night = self.AudioPath.."Non-Localized/Night Loop.ogg",
								  storm = self.AudioPath.."Non-Localized/Stormy Loop.ogg"}
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
			for i = 1, v[1] do --TODO when new version of CC is released, swap over to using PlaySound for proper full map coverage
				table.insert(self.AudioSuspenseSoundDefinitionTable, v[2]..tostring(i));--self.AudioPath..k.."/"..v[2]..tostring(i)..".ogg");
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
	self.AudioGlobalSoundStatus = "ready";
	--Localized
	--Suspense
	self.AudioSuspenseSoundInterval = self.AudioSuspenseBaseSoundInterval; --The current number of MS between playing suspense sounds
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an audio emitter to the table
function Chernarus:AudioAddLocalizedSound(actor, areaname)
	local choice = math.random(1, self.AudioLocalizedSoundDefinitionTable[areaname].size);
	local emitter = CreateAEmitter(self.AudioLocalizedSoundDefinitionTable[areaname][choice], "DayZ.rte");
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
function Chernarus:DoAudio()
	self:CleanupAudio();
	self:AudioDoLocalSounds(); --TODO Simplify this, it doesn't need any complexity
	self:AudioDoSuspenseSounds();
	
	if self.AudioGlobalSoundStatus:find("fade") then
		self:AudioDoGlobalSoundTransitions();
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Find any audio emitters that need to be removed
function Chernarus:CleanupAudio()
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
function Chernarus:AudioChangeGlobalSounds(soundtype) --Called by notifications from DayNight and Weather module
	if self.AudioGlobalCurrentSound ~= soundtype then
		self.AudioGlobalCurrentSound = soundtype;
		self.AudioGlobalSoundStatus = "fadeout";
	end
end
--Fade in and out sound and transition between it when it's done fading
function Chernarus:AudioDoGlobalSoundTransitions()
	if self.AudioGlobalSoundStatus == "fadeout" and AudioMan.MusicVolume >= self.AudioGlobalMinVolume then
		AudioMan.MusicVolume = AudioMan.MusicVolume - self.AudioGlobalFadeSpeed;
		if AudioMan.MusicVolume <= self.AudioGlobalMinVolume then
			AudioMan.MusicVolume = self.AudioGlobalMinVolume;
			self.AudioGlobalSoundStatus = "fadein";
			AudioMan:StopMusic();
			AudioMan:PlayMusic(self.AudioGlobalSoundTable[self.AudioGlobalCurrentSound], -1, -1); --Play infinitely with no volume override
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
function Chernarus:AudioDoLocalSounds()
	for i = 0, Activity.MAXPLAYERCOUNT do
		if self:PlayerHuman(i) then
			local tab = self.AudioLocalizedSoundTable[i];
			if tab == nil or (tab ~= nil and tab.timer:IsPastSimMS(tab.interval)) then
				local actor = self:GetControlledActor(i);
				if actor ~= nil then
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
function Chernarus:GetActorAudioArea(actor)
	for _, areatype in pairs (self.AudioAreas) do
		for i, v in ipairs(areatype) do
			if v.area:IsInside(actor.Pos) then
				return v.name;
			end
		end
	end
	--If not in an area, return the default audio accounting for day or night
	return self.AudioDefaultLocalizedAreaName.." "..self:AudioRequestDayNight_DayOrNightCapitalizedString();
end
--SUSPENSE--
--Deal with suspense sounds, play them randomly over time
function Chernarus:AudioDoSuspenseSounds() --TODO when new version of CC is released, swap over to using PlaySound for proper full map coverage
	if self.AudioSuspenseTimer:IsPastSimMS(self.AudioSuspenseSoundInterval) then
		local choice = math.random(1, self.AudioSuspenseSoundDefinitionTable.size);
		local postable = {100, SceneMan.SceneWidth/2, SceneMan.SceneWidth - 100};
		for i = 1, 3 do
			local emitter = CreateAEmitter(self.AudioSuspenseSoundDefinitionTable[choice], "DayZ.rte");
			emitter.Pos = Vector(postable[i], SceneMan.SceneHeight/2);
			MovableMan:AddParticle(emitter);
		end
		--AudioMan:PlaySound(self.AudioSuspenseSoundDefinitionTable[choice]);
		self.AudioSuspenseSoundInterval = self.AudioSuspenseBaseSoundInterval + math.random(0, self.AudioSuspenseSoundIntervalModifier);
		self.AudioSuspenseTimer:Reset();
	end
end