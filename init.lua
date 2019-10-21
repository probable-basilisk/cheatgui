function OnModPreInit()
	-- Nothing to do but this function has to exist
end

function OnModInit()
	-- Nothing to do but this function has to exist
end

function OnModPostInit()
	-- Nothing to do but this function has to exist
end

function OnWorldPreUpdate()
	-- Nothing to do but this function has to exist
end

function OnWorldPostUpdate() 
	-- Nothing to do but this function has to exist
end

function OnPlayerSpawned( player_entity )
	-- -- check if cheatgui has somehow already been serialized?
	-- local gui = EntityGetWithTag( "cheatgui_container" )
	-- if (not gui)
  EntityLoad("data/hax/guicontainer.xml")
end
