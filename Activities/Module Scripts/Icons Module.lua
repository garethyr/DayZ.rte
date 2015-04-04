-----------------------------------------------------------------------------------------
-- Display meters for player stats and any other icons
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartIcons()
	------------------
	--ICON CONSTANTS--
	------------------
	self.IconNumMeters = 5;
	self.IconMeterSpacing = 50;
	----------------------
	--DYNAMIC ICON TABLE--
	----------------------
	--This table stores all meter objects (i.e. icons that position to a player)
	--Keys - Values:
	--Key is actor.UniqueID, value is a table of icon MOSRotatings as well as the actor and his screen
	self.MeterTable = {};
	
	---------------------
	--STATIC ICON TABLE--
	--------------------- 
	--This table stores all the meter names and their position modifiers (i.e. where they line up)
	self.MeterSetupTable = {
		["Sound Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconMeterSpacing*1, SceneMan:GetOffset(screen).Y + self.IconMeterSpacing*1) end},
		["Light Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconMeterSpacing*2, SceneMan:GetOffset(screen).Y + self.IconMeterSpacing*1) end},
		["Thirst Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconMeterSpacing*3, SceneMan:GetOffset(screen).Y + self.IconMeterSpacing*1) end},
		["Hunger Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconMeterSpacing*4, SceneMan:GetOffset(screen).Y + self.IconMeterSpacing*1) end},
		["Blood Meter"] = {pos = function(screen) return Vector(SceneMan:GetOffset(screen).X + self.IconMeterSpacing*5, SceneMan:GetOffset(screen).Y + self.IconMeterSpacing*1) end},
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
	for k, v in pairs (self.MeterSetupTable) do
		local meter = CreateMOSRotating(k, self.RTE);
		meter.Vel = Vector(0, 0);
		meter.AngularVel = 0;
		meter.Pos = v.pos(self.MeterTable[actor.UniqueID].screen);
		MovableMan:AddParticle(meter);
		table.insert(self.MeterTable[actor.UniqueID], meter);
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
	for k, v in pairs(self.MeterTable) do
		if not MovableMan:IsActor(v.actor) then
			print ("Removing icon from nonexistant actor");
			self:IconsRemoveMeter(k);
		elseif MovableMan:IsActor(v.actor) and v.actor.UniqueID ~= k then
			print ("Removing icon from mismatched actor and ID");
			self:IconsRemoveMeter(k);
			if self.MeterTable[v.actor.UniqueID] == nil then
				print ("Mismatched actor is not in icon table, readding actor");
				AddToMeterTable(actor);
			end
		end
	end	
end
--Remove a given set of meter
function ModularActivity:IconsRemoveMeters(ID)
	for k, v in pairs(self.MeterTable[ID]) do
		if type(k) == "number" then
			v.ToDelete = true;
		end
	end
	self.MeterTable[ID] = nil;
end
--------------------
--ACTION FUNCTIONS--
--------------------
--Manage all meters
function ModularActivity:DoMeters()
	for _, playermeters in pairs (self.MeterTable) do
		--Add screens for any meters that don't have them yet
		if playermeters.screen == -1 then
			playermeters.screen = self:ScreenOfPlayer(playermeters.actor:GetController().Player);
			--print ("Set screen for meter on actor "..tostring(playermeters.actor).." as "..tostring(playermeters.screen));
		end
		--Update meter positions and frames for meters with screens
		if playermeters.screen > -1 then
			for k, meter in pairs (playermeters) do
				if type(k) == "number" then
					--Update the position so meters keep floating
					--print ("Update meter "..meter.PresetName.." for screen "..tostring(playermeters.screen).." to position "..tostring(SceneMan:GetOffset(playermeters.screen)));
					meter.Pos = self.MeterSetupTable[meter.PresetName].pos(playermeters.screen);
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
					meteractions[meter.PresetName](meter, playermeters.actor);
				end
			end
		end
		--Reveal the icons if necessary
		self:IconsNotifyDayNight_RevealIcons(SceneMan:GetOffset(playermeters.screen));
	end
end