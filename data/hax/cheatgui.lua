dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")
dofile_once("data/scripts/gun/gun_actions.lua")
dofile_once("data/hax/materials.lua")
dofile_once("data/hax/alchemy.lua")
dofile_once("data/hax/spawnables.lua")
dofile_once("data/hax/special_spawnables.lua")
dofile_once("data/hax/fungal.lua")
dofile_once("data/hax/gun_builder.lua")
dofile_once("data/hax/superhackykb.lua")
dofile_once("data/hax/utils.lua")

local CHEATGUI_VERSION = "1.5.0"
local CHEATGUI_TITLE = "cheatgui " .. CHEATGUI_VERSION
local console_connected = false

if _keyboard_present then
  -- have FFI
  dofile_once("data/hax/console.lua")
else
  CHEATGUI_TITLE = CHEATGUI_TITLE .. "S" 
end

local created_gui = false

local _next_available_id = 100
local function reset_id()
  _next_available_id = 100
end
local function next_id(n)
  n = n or 1
  local ret = _next_available_id
  _next_available_id = _next_available_id + n
  return ret
end

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
  if not _keyboard_present then return end
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

local closed_panel, perk_panel, cards_panel, menu_panel, flasks_panel
local wands_panel, builder_panel, always_cast_panel, teleport_panel, info_panel
local health_panel, money_panel, spawn_panel, console_panel

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

local function goto_subpanel(panel)
  panel_stack = {}
  enter_panel(menu_panel)
  enter_panel(panel)
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
  if GuiButton( gui, 0, 0, "[-]", next_id()) then
    hide_gui()
  end
  for idx, panel in ipairs(panel_stack) do
    if GuiButton( gui, 0, 0, panel.name .. ">", next_id()) then
      jump_back_panel(idx)
    end
  end
  GuiLayoutEnd(gui)
  GuiLayoutBeginHorizontal( gui, x, y+3)
  if #panel_stack > 1 and GuiButton( gui, 0, 0, "< back", next_id()) then
    prev_panel()
  end
  GuiLayoutEnd( gui )
end

local _info_widgets = {}
local _sorted_info_widgets = {}
local _all_info_widgets = {}

local function _update_info_widgets()
  _sorted_info_widgets = {}
  for wname, widget in pairs(_info_widgets) do
    table.insert(_sorted_info_widgets, {wname, widget})
  end
  table.sort(_sorted_info_widgets, function(a, b)
    return a[1] < b[1]
  end)
end

local function add_info_widget(wname, w)
  _info_widgets[wname] = w
  _update_info_widgets()
end

local function remove_info_widget(wname)
  _info_widgets[wname] = nil
  _update_info_widgets()
end

local function register_widget(wname, w)
  table.insert(_all_info_widgets, {wname, w})
end

closed_panel = Panel{"[+]", function()
  GuiLayoutBeginHorizontal( gui, 1, 0 )
  if GuiButton( gui, 0, 0, "[+]", next_id() ) then
    show_gui()
  end
  GuiLayoutEnd( gui )
  local col_pos = 5
  for idx, winfo in ipairs(_sorted_info_widgets) do
    local wname, widget = unpack(winfo)
    GuiLayoutBeginHorizontal(gui, col_pos, 0)
    local text = widget:text()
    if idx > 1 then text = "| " .. text end
    if GuiButton( gui, 0, 0, text, next_id() ) then
      widget:on_click()
    end
    GuiLayoutEnd( gui )
    col_pos = col_pos + (widget.width or 10)
  end
end}

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

local function get_option_text(opt)
  return maybe_call(opt.text or opt[1], opt)
end

local function grid_layout(options, col_width, callback)
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
      local text = get_option_text(opt)
      if GuiButton( gui, 0, 0, text, next_id() ) then
        (callback or opt.f or opt[2])(opt)
      end
      opt_pos = opt_pos + 1
    end
    GuiLayoutEnd( gui)
    xpos = xpos + xoffset
  end
end

local function grid_panel(title, options, col_width, callback)
  breadcrumbs(1, 0)
  grid_layout(options, col_width, callback)
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

local function create_radio(title, options, default, x_spacing)
  if not default then default = options[1][2] end
  local selected = default --1
  -- for i, v in ipairs(options) do
  --   if v[2] == default then selected = i end
  -- end
  local wrapper = {
    index = selected, 
    value = options[selected][2],
    reset = function(_self)
      _self.index = default
      _self.value = options[default][2]
    end
  }
  return function(xpos, ypos)
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
    GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
    GuiLayoutBeginHorizontal(gui, xpos+(x_spacing or 12), ypos)
    for idx, option in ipairs(options) do
      local text = option[1]
      if idx == wrapper.index then text = "[" .. text .. "]" end
      if GuiButton( gui, 0, 0, text, next_id() ) then
        wrapper.index = idx
        wrapper.value = option[2]
      end
    end
    GuiLayoutEnd(gui)
  end, wrapper
end

local function alphabetize(options, do_it)
  if not do_it then return options end
  local keys = {}
  for idx, opt in ipairs(options) do
    keys[idx] = {get_option_text(opt):lower(), opt}
  end
  table.sort(keys, function(a, b) return a[1] < b[1] end)
  local sorted = {}
  for idx, v in ipairs(keys) do
    sorted[idx] = v[2]
  end
  return sorted
end

local alphabetize_widget, alphabetize_val = create_radio("Alphabetize:", {
  {"Yes", true}, {"No", false}
}, 2, 16)

local function breakup_pages(options, page_size)
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
  return pages
end

local function wrap_paginate(title, options, page_size, callback)
  page_size = page_size or 28*4
  local cur_page = 1
  local pages = breakup_pages(options, page_size)

  local prev_alphabetize = false
  local filtered_set = options
  local filter_thing = {
    value = "", on_change = function(_self)
      filtered_set = alphabetize(
        filter_options(options, _self.value), 
        alphabetize_val.value
      )
    end
  }
  return function(force_refilter)
    if force_refilter or (prev_alphabetize ~= alphabetize_val.value) then
      force_refilter = true
      pages = breakup_pages(
        alphabetize(options, alphabetize_val.value), page_size
      )
    end
    prev_alphabetize = alphabetize_val.value
    set_type_default(filter_thing)
    local filter_str = filter_thing.value
    local filter_text = "[shift+type to filter]"
    if filter_str and (filter_str ~= "") then
      filter_text = filter_str
    end

    if _keyboard_present then
      GuiLayoutBeginVertical( gui, 61, 0)
      GuiText(gui, 0, 0, "Filter:")
      GuiLayoutEnd( gui )
      GuiLayoutBeginVertical( gui, 61 + 11, 0 )
      if GuiButton( gui, 0, 0, filter_text, next_id() ) then
        filter_thing.value = ""
      end
      GuiLayoutEnd( gui)
    end
    alphabetize_widget(31, 0)

    if (not filter_str) or (filter_str == "") then
      grid_panel(title, pages[cur_page], nil, callback)
      if cur_page > 1 then
        GuiLayoutBeginHorizontal(gui, 46, 96)
        if GuiButton( gui, 0, 0, "<-", next_id() ) then
          cur_page = cur_page - 1
        end
        GuiLayoutEnd(gui)
      end
      if #pages > 1 then
        GuiLayoutBeginHorizontal(gui, 48, 96)
        GuiText( gui, 0, 0, ("%d/%d"):format(cur_page, #pages))
        GuiLayoutEnd(gui)
      end
      if cur_page < #pages then
        GuiLayoutBeginHorizontal(gui, 51, 96)
        if GuiButton( gui, 0, 0, "->", next_id() ) then
          cur_page = cur_page + 1
        end
        GuiLayoutEnd(gui)
      end
    else
      if force_refilter then
        filtered_set = alphabetize(
          filter_options(options, filter_str), 
          alphabetize_val.value
        )
      end
      grid_panel(title, filtered_set, nil, callback)
    end
  end
end

local num_types = {
  float = {function(x) return x end, "%0.2f", 1.0},
  int = {function(x) return round(x) end, "%d", 1.0},
  frame = {function(x) return round(x) end, "%0.2f", 1.0/60.0},
  mills = {function(x) return round(x) end, "%0.2f", 1.0/1000.0},
  hearts = {function(x) return x end, "%d", 25.0}
}

local function create_numerical(title, increments, default, kind)
  local validate, fstr, multiplier = unpack(num_types[kind or "float"])

  local text_wrapper = {
    value = "",
    on_change = function(_self)
      -- eh?
    end,
    on_gain_focus = function(_self)
      _self.has_focus = true
      _self.value = _self.numeric:display_val()
    end,
    set_value = function(_self)
      local temp = tonumber(_self.value)
      if temp then
        _self.numeric.value = validate(temp / multiplier)
      end
    end,
    on_lose_focus = function(_self)
      _self.has_focus = false
      _self:set_value()
    end,
    on_hit_enter = function(_self)
      _self:set_value()
      set_type_target(nil)
    end,
    display_val = function(_self)
      if not _self.has_focus then return nil end
      return _self.value .. "_"
    end
  }

  local wrapper = {
    text = text_wrapper,
    value = default or 0.0,
    display_val = function(_self)
      return fstr:format(_self.value * multiplier)
    end,
    temp_val = "",
    reset = function(_self)
      _self.value = default
    end
  }

  text_wrapper.numeric = wrapper

  return function(xpos, ypos)
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
      GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
    GuiLayoutBeginHorizontal(gui, xpos + 12, ypos)
      for idx = #increments, 1, -1 do
        local s = "[" .. string.rep("-", idx) .. "]"
        if GuiButton( gui, 0, 0, s, next_id() ) then
          wrapper.value = wrapper.value - increments[idx]
        end
      end
      if GuiButton(gui, 0, 0, "" .. (text_wrapper:display_val() or wrapper:display_val()), next_id() ) then
        if text_wrapper.has_focus then
          set_type_target(nil)
        else
          set_type_target(text_wrapper)
        end
      end
      for idx = 1, #increments do
        local s = "[" .. string.rep("+", idx) .. "]"
        if GuiButton( gui, 0, 0, s, next_id() ) then
          wrapper.value = wrapper.value + increments[idx]
        end
      end
    GuiLayoutEnd(gui)
  end, wrapper
end

local localization_widget, localization_val = create_radio("Show localized names:", {
  {"Yes", true}, {"No", false}
}, 2, 16)

local shuffle_widget, shuffle_val = create_radio("Shuffle", {
  {"Yes", true}, {"No", false}
}, 2)

local mana_widget, mana_val = create_numerical("Mana", {50, 500}, 300, 'int')
local mana_rec_widget, mana_rec_val = create_numerical("Mana Recharge", {10, 100}, 100, 'int')
local slots_widget, slots_val = create_numerical("Slots", {1, 5}, 5, 'int')
local multi_widget, multi_val = create_numerical("Multicast", {1}, 1, 'int')
local reload_widget, reload_val = create_numerical("Reload", {1, 10}, 30, 'frame')
local delay_widget, delay_val = create_numerical("Delay", {1, 10}, 30, 'frame')
local spread_widget, spread_val = create_numerical("Spread", {0.1, 1}, 0.0, 'float')
local speed_widget, speed_val = create_numerical("Speed", {0.01, 0.1}, 1.0, 'float')

--local always_cast_choice = nil
local MAX_ALWAYS_CASTS=10 -- eh
local always_cast_index = 1
local always_casts = {}
local function compact_always_casts()
  local new_always_casts = {}
  for idx = 1, MAX_ALWAYS_CASTS do
    if always_casts[idx] then
      table.insert(new_always_casts, always_casts[idx])
    end
  end
  always_casts = new_always_casts
end

local builder_widgets = {
  {shuffle_widget, shuffle_val},
  {mana_widget, mana_val},
  {mana_rec_widget, mana_rec_val},
  {slots_widget, slots_val},
  {multi_widget, multi_val},
  {reload_widget, reload_val},
  {delay_widget, delay_val},
  {spread_widget, spread_val},
  {speed_widget, speed_val}
}

builder_panel = Panel{"wand builder", function()
  breadcrumbs(1, 0)

  for idx, widget in ipairs(builder_widgets) do
    widget[1](1, 8 + idx*4)
  end

  GuiLayoutBeginVertical(gui, 1, 48)
  for idx = 1, MAX_ALWAYS_CASTS do
    local label = "Always cast"
    if idx > 1 then label = label .. " (" .. idx .. ")" end
    if GuiButton( gui, 0, 0, label .. ": " .. (always_casts[idx] or "None"), next_id() ) then
      always_cast_index = idx
      enter_panel(always_cast_panel)
    end
    if not always_casts[idx] then break end
  end
  if GuiButton( gui, 0, 0, "[Reset all]", next_id() ) then
    for _, widget in ipairs(builder_widgets) do
      widget[2]:reset()
    end
    always_casts = {}
    always_cast_index=1
  end
  if GuiButton( gui, 0, 4, "[Spawn]", next_id() ) then
    local x, y = get_player_pos()
    local gun = {
      deck_capacity = slots_val.value,
      actions_per_round = multi_val.value,
      reload_time = reload_val.value,
      shuffle_deck_when_empty = (shuffle_val.value and 1) or 0,
      fire_rate_wait = delay_val.value,
      spread_degrees = spread_val.value,
      speed_multiplier = speed_val.value,
      mana_max = mana_val.value,
      mana_charge_speed = mana_rec_val.value,
      always_casts = always_casts --always_cast_choice
    }
    build_gun(x, y, gun)
  end
  GuiLayoutEnd(gui)
end}

local xpos_widget, xpos_val = create_numerical("X", {100, 1000, 10000}, 0, 'int')
local ypos_widget, ypos_val = create_numerical("Y", {100, 1000, 10000}, 0, 'int')

local SPECIAL_LOCATIONS = {
  ["$biome_lava"] = {x=2300}
}

local quick_teleports = nil
local function find_quick_teleports()
  if quick_teleports then return quick_teleports end
  quick_teleports = {}
  local temp_mountains = {}
  local prev_biome = "?"
  for y = 0, 15000, 500 do
    local cur_biome = BiomeMapGetName(0, y)
    if cur_biome == "$biome_holymountain" then
      temp_mountains[prev_biome] = y
    else
      prev_biome = cur_biome
    end
  end
  local function refine_position(y0)
    for y = y0, y0+500, 10 do
      local cur_biome = BiomeMapGetName(0, y)
      if cur_biome ~= "$biome_holymountain" then
        return y-10, cur_biome
      end
    end
  end
  local mountains = {}
  for biome, y in pairs(temp_mountains) do
    local teleport_y, next_biome = refine_position(y)
    teleport_y = teleport_y-200
    local teleport_x = -200
    if SPECIAL_LOCATIONS[next_biome] then
      teleport_x = SPECIAL_LOCATIONS[next_biome].x or teleport_x
      teleport_y = SPECIAL_LOCATIONS[next_biome].y or teleport_y
    end
    local label = ("%s (%d, %d)"):format(GameTextGet(next_biome), teleport_x, teleport_y)
    table.insert(quick_teleports, {label, teleport_x, teleport_y})
  end
  table.sort(quick_teleports, function(a, b) return a[3] < b[3] end)
  return quick_teleports
end

teleport_panel = Panel{"teleport", function()
  xpos_widget(1, 12)
  ypos_widget(1, 16)

  breadcrumbs(1, 0)

  GuiLayoutBeginVertical(gui, 1, 20)
  if GuiButton( gui, 0, 0, "[Get current position]", next_id() ) then
    local x, y = get_player_pos()
    xpos_val.value, ypos_val.value = math.floor(x), math.floor(y)
  end
  if GuiButton( gui, 0, 0, "[Zero position]", next_id() ) then
    xpos_val.value, ypos_val.value = 0, 0
  end
  if GuiButton( gui, 0, 0, "[Teleport]", next_id() ) then
    GamePrint(("Attempting to teleport to (%d, %d)"):format(xpos_val.value, ypos_val.value))
    teleport(xpos_val.value, ypos_val.value)
  end
  GuiText(gui, 0, 0, " ") -- just a spacer
  GuiText(gui, 0, 0, "----Quick Teleports----")
  for i, location in ipairs(find_quick_teleports()) do
    local label, x, y = unpack(location)
    if GuiButton(gui, 0, 0, label, next_id() ) then
      GamePrint(("Attempting to teleport to (%d, %d)"):format(x, y))
      teleport(x, y)
    end
  end
  GuiLayoutEnd(gui)
end}

local cur_hp_widget, cur_hp_val = create_numerical("HP", {1, 4}, 4, 'hearts')
local max_hp_widget, max_hp_val = create_numerical("Max HP", {1, 4}, 4, 'hearts')

health_panel = Panel{"health", function()
  cur_hp_widget(1, 12)
  max_hp_widget(1, 16)

  breadcrumbs(1, 0)

  GuiLayoutBeginVertical(gui, 1, 20)
  if GuiButton( gui, 0, 0, "[Get current health]", next_id() ) then
    cur_hp_val.value, max_hp_val.value = get_health()
  end
  if GuiButton( gui, 0, 0, "[Apply health changes]", next_id() ) then
    set_health(cur_hp_val.value, max_hp_val.value)
  end
  GuiText(gui, 0, 0, " ") -- just a spacer
  GuiText(gui, 0, 0, "----Quick health----")
  if GuiButton( gui, 0, 0, "[Add +25 max HP]", next_id() ) then
    cur_hp_val.value, max_hp_val.value = get_health()
    cur_hp_val.value, max_hp_val.value = cur_hp_val.value+1, max_hp_val.value+1
    set_health(cur_hp_val.value, max_hp_val.value)
  end
  if GuiButton( gui, 0, 0, "[Add +100 max HP]", next_id() ) then
    cur_hp_val.value, max_hp_val.value = get_health()
    cur_hp_val.value, max_hp_val.value = cur_hp_val.value+4, max_hp_val.value+4
    set_health(cur_hp_val.value, max_hp_val.value)
  end
  GuiLayoutEnd(gui)
end}

local money_widget, money_val = create_numerical("Gold", {10, 100, 1000}, 0, 'int')

money_panel = Panel{"gold", function()
  money_widget(1, 12)
  breadcrumbs(1, 0)

  GuiLayoutBeginVertical(gui, 1, 20)
  if GuiButton( gui, 0, 0, "[Get current gold]", next_id() ) then
    money_val.value = get_money()
  end
  if GuiButton( gui, 0, 0, "[Set current gold]", next_id() ) then
    set_money(money_val.value)
  end
  GuiText(gui, 0, 0, " ") -- just a spacer
  GuiText(gui, 0, 0, "----Quick cash----")
  if GuiButton( gui, 0, 0, "[+100 Gold]", next_id() ) then
    money_val.value = get_money()+100
    set_money(money_val.value)
  end
  if GuiButton( gui, 0, 0, "[+500 Gold]", next_id() ) then
    money_val.value = get_money()+500
    set_money(money_val.value)
  end
  if GuiButton( gui, 0, 0, "[+2000 Gold]", next_id() ) then
    money_val.value = get_money()+2000
    set_money(money_val.value)
  end
  GuiLayoutEnd(gui)
end}

-- build these button lists once so we aren't rebuilding them every frame
local function localized_name(thing)
  if localization_val.value then return thing.ui_name else return thing.id end
end

local function spawn_spell_button(card)
  local x, y = get_player_pos()
  GamePrint( "Attempting to spawn " .. card.id)
  CreateItemActionEntity( card.id, x, y )
end

local function set_always_cast(card)
  always_casts[always_cast_index] = (card and card.id) or nil
  compact_always_casts()
  prev_panel()
end

local spell_options = {}
local always_cast_options = {
  {
    text = "None", 
    f = function()
      set_always_cast(nil)
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
  GamePrint( "Attempting to spawn " .. perk.id)
  spawn_perk(perk.id, get_player())
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

local quantity_widget, quantity_val = create_numerical("Quantity mult:", {100, 1000}, 1000, 'mills')
local container_widget, container_val = create_radio("Container:", {
  {"Potion", "potion"}, {"Pouch", "pouch"}
}, 1)

local function spawn_potion_button(potion)
  GamePrint( "Attempting to spawn potion of " .. potion.id)
  spawn_potion(potion.id, quantity_val.value, container_val.value)
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
  set_tourist_mode(tourist_mode_on)
  GamePrint("Tourist mode: " .. tostring(tourist_mode_on))
end

local function open_console()
  local auth_token = listen_console_connections()
  console_connected = true
  os.execute("start http://localhost:8777/index.html?token=" .. (auth_token or "none"))
end

local seedval = "?"
SetRandomSeed(0, 0)
seedval = tostring(Random() * 2^31)

local LC, AP, LC_prob, AP_prob = get_alchemy()

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

local function draw_extra_buttons()
  for _, button in ipairs(extra_buttons) do
    local title, f = button[1], button[2]
    if type(title) == 'function' then title = title() end
    if f then
      if GuiButton( gui, 0, 0, title, next_id() ) then
        f()
      end
    else
      GuiText( gui, 0, 0, title)
    end
  end
end

local function wrap_localized(f)
  local prev_localization = false
  return function()
    localization_widget(31, 3)
    local localization_changed = (prev_localization ~= localization_val.value)
    prev_localization = localization_val.value
    f(localization_changed)
  end
end

local _flask_base = wrap_localized(wrap_paginate("Select a flask to spawn:", potion_options))
local function flask_panel_func()
  quantity_widget(61, 3)
  container_widget(31, 6)
  _flask_base()
end

local gui_grid_ref_panel = Panel{"gui grid ref.", function()
  breadcrumbs(1, 0)
  for row = 0, 100, 10 do
    for col = 0, 100, 10 do
      GuiLayoutBeginHorizontal(gui, col, row)
      GuiText(gui, 0, 0, ("(%d,%d)"):format(col, row))
      GuiLayoutEnd(gui)
    end
  end
end}

local function spawn_item_button(item)
  GamePrint("Attempting to spawn " .. item.path)
  spawn_item(item.path)
end

-- merge special spawns into the base spawnlist
for _, v in ipairs(special_spawnables) do
  table.insert(spawn_list, v)
end

-- generate spawn item options
local spawn_options = {}
for idx, item in ipairs(spawn_list) do
  spawn_options[idx] = {
    text = localized_name,
    path = item.path,
    id = item.xml,
    ui_name = item.name, 
    f = spawn_item_button
  }
end

always_cast_panel = Panel{"always cast", wrap_localized(wrap_paginate("Select a spell: ", always_cast_options))}
cards_panel = Panel{"spells", wrap_localized(wrap_paginate("Select a spell to spawn:", spell_options))}
perk_panel = Panel{"perks", wrap_localized(wrap_paginate("Select a perk to spawn:", perk_options))}
flasks_panel = Panel{"flasks", flask_panel_func}
spawn_panel = Panel{"items", wrap_localized(wrap_paginate("Select an item to spawn:", spawn_options))}

wands_panel = Panel{"wands", function()
  grid_panel("Select a wand to spawn:", wand_options)
end}

info_panel = Panel{"widgets", function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical(gui, 1, 11)
  for idx, winfo in ipairs(_all_info_widgets) do
    local wname, w = unpack(winfo)
    local enabled = _info_widgets[wname] ~= nil
    local text = w:text()
    if enabled then
      if GuiButton(gui, 0, 0, "[*] " .. text, next_id() ) then
        remove_info_widget(wname)
      end
    else
      if GuiButton(gui, 0, 0, "[ ] " .. text, next_id() ) then
        GamePrint("Adding " .. wname .. " to info bar (minimize cheatgui to see)")
        add_info_widget(wname, w)
      end
    end
  end
  GuiLayoutEnd(gui)
end}

local fungal_conv = {from="blood", to="blood"}
local fungal_index

local function choose_fungal_material(mat)
  fungal_conv[fungal_index] = mat.id
  prev_panel()
end

local fungal_material_panel = Panel{"shift material", 
  wrap_localized(wrap_paginate("Select a material: ", potion_options, nil, choose_fungal_material))}

local function predict_nth_shift(n)
  local shift_from, shift_to = fungal_predict_transform(n or 0)
  if shift_from and shift_to then
    return tostring((shift_from or "?")) .. " -> " 
        .. tostring((shift_to or "?"))
  else
    return "No effect (same material chosen as src and dest)"
  end
end

local fungal_panel = Panel{"fungal", function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical(gui, 1, 12)
  GuiText(gui, 0, 0, "Next shift: " .. predict_nth_shift(0))
  GuiText(gui, 0, 0, "Next shift+1: " .. predict_nth_shift(1))
  GuiText(gui, 0, 0, "Next shift+2: " .. predict_nth_shift(2))
  if GuiButton( gui, 0, 0, "FROM: " .. fungal_conv.from, next_id() ) then
    fungal_index = "from"
    enter_panel(fungal_material_panel)
  end
  if GuiButton( gui, 0, 0, "TO: " .. fungal_conv.to, next_id() ) then
    fungal_index = "to"
    enter_panel(fungal_material_panel)
  end
  if GuiButton( gui, 0, 0, "[Force convert]", next_id()) then
    GamePrint("Would convert: " .. fungal_conv.from .. " -> " .. fungal_conv.to)
    fungal_force_convert(fungal_conv.from, fungal_conv.to)
  end
  GuiLayoutEnd(gui)
end}


console_panel = Panel{"console", function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical(gui, 1, 11)
  if console_connected then
    if GuiButton( gui, 0, 0, "[Close console host]", next_id() ) then
      close_console_connections()
      console_connected = false
    end
  else
    if GuiButton( gui, 0, 0, "[Open console host]", next_id() ) then
      listen_console_connections()
      console_connected = true
    end
  end
  if GuiButton( gui, 0, 0, "[Open new console]", next_id() ) then
    open_console()
  end
  GuiText(gui, 0, 0, " ") -- just a spacer
  GuiText(gui, 0, 0, "----Active connections (click to close)----")
  local conns = get_console_connections()
  local sorted_conns = {}
  for addr, client in pairs(conns) do
    table.insert(sorted_conns, addr)
  end
  table.sort(sorted_conns)
  for _, addr in ipairs(sorted_conns) do
    local conn = conns[addr] or {stat_out=-1, stat_in=-1}
    local text = ("%s [in: %d, out: %d]"):format(addr, conn.stat_in or 0, conn.stat_out or 0)
    if GuiButton( gui, 0, 0, text, next_id() ) then
      if conns[addr] then conns[addr]:close() end
    end
  end
  GuiLayoutEnd(gui)
end}

local main_panels = {
  perk_panel, cards_panel, flasks_panel, wands_panel, spawn_panel,
  builder_panel, health_panel, money_panel,
  teleport_panel, fungal_panel, info_panel, gui_grid_ref_panel
}

if _keyboard_present then table.insert(main_panels, console_panel) end

local function draw_main_panels()
  for idx, panel in ipairs(main_panels) do
    if GuiButton( gui, 0, 0, panel.name .. "->", next_id() ) then
      enter_panel(panel)
    end
  end
end

menu_panel = Panel{CHEATGUI_TITLE, function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical( gui, 1, 11 )
  draw_main_panels()
  draw_extra_buttons()
  GuiLayoutEnd(gui)
end}

register_cheat_button("[edit wands everywhere]", function()
  spawn_perk("EDIT_WANDS_EVERYWHERE", get_player())
end)

register_cheat_button("[spell refresh]", function()
  GameRegenItemActionsInPlayer(get_player())
end)

register_cheat_button("[full heal]", function() quick_heal() end)

register_cheat_button("[end fungal trip]", function()
  EntityRemoveIngestionStatusEffect(get_player(), "TRIP" )
end)

register_cheat_button("[reset fungal shift timer]", function()
  GlobalsSetValue("fungal_shift_last_frame", "-1000000")
end)

register_cheat_button(function()
  return "[" .. ((tourist_mode_on and "disable") or "enable") .. " tourist mode]"
end, toggle_tourist_mode)

register_cheat_button("[spawn orbs]", function()
  local x, y = get_player_pos()
  for i = 0, 13 do
    EntityLoad(("data/entities/items/orbs/orb_%02d.xml"):format(i), x+(i*15), y - (i*5))
  end
end)

if _keyboard_present then
  register_cheat_button("[open console]", function()
    open_console()
    enter_panel(console_panel)
  end)
end

enter_panel(menu_panel)

-- widgets
local function StatsWidget(dispname, keyname, extra_pad)
  local width = math.ceil(#dispname * 0.9) + (extra_pad or 3)
  return {
    text = function()
      return ("%s: %s"):format(dispname, StatsGetValue(keyname) or "?")
    end,
    on_click = function()
      goto_subpanel(info_panel)
    end,
    width = width
  }
end

register_widget("playtime", StatsWidget("Playtime", "playtime_str", 6))
register_widget("visited", StatsWidget("Visited", "places_visited"))
register_widget("gold", StatsWidget("Gold", "gold_all"))
register_widget("hearts", StatsWidget("Hearts", "heart_containers"))
register_widget("items", StatsWidget("Items", "items"))
register_widget("projectiles", StatsWidget("Shot", "projectiles_shot", 3))
register_widget("kicks", StatsWidget("Kicked", "kicks"))
register_widget("kills", StatsWidget("Kills", "enemies_killed"))
register_widget("damage", StatsWidget("Damage taken", "damage_taken"))
register_widget("frame", {
  text = function()
    return ("Frame: %08d"):format(GameGetFrameNum())
  end,
  on_click = function()
    goto_subpanel(info_panel)
  end,
  width = 16
})

register_widget("position", {
  text = function()
    local x, y = get_player_pos()
    return ("X: %d, Y: %d"):format(x, y)
  end,
  on_click = function()
    goto_subpanel(info_panel)
  end,
  width = 15
})

local localize_alchemy = false

for _, recipe in ipairs{"LC", "AP"} do
  local maxwidth = math.max(
    #(alchemy_combos[recipe][true]), 
    #(alchemy_combos[recipe][false])
  )

  register_widget(recipe, {
    text = function()
      return ("%s: %s"):format(recipe, alchemy_combos[recipe][localize_alchemy])
    end,
    on_click = function()
      localize_alchemy = not localize_alchemy
    end,
    width = math.ceil(maxwidth * 0.75)
  })
end

function _cheat_gui_main()
  if gui ~= nil then
    GuiStartFrame( gui )
  end

  if _gui_frame_function ~= nil then
    reset_id()
    handle_typing()
    local happy, errstr = pcall(_gui_frame_function)
    if not happy then
      print("Gui error: " .. errstr)
      GamePrint("cheatgui err: " .. errstr)
      if console_connected then
        send_all_consoles(errstr .. ":" .. debug.traceback())
      end
      hide_gui()
    end
  end

  wake_up_waiting_threads(1) -- from coroutines.lua
  if console_connected and _socket_update then _socket_update() end
end

hide_gui()