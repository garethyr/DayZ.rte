
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeHumanAI")	--dofile("Base.rte/Actors/AI/NativeHumanAI.lua")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
	for A in MovableMan.Actors do A.IgnoresTeamHits = false
	end
end


function Create(self)
	self.curteam = self.Team
	self.shottimer = Timer();
end

function Update(self)
	if self:GetController():IsState(Controller.BODY_CROUCH) then
		self.Team = 1 - self.curteam
	end
	if self:GetController():IsState(Controller.WEAPON_FIRE) then
		self.Team = self.curteam
		self.shottimer:Reset()
	end
	if not(self.shottimer:IsPastRealMS(2000)) then
		self.Team = self.curteam
	end
	if self.Health <= .5 then
		self.Team = self.curteam
	end
	for actor in MovableMan.Actors do
		if (self:GetController():IsState(Controller.BODY_JUMP)) or (self:GetController():IsState(Controller.MOVE_LEFT)) or (self:GetController():IsState(Controller.MOVE_RIGHT)) then
			if (actor.Pos.X >= self.Pos.X - 175) and (actor.Pos.X <= self.Pos.X + 175) and (actor.Pos.Y >= self.Pos.Y - 175) and (actor.Pos.Y <= self.Pos.Y + 175) and (actor.ClassName == "AHuman") then
				if (actor.Pos.X >= self.Pos.X - 175) and (math.deg(actor:GetAimAngle(true)) <= 90) and (math.deg(actor:GetAimAngle(true)) >= 270) then
					self.Team = self.curteam
				end
				if (actor.Pos.X >= self.Pos.X - 175) and (math.deg(actor:GetAimAngle(true)) >= 90) and (math.deg(actor:GetAimAngle(true)) <= 270) then
					self.Team = 1 - self.curteam
				end
				if (actor.Pos.X <= self.Pos.X + 175) and (math.deg(actor:GetAimAngle(true)) >= 90) and (math.deg(actor:GetAimAngle(true)) <= 270) then
					self.Team = self.curteam
				end
				if (actor.Pos.X <= self.Pos.X + 175) and (math.deg(actor:GetAimAngle(true)) <= 90) and (math.deg(actor:GetAimAngle(true)) >= 270) then
					self.Team = 1 - self.curteam
				end
			end
			if not(actor.Pos.X >= self.Pos.X - 175) and not(actor.Pos.X <= self.Pos.X + 175) and not(actor.Pos.Y >= self.Pos.Y - 175) and not(actor.Pos.Y <= self.Pos.Y + 175) and (actor.ClassName == "AHuman") then
				self.Team = 1 - self.curteam
			end
		end
	end
end

function Destroy(self)
	self.Team = self.curteam
end