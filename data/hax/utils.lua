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

function empty_container_of_materials(idx)
  for _ = 1, 1000 do -- avoid infinite loop
    local material = GetMaterialInventoryMainMaterial(idx)
    if material <= 0 then break end
    local matname = CellFactory_GetName(material)
    AddMaterialInventoryMaterial(idx, matname, 0)
  end
end

function spawn_potion(material, kind)
  local x, y = get_player_pos()
  local entity
  if kind == nil or kind == "potion" then 
    entity = EntityLoad("data/entities/items/pickup/potion_empty.xml", x, y)
  elseif kind == "pouch" then
    entity = EntityLoad("data/entities/items/pickup/powder_stash.xml", x, y)
    empty_container_of_materials(entity)
  end
  AddMaterialInventoryMaterial( entity, material, 1000 )
end

function engage_tourist_mode()
  GenomeSetHerdId( get_player(), "healer_orc" )
  GamePrintImportant("Tourist Mode", "")
end

function hello()
  GamePrintImportant("Hello", "Hello")
  GamePrint("Hello")
  print("Hello")
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

function print_component_info(c)
  local frags = {"<" .. ComponentGetTypeName(c) .. ">"}
  local members = ComponentGetMembers(c)
  if not members then return end
  for k, v in pairs(members) do
    table.insert(frags, k .. ': ' .. tostring(v))
  end
  print(table.concat(frags, '\n'))
end

function get_vector_value(comp, member, kind)
  kind = kind or "float"
  local n = ComponentGetVectorSize( comp, member, kind )
  if not n then return nil end
  local ret = {};
  for i = 1, n do
    ret[i] = ComponentGetVectorValue(comp, member, kind, i-1) or "nil"
  end
  return ret
end

function print_vector_value(...)
  local v = get_vector_value(...)
  if not v then return nil end
  return "{" .. table.concat(v, ", ") .. "}"
end

function print_detailed_component_info(c)
  local members = ComponentGetMembers(c)
  if not members then return end
  local frags = {}
  for k, v in pairs(members) do
    if (not v) or #v == 0 then
      local mems = ComponentObjectGetMembers(c, k)
      if mems then
        table.insert(frags, k .. ">")
        for k2, v2 in pairs(mems) do
          table.insert(frags, "  " .. k2 .. ": " .. tostring(v2))
        end
      else
        v = print_vector_value(c, k)
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

function list_components(e)
  local comps = EntityGetAllComponents(e)
  if not comps then
    print("Invalid entity?")
    return
  end
  for idx, comp in ipairs(comps) do
    print(comp .. " : " .. ComponentGetTypeName(comp))
  end
end

function list_funcs(filter)
  local ff = {}
  for k, v in pairs(getfenv()) do
    local first_letter = k:sub(1,1)
    if first_letter:upper() == first_letter then
      if (not filter) or k:lower():find(filter:lower()) then
        table.insert(ff, k)
      end
    end
  end
  table.sort(ff)
  print(table.concat(ff, "\n"))
end

function get_child_info(e)
  local children = EntityGetAllChildren(e)
  for _, child in ipairs(children) do
    print(child, EntityGetName(child) or "[no name]")
  end
end

function do_here(fn)
  local f = loadfile(fn)
  if type(f) ~= "function" then
    print("Loading error; check logger.txt for details.")
  end
  setfenv(f, getfenv())
  f()
end