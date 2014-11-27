--Change the item's sharpness, for Chernarus, when thrown
function Create(self)
	self.Sharpness = 0;
end
function Update(self)
	if self.Sharpness == 0 and not self:IsAttached() and self:IsActivated() and self:GetAltitude(300, 5) <= 10 then
		self.Sharpness = 1;
	end
end