-----------------------------------------------------------------------------------------
-- Description
-----------------------------------------------------------------------------------------
--Setup
function ModularActivity:StartSaveLoad()
	
	-----------------------
	--SAVE LOAD CONSTANTS--
	-----------------------

	---------------------------
	--STATIC SAVE LOAD TABLES--
	---------------------------

	----------------------------
	--DYNAMIC SAVE LOAD TABLES--
	----------------------------
	
	-----------------------
	--SAVE LOAD VARIABLES--
	-----------------------
end
----------------------
--CREATION FUNCTIONS--
----------------------
--Start a new game in the starting scene
function ModularActivity:StartNewGame()
	self:DoSceneTransition("Chernarus Tunnels 1", 1);
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