--Yay Findude!
function Update(self)
self.ToSettle = true;
end
--Yay Grif, and Duh102!
function Destroy(self)
self.box1 = Box(Vector(self.Pos.X - 40, self.Pos.Y), Vector(self.Pos.X + 40, self.Pos.Y + 80));
  for actor in MovableMan.Actors do
	if self.box1:WithinBox(actor.Pos) == true then
	  actor:EraseFromTerrain();
      actor.Health = -1;
	  actor.ToSettle = true;
   end
  end
end