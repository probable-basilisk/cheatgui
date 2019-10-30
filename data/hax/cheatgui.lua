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
dofile( "data/hax/superhackykb.lua")

local created_gui = false

local _type_target = nil
local _shift_target = nil

local function handle_typing()
  local type_target = _type_target
  local req_shift = false
  if type_target == nil then 
    type_target = _shift_target
    req_shift = true
  end
  if not type_target then return end
  local prev_val = type_target.value
  local hit_enter = false
  type_target.value, hit_enter = hack_type(prev_val, not req_shift)
  if (prev_val ~= type_target.value) and (type_target.on_change) then
    type_target:on_change()
  end
  if hit_enter and (type_target.on_hit_enter) then
    type_target:on_hit_enter()
  end
end

local function set_type_target(target)
  if _type_target and _type_target.on_lose_focus then
    _type_target:on_lose_focus()
  end
  _type_target = target
  if _type_target and _type_target.on_gain_focus then
    _type_target:on_gain_focus()
  end
end

local function set_type_default(target)
  _shift_target = target
end

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

local closed_panel, perk_panel, cards_panel, menu_panel, flasks_panel, wands_panel, builder_panel, always_cast_panel, teleport_panel

local function Panel(options)
  if not options.name then
    options.name = options[1]
  end
  if not options.func then
    options.func = options[2]
  end
  return options
end

local panel_stack = {}
local _active_panel = nil

local function _change_active_panel(panel)
  if panel == _active_panel then return end
  set_type_default(nil)
  set_type_target(nil)
  _gui_frame_function = panel.func
end

local function prev_panel()
  if #panel_stack < 2 then
    _change_active_panel(closed_panel)
    panel_stack = {}
  else
    -- pop off last panel
    panel_stack[#panel_stack] = nil
    _change_active_panel(panel_stack[#panel_stack])
  end
end

local function jump_back_panel(idx)
  if #panel_stack <= idx then return end
  for i = idx+1, #panel_stack do
    panel_stack[i] = nil
  end
  _change_active_panel(panel_stack[#panel_stack])
end

local function enter_panel(panel)
  panel_stack[#panel_stack+1] = panel
  _change_active_panel(panel)
end

local function hide_gui()
  _change_active_panel(closed_panel)
end

local function show_gui()
  if #panel_stack == 0 then
    enter_panel(menu_panel)
  else
    _change_active_panel(panel_stack[#panel_stack])
  end
end

local function breadcrumbs(x, y)
  GuiLayoutBeginHorizontal(gui, x, y)
  if GuiButton( gui, 0, 0, "[-]", hax_btn_id+1) then
    hide_gui()
  end
  for idx, panel in ipairs(panel_stack) do
    if GuiButton( gui, 0, 0, panel.name .. ">", hax_btn_id+1+idx) then
      jump_back_panel(idx)
    end
  end
  GuiLayoutEnd(gui)
  GuiLayoutBeginHorizontal( gui, x, y+3)
  if #panel_stack > 1 and GuiButton( gui, 0, 0, "< back", hax_btn_id+30) then
    prev_panel()
  end
  GuiLayoutEnd( gui )
end

closed_panel = Panel{"[+]", function()
  GuiLayoutBeginVertical( gui, 1, 0 )
  if GuiButton( gui, 0, 0, "[+]", hax_btn_id ) then
    show_gui()
  end
  GuiLayoutEnd( gui)
end}

local function get_player()
  return EntityGetWithTag( "player_unit" )[1]
end

local function get_player_pos()
  return EntityGetTransform(get_player())
end

local function teleport(x, y)
  EntitySetTransform(get_player(), x, y)
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
  breadcrumbs(1, 0)
  grid_layout(options, col_width)
end

local function filter_options(options, str)
  local ret = {}
  for _, opt in ipairs(options) do
    local text = maybe_call(opt.text, opt):lower()
    if text:find(str) then
      table.insert(ret, opt)
    end
  end
  return ret
end

local GUTTER_Y = 345
local CENTER_X = 1280/4

local function wrap_paginate(title, options, page_size)
  page_size = page_size or 28*4
  local cur_page = 1
  local pages = {}
  local npages = math.ceil(#options / page_size)
  local opt_pos = 1
  for page = 1, npages do
    if not options[opt_pos] then break end
    pages[page] = {}
    for idx = 1, page_size do
      if not options[opt_pos] then break end
      table.insert(pages[page], options[opt_pos])
      opt_pos = opt_pos + 1
    end
  end
  local filtered_set = options
  local filter_thing = {
    value = "", on_change = function(_self)
      filtered_set = filter_options(options, _self.value)
    end
  }
  return function(force_refilter)
    set_type_default(filter_thing)
    local filter_str = filter_thing.value
    local filter_text = "[shift+type to filter]"
    if filter_str and (filter_str ~= "") then
      filter_text = filter_str
    end

    GuiLayoutBeginVertical( gui, 31, 0)
    GuiText(gui, 0, 0, "Filter:")
    GuiLayoutEnd( gui )
    GuiLayoutBeginVertical( gui, 31 + 16, 0 )
    if GuiButton( gui, 0, 0, filter_text, hax_btn_id+11 ) then
      filter_thing.value = ""
    end
    GuiLayoutEnd( gui)

    if (not filter_str) or (filter_str == "") then
      grid_panel(title, pages[cur_page])
      if cur_page > 1 then
        if GuiButton( gui, CENTER_X - 13, GUTTER_Y, "<-", hax_btn_id+12 ) then
          cur_page = cur_page - 1
        end
      end
      if npages > 1 then
        GuiText( gui, 1280/4, GUTTER_Y, ("%d/%d"):format(cur_page, npages))
      end
      if cur_page < npages then
        if GuiButton( gui, CENTER_X + 20, GUTTER_Y, "->", hax_btn_id+13 ) then
          cur_page = cur_page + 1
        end
      end
    else
      if force_refilter then
        filtered_set = filter_options(options, filter_str)
      end
      grid_panel(title, filtered_set)
    end
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
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
    GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
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
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
      GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
    GuiLayoutBeginHorizontal(gui, xpos + 12, ypos)
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
}, 2, 16)


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

builder_panel = Panel{"wand builder", function()
  local button_id = hax_btn_id + 30
  button_id = shuffle_widget(button_id, 1, 12)
  button_id = mana_widget(button_id, 1, 16)
  button_id = mana_rec_widget(button_id, 1, 20)
  button_id = slots_widget(button_id, 1, 24)
  button_id = multi_widget(button_id, 1, 28)
  button_id = reload_widget(button_id, 1, 32)
  button_id = delay_widget(button_id, 1, 36)
  button_id = spread_widget(button_id, 1, 40)
  button_id = speed_widget(button_id, 1, 44)

  breadcrumbs(1, 0)

  GuiLayoutBeginVertical(gui, 1, 48)
  if GuiButton( gui, 0, 0, "Always cast: " .. (always_cast_choice or "None"), button_id+1) then
    enter_panel(always_cast_panel)
  end
  if GuiButton( gui, 0, 2, "[Spawn]", button_id+3) then
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
  GuiLayoutEnd(gui)
end}

local xpos_widget, xpos_val = create_numerical("X", {100, 1000, 10000}, 0)
local ypos_widget, ypos_val = create_numerical("Y", {100, 1000, 10000}, 0)

teleport_panel = Panel{"teleport", function()
  local button_id = hax_btn_id + 20
  button_id = xpos_widget(button_id, 1, 12)
  button_id = ypos_widget(button_id, 1, 16)

  breadcrumbs(1, 0)

  GuiLayoutBeginVertical(gui, 1, 20)
  if GuiButton( gui, 0, 0, "[Get current position]", button_id+1) then
    local x, y = get_player_pos()
    xpos_val.value, ypos_val.value = math.floor(x), math.floor(y)
  end
  if GuiButton( gui, 0, 4, "[Zero position]", button_id+2) then
    xpos_val.value, ypos_val.value = 0, 0
  end
  if GuiButton( gui, 0, 8, "[Teleport]", button_id+3) then
    GamePrint(("Attempting to teleport to (%d, %d)"):format(xpos_val.value, ypos_val.value))
    teleport(xpos_val.value, ypos_val.value)
  end
  GuiLayoutEnd(gui)
end}

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
  prev_panel()
end

local spell_options = {}
local always_cast_options = {
  {
    text = "None", 
    f = function()
      always_cast_choice = nil
      prev_panel()
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
    ui_name = resolve_localized_name(perk.ui_name, perk.id), 
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

local LC, AP, LC_prob, AP_prob = get_alchemy()

local function localize_material(mat)
  local n = GameTextGet("$mat_" .. mat)
  if n and n ~= "" then return n else return "[" .. mat .. "]" end
end

local function format_combo(combo, prob, localize)
  local ret = {}
  for idx, mat in ipairs(combo) do
    ret[idx] = (localize and localize_material(mat)) or mat
  end
  return table.concat(ret, ", ") .. " (" .. prob .. "%)"
end

local alchemy_combos = {
  AP = {
    [false]=format_combo(AP, AP_prob, false),
    [true]=format_combo(AP, AP_prob, true)
  },
  LC = {
    [false]=format_combo(LC, LC_prob, false),
    [true]=format_combo(LC, LC_prob, true)
  }
}

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

local function wrap_localized(f)
  local prev_localization = false
  return function()
    localization_widget(hax_btn_id+20, 31, 3)
    local localization_changed = (prev_localization ~= localization_val.value)
    prev_localization = localization_val.value
    f(localization_changed)
  end
end

always_cast_panel = Panel{"always cast", wrap_localized(wrap_paginate("Select a spell: ", always_cast_options))}
cards_panel = Panel{"spells", wrap_localized(wrap_paginate("Select a spell to spawn:", spell_options))}
perk_panel = Panel{"perks", wrap_localized(wrap_paginate("Select a perk to spawn:", perk_options))}
flasks_panel = Panel{"flasks", wrap_localized(wrap_paginate("Select a flask to spawn:", potion_options))}

wands_panel = Panel{"wands", function()
  grid_panel("Select a wand to spawn:", wand_options)
end}

local main_panels = {
  perk_panel, cards_panel, flasks_panel, wands_panel, builder_panel, teleport_panel
}

local function draw_main_panels(startid)
  for idx, panel in ipairs(main_panels) do
    if GuiButton( gui, 0, 0, panel.name, hax_btn_id + idx ) then
      enter_panel(panel)
    end
  end
  return startid + #main_panels + 1
end

menu_panel = Panel{"cheatgui", function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical( gui, 1, 11 )
  local next_id = draw_main_panels(hax_btn_id)
  draw_extra_buttons(next_id)
  GuiLayoutEnd( gui)
end}

register_cheat_button("Spell Refresh", function()
  GameRegenItemActionsInPlayer( get_player() )
end)

register_cheat_button("Much Health", function() set_health(40) end)

register_cheat_button(function()
  return ((tourist_mode_on and "Disable") or "Enable") .. " tourist mode"
end, toggle_tourist_mode)

local localize_alchemy = false
for _, recipe in ipairs{"LC", "AP"} do
  register_cheat_button(
    function()
      return ("%s: %s"):format(recipe, alchemy_combos[recipe][localize_alchemy])
    end, 
    function()
      localize_alchemy = not localize_alchemy
    end
  )
end

register_cheat_button("Spawn Orbs", function()
  local x, y = get_player_pos()
  for i = 0, 13 do
    EntityLoad(("data/entities/items/orbs/orb_%02d.xml"):format(i), x+(i*15), y - (i*5))
  end
end)

enter_panel(menu_panel)

function _cheat_gui_main()
  if gui ~= nil then
    GuiStartFrame( gui )
  end

  if _gui_frame_function ~= nil then
    handle_typing()
    local happy, errstr = pcall(_gui_frame_function)
    if not happy then
      print("Gui error: " .. errstr)
      _gui_frame_function = nil
    end
  end
end