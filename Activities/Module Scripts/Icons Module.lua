-----------------------------------------------------------------------------------------
-- Display meters for player stats and any other icons
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartIcons()
	------------------
	--ICON CONSTANTS--
	------------------
	self.IconsNumMeters = 5; --The number of player icons for activity, sustenance, health, etc. values
	self.IconsMeterSpacing = 50; --The space in between each icon's position, must be larger than the icon's size to prevent overlap
	self.IconsLeftmostMeter = {name = "Sound Meter", size = Vector(40, 32)}; --The leftmost icon in the set of meters for a player along with its size. Used for revealing meters during night
	----------------------
	--DYNAMIC ICON TABLE--
	----------------------
	--This table stores all meter objects (i.e. icons that position to a player). Key is actor.UniqueID
	--Keys - Values:
	--actor = the actor to follow and give information about, screen = the actor's controlling player, meters = {MeterName = the icon MOSRotatings}
	self.MeterTable = {};
	
	---------------------
	--STATIC ICON TABLE--
	--------------------- 
	--This table stores all the meter names and their position modifiers (i.e. where they line up)
	local xmult = function(screen) if FrameMan.HSplit and (screen == 1 or screen == 3) then return 1 else return 0 end end --Return a multiplier for screen X positioning, based on the current player
	local ymult = function(screen) if FrameMan.VSplit and (screen == 2 or screen == 3) then return 1 else return 0 end end --Return a multiplier for screen Y positioning, based on the current player
	self.MeterSetupTable = { --TODO make this work properly with split screens
		["Sound Meter"] = {pos = function(screen) return Vector(FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*1, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1) end},
		["Light Meter"] = {pos = function(screen) return Vector(FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*2, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1) end},
		["Thirst Meter"] = {pos = function(screen) return Vector(FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*3, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1) end},
		["Hunger Meter"] = {pos = function(screen) return Vector(FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*4, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1) end},
		["Blood Meter"] = {pos = function(screen) return Vector(FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*5, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1) end},
		-- ["Sound Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*1, SceneMan:GetOffset(screen).Y + self.IconsMeterSpacing*1) end},
		-- ["Light Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*2, SceneMan:GetOffset(screen).Y + self.IconsMeterSpacing*1) end},
		-- ["Thirst Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*3, SceneMan:GetOffset(screen).Y + self.IconsMeterSpacing*1) end},
		-- ["Hunger Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*4, SceneMan:GetOffset(screen).Y + self.IconsMeterSpacing*1) end},
		-- ["Blood Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*5, SceneMan:GetOffset(screen).Y + self.IconsMeterSpacing*1) end},
	};
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an actor to the meter table
function ModularActivity:AddToMeterTable(actor)
	self.MeterTable[actor.UniqueID] = {};
	self.MeterTable[actor.UniqueID].actor = actor;
	self.MeterTable[actor.UniqueID].screen = actor:GetController().Player; --Starts as -1 as there actor isn't selected yet
	self.MeterTable[actor.UniqueID].meters = {};
	for k, v in pairs (self.MeterSetupTable) do
		local meter = CreateMOSRotating(k, self.RTE);
		meter.Vel = Vector(0, 0);
		meter.AngularVel = 0;
		meter.Pos = v.pos(self.MeterTable[actor.UniqueID].screen);
		MovableMan:AddParticle(meter);
		self.MeterTable[actor.UniqueID].meters[k] = meter;
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--Update frame and position for all icons
function ModularActivity:DoIcons()
	self:IconsCleanupMeters();
	self:DoMeters();
	--Show the score in screentext
	self:AddScreenText("Total Zombies Killed: "..tostring(self.ZombiesKilled));
	self:AddScreenText("Nights Survived: "..tostring(self.NightsSurvived));
end
--------------------
--DELETE FUNCTIONS--
--------------------
--Remove any meters whose actor is no longer alive or whose key (UniqueID) does not match their actor's UniqueID
function ModularActivity:IconsCleanupMeters()
	for ID, metertable in pairs(self.MeterTable) do
		if not MovableMan:IsActor(metertable.actor) then
			print ("Removing meters from nonexistant actor with id "..tostring(ID));
			self:IconsRemoveMeters(ID);
		elseif MovableMan:IsActor(metertable.actor) and metertable.actor.UniqueID ~= ID then
			print ("Removing meters from mismatched actor and ID");
			self:IconsRemoveMeters(ID);
			if self.MeterTable[metertable.actor.UniqueID] == nil then
				print ("Mismatched actor is not in meter table, readding actor");
				self:AddToMeterTable(actor);
			end
		end
	end	
end
--Remove a given set of meter
function ModularActivity:IconsRemoveMeters(ID)
	for k, v in pairs(self.MeterTable[ID].meters) do
		v.ToDelete = true;
	end
	self.MeterTable[ID] = nil;
	print ("Removed meters for player with unique id "..tostring(ID));
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Manage all meters
function ModularActivity:DoMeters()
	for _, playermeter in pairs (self.MeterTable) do
		--Add screens for any meters that don't have them yet
		if playermeter.screen == -1 then
			playermeter.screen = self:ScreenOfPlayer(playermeter.actor:GetController().Player);
			print ("Set screen for meter on actor "..tostring(playermeter.actor).." as "..tostring(playermeter.screen));
		end
		--Update meter positions and frames for meters with screens
		if playermeter.screen > -1 then
			for _, meter in pairs (playermeter.meters) do
				--Update the position so meters keep floating
				--print ("Update meter "..meter.PresetName.." for screen "..tostring(playermeter.screen).." to position "..tostring(SceneMan:GetOffset(playermeter.screen)));
				meter.Pos = self.MeterSetupTable[meter.PresetName].pos(playermeter.screen);
				meter.Pos.Y = meter.Pos.Y-((SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs)/3);
				meter.Vel.Y = meter.Vel.Y - SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs;
				
				--Update the frame based on parameters
				local meteractions = {
					["Sound Meter"] = function(meter, actor) meter.Frame = math.floor(meter.FrameCount*self:IconsRequestAlerts_ActorActivityPercent("sound", actor)) end,
					["Light Meter"] = function(meter, actor) meter.Frame = math.floor(meter.FrameCount*self:IconsRequestAlerts_ActorActivityPercent("light", actor)) end,
					["Thirst Meter"] = function(meter, actor) meter.Frame = math.floor(meter.FrameCount*self:IconsRequestSustenance_ActorSustenancePercent("thirst", actor)) end,
					["Hunger Meter"] = function(meter, actor) meter.Frame = math.floor(meter.FrameCount*self:IconsRequestSustenance_ActorSustenancePercent("hunger", actor)) end,
					["Blood Meter"] = function(meter, actor) meter.Frame = math.floor(meter.FrameCount*(100 - actor.Health)/100) end,
				}
				meteractions[meter.PresetName](meter, playermeter.actor);
			end
		end
		--Reveal the icons if necessary
		--FrameMan.PlayerScreenWidth*xmult(screen) + SceneMan:GetOffset(screen).X + self.IconsMeterSpacing*1, FrameMan.PlayerScreenHeight*ymult(screen) + self.IconsMeterSpacing*1
		local cornerpos = playermeter.meters[self.IconsLeftmostMeter.name].Pos;
		self:IconsNotifyDayNight_RevealIcons(Vector(cornerpos.X - self.IconsLeftmostMeter.size.X/2, cornerpos.Y - self.IconsLeftmostMeter.size.Y/2));
	end
end