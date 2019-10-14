if not async then
  -- guard against multiple inclusion to prevent
  -- loss of async coroutines
  dofile( "data/scripts/lib/coroutines.lua" )
end
dofile( "data/scripts/lib/utilities.lua" )
dofile( "data/scripts/perks/perk.lua")
dofile( "data/scripts/gun/gun_actions.lua" )
dofile( "data/hax/materials.lua")
dofile( "data/hax/alchemy.lua")
dofile( "data/hax/gun_builder.lua")

local created_gui = false

if not _cheat_gui then
  print("Creating cheat GUI")
  _cheat_gui = GuiCreate()
  _gui_frame_function = nil
  created_gui = true
else
  print("Reloading onto existing GUI")
end

local gui = _cheat_gui

local hax_btn_id = 123

local closed_panel, perk_panel, cards_panel, menu_panel, flasks_panel, wands_panel, builder_panel, always_cast_panel

closed_panel = function()
  GuiLayoutBeginVertical( gui, 1, 0 )
  if GuiButton( gui, 0, 0, "[+]", hax_btn_id ) then
    print("2")
    _gui_frame_function = menu_panel
  end
  GuiLayoutEnd( gui)
end

local function get_player()
  return EntityGetWithTag( "player_unit" )[1]
end

local function get_player_pos()
  return EntityGetTransform(get_player())
end

local function set_health(hp)
  local damagemodels = EntityGetComponent( get_player(), "DamageModelComponent" )
  if( damagemodels ~= nil ) then
    for i,damagemodel in ipairs(damagemodels) do
      ComponentSetValue( damagemodel, "max_hp", hp)
      ComponentSetValue( damagemodel, "hp", hp)
    end
  end
end

local function spawn_potion(material)
  local x, y = get_player_pos()
  local entity = EntityLoad("data/hax/potion_empty.xml", x, y)
  AddMaterialInventoryMaterial( entity, material, 1000 )
end

local function spawn_item(path)
  local x, y = get_player_pos()
  local entity = EntityLoad(path, x, y)
end

local function wrap_spawn(path)
  return function() spawn_item(path) end
end

local function maybe_call(s_or_f, opt)
  if type(s_or_f) == 'function' then 
    return s_or_f(opt)
  else
    return s_or_f
  end
end

local function grid_layout(options, col_width)
  local num_options = #options
  local col_size = 28
  local ncols = math.ceil(num_options / col_size)
  local xoffset = col_width or 25
  local xpos = 5
  local opt_pos = 1
  for col = 1, ncols do
    if not options[opt_pos] then break end
    GuiLayoutBeginVertical( gui, xpos, 11 )
    for row = 1, col_size do
      if not options[opt_pos] then break end
      local opt = options[opt_pos]
      local text = opt.text or opt[1]
      text = maybe_call(text, opt)
      if GuiButton( gui, 0, 0, text, hax_btn_id+opt_pos+40 ) then
        (opt.f or opt[2])(opt)
      end
      opt_pos = opt_pos + 1
    end
    GuiLayoutEnd( gui)
    xpos = xpos + xoffset
  end
end

local function grid_panel(title, options, col_width)
  GuiLayoutBeginVertical( gui, 1, 0 )
  GuiText( gui, 0,0, title)
  if GuiButton( gui, 0, 0, "Close", hax_btn_id+10 ) then
    _gui_frame_function = closed_panel
  end
  GuiLayoutEnd( gui)
  grid_layout(options, col_width)
end

local function wrap_paginate(title, options, page_size)
  page_size = page_size or (28*4 - 2)
  local cur_page = 1
  local pages = {}
  local npages = math.ceil(#options / page_size)
  local opt_pos = 1
  for page = 1, npages do
    if not options[opt_pos] then break end
    pages[page] = {}
    if page > 1 then
      table.insert(pages[page], {"<- Prev", function()
        cur_page = page - 1
      end})
    end
    for idx = 1, page_size do
      if not options[opt_pos] then break end
      table.insert(pages[page], options[opt_pos])
      opt_pos = opt_pos + 1
    end
    if page < npages then
      table.insert(pages[page], {"More ->", function()
        cur_page = page + 1
      end})
    end
  end
  return function()
    grid_panel(title, pages[cur_page])
  end
end

local function create_radio(title, options, default, x_spacing)
  if not default then default = options[1][2] end
  local selected = default --1
  -- for i, v in ipairs(options) do
  --   if v[2] == default then selected = i end
  -- end
  local wrapper = {
    index = selected, 
    value = options[selected][2]
  }
  return function(button_id, xpos, ypos)
    button_id = (button_id or 200) + 1  
    GuiText(gui, xpos*4, (ypos) * 3.5 + 1, title)
    GuiLayoutBeginHorizontal(gui, xpos+(x_spacing or 12), ypos)
    for idx, option in ipairs(options) do
      local text = option[1]
      if idx == wrapper.index then text = "[" .. text .. "]" end
      if GuiButton( gui, 0, 0, text, button_id ) then
        wrapper.index = idx
        wrapper.value = option[2]
      end
      button_id = button_id + 1
    end
    GuiLayoutEnd(gui)
    return button_id
  end, wrapper
end

local function create_numerical(title, increments, default)
  local wrapper = {
    value = default or 0.0
  }
  return function(button_id, xpos, ypos)
    button_id = (button_id or 200) + 1
    GuiText(gui, xpos*4, (ypos) * 3.5 + 1, title)
    GuiLayoutBeginHorizontal(gui, xpos + 12, ypos)
    --GuiText(gui, 0, 0, title)
    for idx = #increments, 1, -1 do
      local s = "[" .. string.rep("-", idx) .. "]"
      if GuiButton( gui, 0, 0, s, button_id ) then
        wrapper.value = wrapper.value - increments[idx]
      end
      button_id = button_id + 1
    end
    GuiText(gui, 0, 0, "" .. wrapper.value)
    for idx = 1, #increments do
      local s = "[" .. string.rep("+", idx) .. "]"
      if GuiButton( gui, 0, 0, s, button_id ) then
        wrapper.value = wrapper.value + increments[idx]
      end
      button_id = button_id + 1
    end
    GuiLayoutEnd(gui)
    return button_id
  end, wrapper
end

local localization_widget, localization_val = create_radio("Show localized names:", {
  {"Yes", true}, {"No", false}
}, 2, 1)


local shuffle_widget, shuffle_val = create_radio("Shuffle", {
  {"Yes", true}, {"No", false}
}, 2)

local mana_widget, mana_val = create_numerical("Mana", {50, 500}, 300)
local mana_rec_widget, mana_rec_val = create_numerical("Mana Recharge", {10, 100}, 100)
local slots_widget, slots_val = create_numerical("Slots", {1, 5}, 5)
local multi_widget, multi_val = create_numerical("Multicast", {1}, 1)
local reload_widget, reload_val = create_numerical("Reload", {0.01, 0.1}, 0.5)
local delay_widget, delay_val = create_numerical("Delay", {0.01, 0.1}, 0.5)
local spread_widget, spread_val = create_numerical("Spread", {0.1, 1}, 0.0)
local speed_widget, speed_val = create_numerical("Speed", {0.01, 0.1}, 1.0)

local always_cast_choice = nil

builder_panel = function()
  local button_id = hax_btn_id + 1
  --GuiLayoutBeginVertical(gui, 2, 11)
  button_id = shuffle_widget(button_id, 1, 12)
  button_id = mana_widget(button_id, 1, 16)
  button_id = mana_rec_widget(button_id, 1, 20)
  button_id = slots_widget(button_id, 1, 24)
  button_id = multi_widget(button_id, 1, 28)
  button_id = reload_widget(button_id, 1, 32)
  button_id = delay_widget(button_id, 1, 36)
  button_id = spread_widget(button_id, 1, 40)
  button_id = speed_widget(button_id, 1, 44)
  --GuiLayoutEnd(gui)

  GuiLayoutBeginVertical( gui, 1, 0 )
  GuiText( gui, 0,0, "Wand builder")
  if GuiButton( gui, 0, 0, "Close", hax_btn_id ) then
    _gui_frame_function = closed_panel
  end
  GuiLayoutEnd( gui)

  if GuiButton( gui, 1*4, 48*3.5, "Always cast: " .. (always_cast_choice or "None"), button_id+1) then
    _gui_frame_function = always_cast_panel
    return
  end
  if GuiButton( gui, 1*4, 48*4, "[Spawn]", button_id+3) then
    local x, y = get_player_pos()
    local gun = {
      deck_capacity = slots_val.value,
      actions_per_round = multi_val.value,
      reload_time = math.ceil(reload_val.value * 60),
      shuffle_deck_when_empty = (shuffle_val.value and 1) or 0,
      fire_rate_wait = math.ceil(delay_val.value * 60),
      spread_degrees = spread_val.value,
      speed_multiplier = speed_val.value,
      mana_max = mana_val.value,
      mana_charge_speed = mana_rec_val.value,
      always_cast = always_cast_choice
    }
    build_gun(x, y, gun)
  end
end

-- build these button lists once so we aren't rebuilding them every frame
local function resolve_localized_name(s, default)
  if s:sub(1,1) ~= "$" then return s end
  local rep = GameTextGet(s)
  if rep and rep ~= "" then return rep else return default or s end
end

local function localized_name(thing)
  if localization_val.value then return thing.ui_name else return thing.id end
end

local function spawn_spell_button(card)
  local x, y = get_player_pos()
  GamePrint( "Attempting to spawn " .. card.id)
  CreateItemActionEntity( card.id, x, y )
end

local function set_always_cast(card)
  always_cast_choice = card.id
  _gui_frame_function = builder_panel
end

local spell_options = {}
local always_cast_options = {
  {
    text = "None", 
    f = function()
      always_cast_choice = nil
      _gui_frame_function = builder_panel
    end
  }
}

for idx, card in ipairs(actions) do
  local ui_name = resolve_localized_name(card.name)
  local id = card.id:lower()
  if (not ui_name) or (ui_name == "") then ui_name = id end
  spell_options[idx] = {
    text = localized_name,
    id = id, ui_name = ui_name,
    f = spawn_spell_button
  }
  always_cast_options[idx+1] = {
    text = localized_name,
    id = id, ui_name = ui_name,
    f = set_always_cast
  }
end

local function spawn_perk_button(perk)
  local x, y = get_player_pos()
  GamePrint( "Attempting to spawn " .. perk.id)
  perk_spawn( x, y - 8, perk.id )
end

local perk_options = {}
for idx, perk in ipairs(perk_list) do
  perk_options[idx] = {
    text = localized_name, 
    id = perk.id,
    ui_name = perk.ui_name, 
    f = spawn_perk_button
  }
end

local function spawn_potion_button(potion)
  GamePrint( "Attempting to spawn potion of " .. potion.id)
  spawn_potion(potion.id)
end

local potion_options = {}
for idx, matinfo in ipairs(materials_list) do
  local material, translated_material = unpack(matinfo)
  if material:sub(1,1) ~= "-" then
    potion_options[idx] = {
      text = localized_name, 
      ui_name = translated_material, id = material,
      f = spawn_potion_button
    }
  else
    potion_options[idx] = {text = material, f = function() end}
  end
end

local wand_options = {}
for i = 1, 5 do
  wand_options[i] = {
    "Wand Level " .. i, 
    wrap_spawn("data/entities/items/wand_level_0" .. i .. ".xml")
  }
end
table.insert(wand_options, {"Haxx", wrap_spawn("data/hax/wand_hax.xml")})

local tourist_mode_on = false
local function toggle_tourist_mode()
  tourist_mode_on = not tourist_mode_on
  local herd = (tourist_mode_on and "healer_orc") or "player"
  GenomeSetHerdId( get_player(), herd )
  GamePrint("Tourist mode: " .. tostring(tourist_mode_on))
end

local xray_added = false
local function add_permanent_xray()
  if xray_added then return end
  local px, py = get_player_pos()
  local cid = EntityLoad( "data/entities/misc/effect_remove_fog_of_war.xml", px, py )
  EntityAddChild( get_player(), cid )
  -- EntityAddComponent(get_player(), "MagicXRayComponent", {
  --   radius = 2048,
  --   steps_per_frame = 8
  -- })
  GamePrint("Permanent XRay Added?")
  xray_added = true
end

local seedval = "?"
SetRandomSeed(0, 0)
seedval = tostring(Random() * 2^31)

local LC, AP = get_alchemy()
LC = table.concat(LC, ", ")
AP = table.concat(AP, ", ")

local extra_buttons = {}
function register_cheat_button(title, f)
  table.insert(extra_buttons, {title, f})
end

local function draw_extra_buttons(startid)
  for _, button in ipairs(extra_buttons) do
    local title, f = button[1], button[2]
    if type(title) == 'function' then title = title() end
    if f then
      if GuiButton( gui, 0, 0, title, startid) then
        f()
      end
      startid = startid + 1
    else
      GuiText( gui, 0, 0, title)
    end
  end
  return startid
end

menu_panel = function()
  GuiLayoutBeginVertical( gui, 1, 11 )
  if GuiButton( gui, 0, 0, "Perks", hax_btn_id ) then
    _gui_frame_function = perk_panel
  end
  if GuiButton( gui, 0, 0, "Cards", hax_btn_id+1) then
    _gui_frame_function = cards_panel
  end
  if GuiButton( gui, 0, 0, "Flasks", hax_btn_id+5) then
    _gui_frame_function = flasks_panel
  end
  if GuiButton( gui, 0, 0, "Wands", hax_btn_id+6) then
    _gui_frame_function = wands_panel
  end
  if GuiButton( gui, 0, 0, "Wand builder", hax_btn_id+8) then
    _gui_frame_function = builder_panel
  end
  draw_extra_buttons(9)
  if GuiButton( gui, 0, 0, "Close", hax_btn_id+2) then
    _gui_frame_function = closed_panel
  end
  GuiLayoutEnd( gui)
end

register_cheat_button("Spell Refresh", function()
  GameRegenItemActionsInPlayer( get_player() )
end)

register_cheat_button("Much Health", function() set_health(40) end)

register_cheat_button(function()
  return ((tourist_mode_on and "Disable") or "Enable") .. " tourist mode"
end, toggle_tourist_mode)

register_cheat_button("LC: " .. LC)
register_cheat_button("AP: " .. AP)

register_cheat_button("Spawn Orbs", function()
  local x, y = get_player_pos()
  for i = 0, 13 do
    EntityLoad(("data/entities/items/orbs/orb_%02d.xml"):format(i), x+(i*15), y - (i*5))
  end
end)

local function wrap_localized(f)
  return function()
    localization_widget(hax_btn_id+1, 50, 7)
    f()
  end
end

always_cast_panel = wrap_localized(wrap_paginate("Select a spell: ", always_cast_options))
cards_panel = wrap_localized(wrap_paginate("Select a spell to spawn:", spell_options))
perk_panel = wrap_localized(wrap_paginate("Select a perk to spawn:", perk_options))
flasks_panel = wrap_localized(wrap_paginate("Select a flask to spawn:", potion_options))

wands_panel = function()
  grid_panel("Select a wand to spawn:", wand_options)
end

_gui_frame_function = menu_panel

if created_gui then
  print("Starting GUI loop")
  async_loop(function()
    if gui ~= nil then
      GuiStartFrame( gui )
    end

    if _gui_frame_function ~= nil then
      local happy, errstr = pcall(_gui_frame_function)
      if not happy then
        print("Gui error: " .. errstr)
        _gui_frame_function = nil
      end
    end

    wait(0)
  end)
end