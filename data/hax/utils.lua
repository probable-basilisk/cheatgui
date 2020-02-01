rawprint("Loaded hax utils?")

function get_player()
  return EntityGetWithTag( "player_unit" )[1]
end

function get_player_pos()
  return EntityGetTransform(get_player())
end

function enable_ai(e, enabled)
  local ai = EntityGetFirstComponent(e, "AnimalAIComponent")
  if not ai then print("no ai??") end
  --ComponentSetValue( ai, "_enabled", (enabled and "1") or "0" )
  --ComponentSetValue( ai, "enabled", (enabled and "1") or "0" )
  EntitySetComponentIsEnabled(e, ai, enabled)
end

function teleport(x, y)
  EntitySetTransform(get_player(), x, y)
end

function spawn_entity(ename, offset_x, offset_y)
  local x, y = get_player_pos()
  x = x + (offset_x or 0)
  y = y + (offset_y or 0)
  return EntityLoad(ename, x, y)
end

function spawn_potion(material)
  local x, y = get_player_pos()
  local entity = EntityLoad("data/hax/potion_empty.xml", x, y)
  AddMaterialInventoryMaterial( entity, material, 1000 )
end

function engage_tourist_mode()
  GenomeSetHerdId( get_player(), "healer_orc" )
  GamePrintImportant("Tourist Mode", "")
end