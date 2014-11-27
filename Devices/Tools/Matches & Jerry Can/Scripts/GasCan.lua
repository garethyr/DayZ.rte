function Create(self)

	self.lifeTimer = Timer();
	self.emitTimerA = Timer();
	self.emitTimerB = Timer();

	self.smallAngle = 6.28318/12;

	self.angleList = {};

end

function Update(self)

	if MovableMan:IsParticle(self) and self.lifeTimer:IsPastSimMS(1600) then
		self.ToDelete = true;
	else
		--self.ToDelete = false;
		--self.ToSettle = false;

		if self.emitTimerA:IsPastSimMS(40) then
			self.emitTimerA:Reset();

			self.angleList = {};

			for i = 1, 12 do
				local angleCheck = self.smallAngle*i;

				for i = 1, 5 do
					local checkPos = self.Pos + Vector(i,0):RadRotate(angleCheck);
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
					if terrCheck ~= 0 then
						break;
					end
					if i == 5 then
						self.angleList[#self.angleList+1] = angleCheck;
					end
				end
			end

			if #self.angleList > 0 then
				local listNum = #self.angleList;

				local randomAngleA = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;
				local randomAngleB = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;
				local randomAngleC = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;

				local fireA = CreateMOPixel("Fuel Gas");
				fireA.Pos = self.Pos;
				fireA.Vel = Vector((math.random()*5)+10,0):RadRotate(randomAngleA);
				MovableMan:AddParticle(fireA);

				local fireB = CreateMOPixel("Fuel Gas 2");
				fireB.Pos = self.Pos;
				fireB.Vel = Vector((math.random()*5)+5,0):RadRotate(randomAngleB);
				MovableMan:AddParticle(fireB);

				local fireC = CreateMOSParticle("Tiny Smoke Ball 1");
				fireC.Pos = self.Pos;
				fireC.Vel = Vector((math.random()*1)+1,0):RadRotate(randomAngleC);
				MovableMan:AddParticle(fireC);
			else
				local fireA = CreateMOPixel("Fuel Gas 3");
				fireA.Pos = self.Pos;
				fireA.Vel = Vector((math.random()*5)+10,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireA);

				local fireB = CreateMOPixel("Fuel Gas 4");
				fireB.Pos = self.Pos;
				fireB.Vel = Vector((math.random()*5)+5,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireB);

				local fireC = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 1");
				fireC.Pos = self.Pos;
				fireC.Vel = Vector((math.random()*1)+1,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireC);
			end
		end
	end

end
