
dofile("Base.rte/Constants.lua")
dofile("DayZ.rte/Actors/Zombies/AI/MeleeNativeHumanAI.lua")		--Change this to point to the right location

function Create(self)
	self.AI = MeleeNativeHumanAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end
