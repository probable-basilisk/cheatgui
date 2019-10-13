dofile("data/scripts/gun/procedural/gun_procedural.lua")

local function gen_gun()
	local entity_id = GetUpdatedEntityID()
	local x, y = EntityGetTransform( entity_id )
  SetRandomSeed( x, y )
  
  local cost, level = 0, 6

	local ability_comp = EntityGetFirstComponent( entity_id, "AbilityComponent" )

	cost = 0

  local gun = { }
  gun["cost"]	= cost
  gun["deck_capacity"] = 50
  gun["actions_per_round"] = 50
  gun["reload_time"] = 60
  gun["shuffle_deck_when_empty"] = 0
  gun["fire_rate_wait"] = 60
  gun["spread_degrees"] = 0
  gun["speed_multiplier"] = 1
  gun["prob_unshuffle"] = 0.1
  gun["prob_draw_many"] = 0.15
  gun["mana_charge_speed"] = 10000
  gun["mana_max"] = 10000
  gun["force_unshuffle"] = 1


  local name = "HAXXXX" --ComponentGetValue( ability_comp, "ui_name" )
	
	-- SetItemSprite( entity_id, ability_comp, "data/items_gfx/gungen_guns/submachinegun_", Random( 0, 7 ) )
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

	-- stuff in the gun
	local good_cards = 5
	if( Random(0,100) < 7 ) then good_cards = Random(20,50) end

	if( is_rare == 1 ) then
		good_cards = good_cards * 2
	end

	local orig_level = level
	level = level - 1
	local deck_capacity = gun["deck_capacity"]
	local actions_per_round = gun["actions_per_round"]
	local card_count = Random( 1, 3 ) 
	local bullet_card = GetRandomActionWithType( x, y, level, ACTION_TYPE_PROJECTILE, 0 )
	local random_bullets = 0 
	local good_card_count = 0

	if( Random(0,100) < 50 and card_count < 3 ) then card_count = card_count + 1 end 
	
	if( Random(0,100) < 10 or is_rare == 1 ) then 
		card_count = card_count + Random( 1, 2 )
	end

	good_cards = Random( 5, 45 )
	card_count = Random( 0.51 * deck_capacity, deck_capacity )
	card_count = clamp( card_count, 1, deck_capacity-1 )

	-- card count is in between 1 and 6

	if( Random(0,100) < (orig_level*10)-5 ) then
		random_bullets = 1
	end

	if( Random( 0, 100 ) < 4 or is_rare == 1 ) then
		local card = 0
		local p = Random(0,100) 
		if( p < 77 ) then
			card = GetRandomActionWithType( x, y, level+1, ACTION_TYPE_MODIFIER, 666 )
		elseif( p < 94 ) then
			card = GetRandomActionWithType( x, y, level+1, ACTION_TYPE_DRAW_MANY, 666 )
			good_card_count = good_card_count + 1
		else 
			card = GetRandomActionWithType( x, y, level+1, ACTION_TYPE_PROJECTILE, 666 )
		end
		AddGunActionPermanent( entity_id, card )
	end


	for i=1,card_count do
		if( Random(0,100) < good_cards ) then
			-- if actions_per_round == 1 and the first good card, then make sure it's a draw x
			local card = 0
			if( good_card_count == 0 and actions_per_round == 1 ) then
				card = GetRandomActionWithType( x, y, level, ACTION_TYPE_DRAW_MANY, i )
				good_card_count = good_card_count + 1
			else
				if( Random(0,100) < 83 ) then
					card = GetRandomActionWithType( x, y, level, ACTION_TYPE_MODIFIER, i )
				else
					card = GetRandomActionWithType( x, y, level, ACTION_TYPE_DRAW_MANY, i )
				end
			end
		
			AddGunAction( entity_id, card )
		else
			AddGunAction( entity_id, bullet_card )
			if( random_bullets == 1 ) then
				bullet_card = GetRandomActionWithType( x, y, level, ACTION_TYPE_PROJECTILE, i )
			end
		end
	end

	local wand = GetWand( gun )

	SetWandSprite( entity_id, ability_comp, wand.file, wand.grip_x, wand.grip_y, (wand.tip_x - wand.grip_x), (wand.tip_y - wand.grip_y) )
	-- SetItemSprite( entity_id, ability_comp, "data/items_gfx/wands/wand_", Random( 0, 999 ) )

	-- this way:
	-- AddGunActionPermanent( entity_id, "ELECTRIC_CHARGE" )
end
gen_gun()