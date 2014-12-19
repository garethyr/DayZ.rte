-----------------------------------------------------------------------------------------
-- Play global and location based audio for the players
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartAudio()
	AudioMan:StopMusic();
	-----------------------
	--DYNAMIC AUDIO TABLE--
	-----------------------
	self.LocalizedAudioTable = {};
	
	----------------------
	--STATIC AUDIO TABLE--
	----------------------
	self.AudioGlobalSoundTable = {day = "DayZ.rte/Sounds/Non-Localized/Day Loop.ogg",
								  night = "DayZ.rte/Sounds/Non-Localized/Night Loop.ogg",
								  storm = "DayZ.rte/Sounds/Non-Localized/Stormy Loop.ogg"}
	
	-------------------
	--AUDIO CONSTANTS--
	-------------------
	self.AudioGlobalFadeSpeed = AudioMan.MusicVolume/125; --The speed at which to fade in and out audio, the divisor determines the speed - default 250
	self.AudioGlobalMaxVolume = AudioMan.MusicVolume; --The maximum volume to fade-in to, based on the volume set by the player
	self.AudioGlobalMinVolume = 0; --The minimum volume to fade-out to, when the volume reaches this level the next track fades in
	print (self.AudioGlobalMaxVolume)
	
	-------------------
	--AUDIO VARIABLES--
	-------------------
	self.CurrentGlobalAudio = nil;
	self.AudioGlobalSoundStatus = "ready";
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an audio emitter to the table
function Chernarus:AudioAddLocalizedSound(emitter)
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Manage and play all audio
function Chernarus:DoAudio()
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
function Chernarus:CleanupAudio()
end
--Remove unused audio emitters from the table
function Chernarus:AudioRemoveLocalizedSound(emitter)
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Deal with global audio, based on time of day and weather
function Chernarus:AudioChangeGlobalSounds(status) --Called by notifications from DayNight and Weather module
	if self.CurrentGlobalAudio ~= status then
		self.CurrentGlobalAudio = status;
		self.AudioGlobalSoundStatus = "fadeout";
	end
	
end
--Fade in and out sound and transition between it when it's done fading
function Chernarus:AudioDoGlobalSoundTransitions()
	if self.AudioGlobalSoundStatus == "fadeout" and AudioMan.MusicVolume >= self.AudioGlobalMinVolume then
		AudioMan.MusicVolume = AudioMan.MusicVolume - self.AudioGlobalFadeSpeed;
		if AudioMan.MusicVolume <= self.AudioGlobalMinVolume then
			print ("faded out");
			AudioMan.MusicVolume = self.AudioGlobalMinVolume;
			self.AudioGlobalSoundStatus = "fadein";
			AudioMan:StopMusic();
			AudioMan:PlayMusic(self.AudioGlobalSoundTable[self.CurrentGlobalAudio], -1, -1); --Play infinitely with no volume override
		end
	elseif self.AudioGlobalSoundStatus == "fadein" and AudioMan.MusicVolume <= self.AudioGlobalMaxVolume then
		AudioMan.MusicVolume = AudioMan.MusicVolume + self.AudioGlobalFadeSpeed;
		if AudioMan.MusicVolume >= self.AudioGlobalMaxVolume then
			print ("faded in");
			AudioMan.MusicVolume = self.AudioGlobalMaxVolume;
			self.AudioGlobalSoundStatus = "ready";
		end
	end
end
function Chernarus:AudioDoLocalSounds()
end
function Chernarus:AudioDoSuspenseSounds()
end