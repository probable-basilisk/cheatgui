dofile("data/scripts/gun/procedural/gun_procedural.lua")

function build_gun(x, y, gun)
  local entity_id = EntityLoad("data/hax/wand_empty.xml", x, y)
	local ability_comp = EntityGetFirstComponent( entity_id, "AbilityComponent" )

  gun.cost = gun.cost or 0
  gun.deck_capacity = gun.deck_capacity or 5
  gun.actions_per_round = gun.actions_per_round or 1
  gun.reload_time = gun.reload_time or 30
  gun.shuffle_deck_when_empty = gun.shuffle_deck_when_empty or 0
  gun.fire_rate_wait = gun.fire_rate_wait or 30
  gun.spread_degrees = gun.spread_degrees or 0
  gun.speed_multiplier = gun.speed_multiplier or 1
  gun.prob_unshuffle = gun.prob_unshuffle or 0.1
  gun.prob_draw_many = gun.prob_draw_many or 0.15
  gun.mana_charge_speed = gun.mana_charge_speed or 10000
  gun.mana_max = gun.mana_max or 10000
  gun.force_unshuffle = gun.force_unshuffle or 1

  local name = "HAXXXX" --ComponentGetValue( ability_comp, "ui_name" )
	
	ComponentSetValue( ability_comp, "ui_name", name )
	ComponentObjectSetValue( ability_comp, "gun_config", "actions_per_round", gun["actions_per_round"] )
	ComponentObjectSetValue( ability_comp, "gun_config", "reload_time", gun["reload_time"] )
	ComponentObjectSetValue( ability_comp, "gun_config", "deck_capacity", gun["deck_capacity"] )
	ComponentObjectSetValue( ability_comp, "gun_config", "shuffle_deck_when_empty", gun["shuffle_deck_when_empty"] )
	ComponentObjectSetValue( ability_comp, "gunaction_config", "fire_rate_wait", gun["fire_rate_wait"] )
	ComponentObjectSetValue( ability_comp, "gunaction_config", "spread_degrees", gun["spread_degrees"] )
	ComponentObjectSetValue( ability_comp, "gunaction_config", "speed_multiplier", gun["speed_multiplier"] )
	ComponentSetValue( ability_comp, "mana_charge_speed", gun["mana_charge_speed"])
	ComponentSetValue( ability_comp, "mana_max", gun["mana_max"])
	ComponentSetValue( ability_comp, "mana", gun["mana_max"])
	ComponentSetValue( ability_comp, "item_recoil_recovery_speed", 15.0 ) -- TODO: implement logic for setting this

	local wand = GetWand( gun )
	SetWandSprite( entity_id, ability_comp, wand.file, wand.grip_x, wand.grip_y, (wand.tip_x - wand.grip_x), (wand.tip_y - wand.grip_y) )
end