function OnModPreInit()
	-- Nothing to do but this function has to exist
end

function OnModInit()
	-- Nothing to do but this function has to exist
end

function OnModPostInit()
	-- Nothing to do but this function has to exist
end

function OnPlayerSpawned( player_entity )
	-- Nothing to do but this function has to exist
end

-- `director_init` is a good target for injecting stuff
-- that needs to stay around all the time
-- (the player entity is a bad choice because it gets
--  destroyed when you polymorph)
ModLuaFileAppend( "data/scripts/director_init.lua", "data/hax/hax.lua" )