function get_player()
  return EntityGetWithTag("player_unit")[1]
end

function get_player_pos()
  local player = get_player()
  if not player then return 0, 0 end
  return EntityGetTransform(player)
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

function get_health()
  local dm = EntityGetComponent(get_player(), "DamageModelComponent")[1]
  return ComponentGetValue(dm, "hp"), ComponentGetValue(dm, "max_hp")
end

function set_health(cur_hp, max_hp)
  local damagemodels = EntityGetComponent(get_player(), "DamageModelComponent")
  for _, damagemodel in ipairs(damagemodels or {}) do
    ComponentSetValue(damagemodel, "max_hp", max_hp)
    ComponentSetValue(damagemodel, "hp", cur_hp)
  end
end

function quick_heal()
  local _, max_hp = get_health()
  set_health(max_hp, max_hp)
end

function set_money(amt)
  local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
  ComponentSetValue2(wallet, "money", amt)
end

function get_money()
  local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
  return ComponentGetValue2(wallet, "money")
end

function twiddle_money(delta)
  local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
  local current = ComponentGetValue2(wallet, "money")
  ComponentSetValue2(wallet, "money", math.max(0, current+delta))
end

function spawn_entity(ename, offset_x, offset_y)
  local x, y = get_player_pos()
  x = x + (offset_x or 0)
  y = y + (offset_y or 0)
  return EntityLoad(ename, x, y)
end
spawn_item = spawn_entity

function empty_container_of_materials(idx)
  for _ = 1, 1000 do -- avoid infinite loop
    local material = GetMaterialInventoryMainMaterial(idx)
    if material <= 0 then break end
    local matname = CellFactory_GetName(material)
    AddMaterialInventoryMaterial(idx, matname, 0)
  end
end

function spawn_potion(material, quantity, kind)
  local x, y = get_player_pos()
  quantity = quantity or 1000
  local entity
  if kind == nil or kind == "potion" then 
    entity = EntityLoad("data/entities/items/pickup/potion_empty.xml", x, y)
  else -- kind == "pouch"
    entity = EntityLoad("data/entities/items/pickup/powder_stash.xml", x, y)
    empty_container_of_materials(entity)
    quantity = quantity * 1.5
  end
  AddMaterialInventoryMaterial(entity, material, quantity)
end

function spawn_perk(perk_id, auto_pickup_entity)
  local x, y = get_player_pos()
  local perk_entity = perk_spawn(x, y - 8, perk_id)
  if auto_pickup_entity then
    perk_pickup(perk_entity, auto_pickup_entity, nil, true, false)
  end
end

function set_tourist_mode(enabled)
  local herd = (enabled and "healer") or "player"
  GenomeSetHerdId(get_player(), herd)
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

function round(v)
  local upper = math.ceil(v)
  local lower = math.floor(v)
  if math.abs(v - upper) < math.abs(v - lower) then
    return upper
  else
    return lower
  end
end

function resolve_localized_name(s, default)
  if s:sub(1,1) ~= "$" then return s end
  local rep = GameTextGet(s)
  if rep and rep ~= "" then return rep else return default or s end
end

function localize_material(mat)
  local n = GameTextGet("$mat_" .. mat)
  if n and n ~= "" then return n else return "[" .. mat .. "]" end
end