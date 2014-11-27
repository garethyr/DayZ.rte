function Create(self)
	if not DayZHumanWoundTable then
		DayZHumanWoundTable = {}
	end
	self.Parent = nil;
	self.DelayTimer = Timer();
	local dist = 500;
	for actor in MovableMan.Actors do
		if SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude < dist then
			dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude;
			self.Parent = actor;
		end
	end
	DayZHumanWoundTable[#DayZHumanWoundTable+1] = {self, self.Parent};
	self.WoundNumber = #DayZHumanWoundTable;
	--print ("WOUND MADE, Parent: "..tostring(self.Parent)..". Table Num:"..tostring(#DayZHumanWoundTable));
end
function Destroy(self)
	if DayZHumanWoundTable ~= nil then
		if #DayZHumanWoundTable == 0 or ToGameActivity(ActivityMan:GetActivity()):ActivityOver() == true then
			DayZHumanWoundTable = nil;
		else
			table.remove(DayZHumanWoundTable, self.WoundNumber);
		end
	end
end