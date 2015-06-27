function Create(self)
	if not DayZHumanWoundTable then
		DayZHumanWoundTable = {}
	end
	self.Parent = nil;
	self.DelayTimer = Timer();
	local dist = 100;
	for actor in MovableMan.Actors do
		if SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude < dist then
			dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude;
			self.Parent = actor;
		end
	end
	if DayZHumanWoundTable[self.Parent.UniqueID] == nil then
		DayZHumanWoundTable[self.Parent.UniqueID] = {actor = self.Parent, wounds = {}};
	end
	DayZHumanWoundTable[self.Parent.UniqueID].wounds[self.UniqueID] = self;
	--print ("Added wound to "..tostring(self.Parent).." last wound is "..tostring(self));
end
function Destroy(self)
	if DayZHumanWoundTable ~= nil then
		if next(DayZHumanWoundTable) == nil or ToGameActivity(ActivityMan:GetActivity()):ActivityOver() then
			DayZHumanWoundTable = nil;
		else
			DayZHumanWoundTable[self.Parent.UniqueID].wounds[self.UniqueID] = nil;
			if next(DayZHumanWoundTable[self.Parent.UniqueID].wounds) == nil then
				DayZHumanWoundTable[self.Parent.UniqueID] = nil;
			end
		end
	end
end