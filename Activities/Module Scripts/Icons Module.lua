-----------------------------------------------------------------------------------------
-- Display meters for player stats and any other icons
-----------------------------------------------------------------------------------------
--Setup
function Chernarus:StartIcons()
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
function Chernarus:AddToMeterTable(actor)
	self.MeterTable[actor.UniqueID] = {};
	self.MeterTable[actor.UniqueID].actor = actor;
	self.MeterTable[actor.UniqueID].screen = actor:GetController().Player; --Starts as -1 as there actor isn't selected yet
	for k, v in pairs (self.MeterSetupTable) do
		local meter = CreateMOSRotating(k, "DayZ.rte");
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
function Chernarus:DoIcons()
	self:DoMeters();
end
--------------------
--DELETE FUNCTIONS--
--------------------
function Chernarus:IconsRemoveMeter(ID)
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
function Chernarus:DoMeters()
	for _, meters in pairs (self.MeterTable) do
		--Update meter positions and frames
		for k, meter in pairs (meters) do
			if type(k) == "number" then
				--Update the position so meters keep floating
				meter.Pos = self.MeterSetupTable[meter.PresetName].pos(meters.screen);
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
				meteractions[meter.PresetName](meter, meters.actor);
			end
		end
		--Add screens for any meters that don't have it yet
		if meters.screen == -1 then
			meters.screen = meters.actor:GetController().Player; --TODO player might not work, may need to actively get the screen from the player somehow
																	--To get screen of player, use Activity.ScreenOfPlayer(player)
		end
		self:IconsNotifyDayNight_RevealIcons(SceneMan:GetOffset(meters.screen));
	end
end