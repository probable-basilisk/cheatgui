local function hax_prng_next(v)
  local hi = math.floor(v / 127773.0)
  local lo = v % 127773
  v = 16807 * lo - 2836 * hi
  if v <= 0 then
    v = v + 2147483647
  end
  return v
end

local function shuffle(arr, seed)
  local v = math.floor(seed / 2) + 0x30f6
  v = hax_prng_next(v)
  for i = #arr, 1, -1 do
    v = hax_prng_next(v)
    local fidx = v / 2^31
    local target = math.floor(fidx * i) + 1
    arr[i], arr[target] = arr[target], arr[i]
  end
end

local LIQUIDS = {"water", "water_ice", "water_swamp",
"oil", "alcohol", "swamp", "mud", "blood",
"blood_fungi", "blood_worm", "radioactive_liquid",
"cement", "acid", "lava", "urine",
"poison", "magic_liquid_teleportation",
"magic_liquid_polymorph", "magic_liquid_random_polymorph",
"magic_liquid_berserk", "magic_liquid_charm",
"magic_liquid_invisibility"}

local ORGANICS = {"sand", "bone", "soil", "honey",
"slime", "snow", "rotten_meat", "wax",
"gold", "silver", "copper", "brass", "diamond",
"coal", "gunpowder", "gunpowder_explosive",
"grass", "fungi"}

local function copy_arr(arr)
  local ret = {}
  for k, v in pairs(arr) do ret[k] = v end
  return ret
end

local function random_material(v, mats)
  for _ = 1, 1000 do
    v = hax_prng_next(v)
    local rval = v / 2^31
    local sel_idx = math.floor(#mats * rval) + 1
    local selection = mats[sel_idx]
    if selection then
      mats[sel_idx] = false
      return v, selection
    end
  end
end

local function random_recipe(rand_state, seed)
  local liqs = copy_arr(LIQUIDS)
  local orgs = copy_arr(ORGANICS)
  local m1, m2, m3, m4 = "?", "?", "?", "?"
  rand_state, m1 = random_material(rand_state, liqs)
  rand_state, m2 = random_material(rand_state, liqs)
  rand_state, m3 = random_material(rand_state, liqs)
  rand_state, m4 = random_material(rand_state, orgs)
  local combo = {m1, m2, m3, m4}
  shuffle(combo, seed)
  return rand_state, {combo[1], combo[2], combo[3]}
end

function get_alchemy()
  local seed = tonumber(StatsGetValue("world_seed"))
  local rand_state = math.floor(seed * 0.17127000 + 1323.59030000)

  for i = 1, 6 do
    rand_state = hax_prng_next(rand_state)
  end

  local lc_combo, ap_combo = {"?"}, {"?"}
  rand_state, lc_combo = random_recipe(rand_state, seed)
  rand_state = hax_prng_next(rand_state)
  rand_state = hax_prng_next(rand_state)
  rand_state, ap_combo = random_recipe(rand_state, seed)

  return lc_combo, ap_combo
end