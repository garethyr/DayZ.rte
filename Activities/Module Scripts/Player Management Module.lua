-----------------------------------------------------------------------------------------
-- Description
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartPlayerManagement()
	---------------------
	--PLAYERS CONSTANTS--
	---------------------
	self.PlayerRespawnTimers = {}; --The timers for respawning each player
	for i = 0, self.PlayerCount do
		if self:PlayerHuman(i) then
			self.PlayerRespawnTimers[i+1] = Timer();
		end
	end
	self.PlayerRespawnInterval = 5000; --The interval after which a dead player should respawn

	-------------------------
	--STATIC PLAYERS TABLES--
	-------------------------

	--------------------------
	--DYNAMIC PLAYERS TABLES--
	--------------------------
	--The table of players waiting to respawn, as well as the actor they'll control
	self.PlayerRespawnTable = {}; --Values - player = the activity player, actor = the actor that will be added to the scene
	
	---------------------
	--PLAYERS VARIABLES--
	---------------------
	self.PlayerRespawnTimer = Timer();
	self.PlayerRespawnInterval = 5000;
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an actor and its player to the respawn table
function ModularActivity:AddPlayerToRespawnTable(actor, player, ...) --Optional argument is always empty or a single table
	table.insert(self.PlayerRespawnTable, {actor = actor, player = player});
	if select("#", ...) > 0 then
		self.PlayerRespawnTable[#self.PlayerRespawnTable].args = select(1, ...);
	end
end
--Creates players for any Activity Players missing a player
function ModularActivity:CreateNewPlayerActors()
	for i = 0, self.PlayerCount do
		if self:PlayerHuman(i) then
			local actor = self:CreateNewPlayerActor(i);
			self:AddPlayerToRespawnTable(actor, i);
		end
	end
end
--Actually create a single player
function ModularActivity:CreateNewPlayerActor(player)
	local actor = CreateAHuman("Survivor Black Reticle Actor" , self.RTE);
	actor:AddInventoryItem(CreateHDFirearm("Medical Box" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("[DZ] .45 Revolver" , self.RTE));
	actor:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , self.RTE));
	actor:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Hunting Knife" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Baked Beans" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Coke" , self.RTE));
	actor:AddInventoryItem(CreateTDExplosive("Flare" , self.RTE));
	if self.IncludeFlashlight then
		self:AddFlashlightForActor(actor);
	end
	
	actor.Sharpness = 0;
	actor.Team = self.PlayerTeam;
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor.HUDVisible = false;
	--self:SetPlayerBrain(player, self.PlayerTeam);
	return actor;
end
function ModularActivity:SpawnPlayerActors(spawnareanum)
	for i, v in ipairs(self.PlayerRespawnTable) do
		self:SpawnPlayerActor(spawnareanum, v.actor, v.player, v.args, i); --Note: the last argument here is a position modifier, it is not necessarily equal to the table index in all cases
		table.remove(self.PlayerRespawnTable, i);
	end
end
function ModularActivity:SpawnPlayerActor(spawnareanum, actor, player, args, positionmodifier) --Setting spawnarea as -1 defaults to DefaultPlayerSpawnArea, and for safety, a nil value defaults to spawn area 1
	if spawnareanum == -1 then
		spawnareanum = self.DefaultPlayerSpawnAreaNumber;
	end
	if spawnareanum == nil then
		spawnareanum = 1;
	end
	local spawnarea = self.PlayerSpawnAreas[spawnareanum];
	actor.Pos = Vector(spawnarea:GetCenterPoint().X - 25*math.floor(self.PlayerCount*0.5) + 25*positionmodifier, spawnarea:GetCenterPoint().Y);
	actor:SetControllerMode(Controller.CIM_PLAYER, player); --TODO one of these may not be necessary, probably this one?
	self:SwitchToActor(actor, player, actor.Team);
	MovableMan:AddActor(actor);
	self:AddToPlayerTable(actor, player);
	--Do optional spawning additions for a not-clean respawn - sustenance, alerts, etc.
	if args ~= nil then
		--Handle sustenance
		if args.sust ~= nil then
			self:NotifySust_SetActorSust(actor.UniqueID, args.sust);
		end
		--Handle activity
		if args.activity ~= nil then
			self.HumanTable.Players[actor.UniqueID].activity = args.activity;
		end
		--Handle alerts
		if args.alert ~= nil and args.alert ~= false and self.IncludeAlerts then
			self.HumanTable.Players[actor.UniqueID].alert = args.alert;
			local oldtarget = args.alert.target; --Save the old target for future use
			args.alert.target = actor;
			--Make any zombies spawned by the alert that are targeting the old actor target the new one
			if self.IncludeSpawns and self:AlertHasZombies(args.alert) then
				for _, zombieactor in pairs(args.alert.zombie.actors) do
					local zombietable = self.ZombieTable[zombieactor.UniqueID];
					if zombietable.ttype == "human" and zombietable.target == oldtarget then
						self:SetZombieTarget(zombieactor, actor, zombietable.ttype, zombietable.spawner)
					end
				end
			end
		end
	end
end
--------------------
--UPDATE FUNCTIONS--
--------------------
function ModularActivity:DoPlayerManagement()
	if #self.PlayerRespawnTable > 0 then
		if self.PlayerRespawnTimer:IsPastSimMS(self.PlayerRespawnInterval) then
			self:SpawnPlayerActors(-1);
		else
			for _, respawn in pairs(self.PlayerRespawnTable) do
				self:AddScreenText("Respawning In: "..tostring(math.floor((self.PlayerRespawnInterval - self.PlayerRespawnTimer.ElapsedSimTimeMS)/1000)));
				if self.IncludeDayNight then
					local boxsize = 250;
					local corner = Vector(SceneMan:GetScrollTarget(respawn.player).X - boxsize/2, SceneMan:GetScrollTarget(respawn.player).Y - boxsize/2);
					local box = Box(corner, Vector(corner.X + boxsize, corner.Y + boxsize));
					table.insert(self.DayNightExtraRevealBoxes, box);
				end
			end
		end
	else
		self.PlayerRespawnTimer:Reset();
	end
end
--------------------
--DELETE FUNCTIONS--
--------------------
--------------------
--ACTION FUNCTIONS--
--------------------