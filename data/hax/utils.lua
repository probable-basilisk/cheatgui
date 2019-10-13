rawprint("Loaded hax utils?")

function hello()
  print("hello")
end

function get_player()
  return EntityGetWithTag( "player_unit" )[1]
end

function get_player_pos()
  return EntityGetTransform(get_player())
end

function get_closest_entity(px, py, tag)
  if not py then
    tag = px
    px, py = get_player_pos()
  end
  return EntityGetClosestWithTag( px, py, tag)
end

function get_entity_mouse(tag)
  local mx, my = DEBUG_GetMouseWorld()
  return get_closest_entity(mx, my, tag or "hittable")
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

known_teleport_locations = {
  the_work = {6220, 15175}
}

function teleport_to(location_name)
  local loc = known_teleport_locations[location_name]
  if not loc then
    print("Don't know about that location!")
    return
  end
  teleport(unpack(loc))
end

function spawn_entity(ename, offset_x, offset_y)
  local x, y = get_player_pos()
  x = x + (offset_x or 0)
  y = y + (offset_y or 0)
  return EntityLoad(ename, x, y)
end

possession_target = nil
function possess(e)
  if possession_target then depossess() end
  local cc = EntityGetFirstComponent(e, "ControlsComponent")
  if cc then
    possession_target = e
    enable_ai(e, false)
    ComponentSetValue( cc, "enabled", "1" )
    local player_cc = EntityGetFirstComponent(get_player(), "ControlsComponent")
    ComponentSetValue( player_cc, "enabled", "0" )
  else
    print("Entity not possessable?")
  end
end

function depossess()
  local player_cc = EntityGetFirstComponent(get_player(), "ControlsComponent")
  ComponentSetValue( player_cc, "enabled", "1" )
  if not possession_target then return end
  local cc = EntityGetFirstComponent(possession_target, "ControlsComponent")
  if cc then
    ComponentSetValue( cc, "enabled", "0" )
  end
  enable_ai(e, true)
  possession_target = nil
end

function print_component_info(c)
  local members = ComponentGetMembers(c)
  if not members then return end
  local frags = {}
  for k, v in pairs(members) do
    table.insert(frags, k .. ': ' .. tostring(v))
  end
  print(table.concat(frags, '\n'))
end

function polymorph_player()
  local x, y = get_player_pos()
  local effect = EntityLoad("data/entities/misc/effect_polymorph_random.xml", x, y)
  EntityAddChild( get_player(), effect )
end

function print_detailed_component_info(c)
  local members = ComponentGetMembers(c)
  if not members then return end
  local frags = {}
  for k, v in pairs(members) do
    if (not v) or #v == 0 then
      local mems = ComponentObjectGetMembers(10, k)
      if mems then
        table.insert(frags, k .. ">")
        for k2, v2 in pairs(mems) do
          table.insert(frags, "  " .. k2 .. ": " .. tostring(v2))
        end
      else
        v = "?"
      end
    end
    table.insert(frags, k .. ': ' .. tostring(v))
  end
  print(table.concat(frags, '\n'))

end

function print_entity_info(e)
  local comps = EntityGetAllComponents(e)
  if not comps then
    print("Invalid entity?")
    return
  end
  for idx, comp in ipairs(comps) do
    print(comp, "-----------------")
    print_component_info(comp)
  end
end

function list_funcs()
  local ff = {}
  for k, v in pairs(getfenv()) do
    local first_letter = k:sub(1,1)
    if first_letter:upper() == first_letter then
      table.insert(ff, k)
    end
  end
  table.sort(ff)
  print(table.concat(ff, "\n"))
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

function get_child_info(e)
  local children = EntityGetAllChildren(e)
  for _, child in ipairs(children) do
    print(child, EntityGetName(child) or "[no name]")
  end
end

function show_cheats()
  dofile("data/hax/cheatgui.lua")
  -- local cheats = loadfile("data/hax/cheatgui.lua")
  -- setfenv(cheats, getfenv())
  -- cheats()
end

function do_here(fn)
  local f = loadfile(fn)
  if type(f) ~= "function" then
    print("Loading error; check logger.txt for details.")
  end
  setfenv(f, getfenv())
  f()
end

function fuck_player(entity, is_projectile)
  entity = entity or "data/entities/projectiles/deck/circle_acid.xml"
  async_loop(function()
    local player = get_player()
    local x, y = get_player_pos()
    x = x + (Random()-0.5)*600
    y = y + (Random()-0.5)*600
    if is_projectile then
      shoot_projectile( player, entity, x, y, 0, 0 )
    else
      EntityLoad(entity, x, y)
    end
    wait(60)
  end)
end