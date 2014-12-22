function Create(self)
	self.Speed = 5;
	self.HUDVisible = false
end
function Update(self)
	self.Pos.Y = self.Pos.Y-((SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs)/3);
	self.Vel.Y = self.Vel.Y - SceneMan.GlobalAcc.Y*TimerMan.DeltaTimeSecs;
	self.RotAngle = 0;
	if self:GetController():IsState(Controller.MOVE_LEFT) then
		self.Pos.X = self.Pos.X - self.Speed;
	elseif self:GetController():IsState(Controller.MOVE_RIGHT) then
		self.Pos.X = self.Pos.X + self.Speed;
	end
	if self:GetController():IsState(Controller.MOVE_UP) then
		self.Pos.Y = self.Pos.Y - self.Speed;
	elseif self:GetController():IsState(Controller.MOVE_DOWN) then
		self.Pos.Y = self.Pos.Y + self.Speed;
	end
	ToGameActivity(ActivityMan:GetActivity()):AddObjectivePoint("("..tostring(self.Pos.X)..","..tostring(self.Pos.Y)..")", self.Pos, self.Team, GameActivity.ARROWDOWN);
end