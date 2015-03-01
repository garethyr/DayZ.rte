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
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Add an actor and its player to the respawn table
function ModularActivity:AddPlayerToRespawnTable(actor, player)
	table.insert(self.PlayerRespawnTable, {actor = actor, player = player});
end
--Creates players for any Activity Players missing a player
function ModularActivity:CreateNewPlayerActors()
	for i = 0, self.PlayerCount do
		if self:PlayerHuman(i) then
			local actor = self:CreateNewPlayerActor();
			self:AddPlayerToRespawnTable(actor, i);
		end
	end
end
--Actually create a single player
function ModularActivity:CreateNewPlayerActor()
	local actor = CreateAHuman("Survivor Black Reticle Actor" , self.RTE);
	actor:AddInventoryItem(CreateHDFirearm("[DZ] .45 Revolver" , self.RTE));
	actor:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , self.RTE));
	actor:AddInventoryItem(CreateHeldDevice(".45 ACP Speedloader" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Hunting Knife" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Baked Beans" , self.RTE));
	actor:AddInventoryItem(CreateHDFirearm("Coke" , self.RTE));
	actor:AddInventoryItem(CreateTDExplosive("Flare" , self.RTE));
	
	actor.Sharpness = 0;
	actor.Team = self.PlayerTeam;
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor.HUDVisible = false;
	--self:SetPlayerBrain(player, self.PlayerTeam);
	self:AddToPlayerTable(actor);
	return actor;
end
function ModularActivity:SpawnPlayerActors(spawnarea)
	for i, v in ipairs(self.PlayerRespawnTable) do
		self:SpawnPlayerActor(spawnarea, v.actor, v.player, i);
		table.remove(self.PlayerRespawnTable, i);
	end
end
function ModularActivity:SpawnPlayerActor(spawnarea, actor, player, positionmodifier)
	actor.Pos = Vector(spawnarea:GetCenterPoint().X - 25*math.floor(self.PlayerCount*0.5) + 25*positionmodifier, spawnarea:GetCenterPoint().Y);
	actor:SetControllerMode(Controller.CIM_PLAYER, player);
	MovableMan:AddActor(actor);
	self.HumanTable.Players[actor.UniqueID].spawned = true;
end
--------------------
--UPDATE FUNCTIONS--
--------------------
--------------------
--DELETE FUNCTIONS--
--------------------
--------------------
--ACTION FUNCTIONS--
--------------------