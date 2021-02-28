local fungal_env = nil
local _predict_transform = nil

local STASH = cheatgui_stash

local function _dofile(fn)
  local src = STASH.ModTextFileGetContent(fn)
  if not src then return nil end
  src = loadstring(src)
  if not src then return nil end
  setfenv(src, fungal_env)
  return src()
end

local _done_files = {}
local function _dofile_once(fn)
  if _done_files[fn] then return _done_files[fn] end
  _done_files[fn] = _dofile(fn)
  return _done_files[fn]
end

local MOCKED_FUNCTIONS = {
  "GlobalsSetValue",
  "GameCreateParticle",
  "GamePrintImportant",
  "GamePrint",
  "EntityCreateNew",
  "EntityAddComponent",
  "EntityAddChild",
  "EntityGetAllChildren",
  "GameTriggerMusicFadeOutAndDequeueAll",
  "GameTriggerMusicEvent",
  "EntityLoad",
}

if not loadstring then
  local VIRT_PATH = "mods/cheatgui/_fake_fungal_shift.lua"
  function loadstring(buf)
    set_text(VIRT_PATH, buf)
    return loadfile(VIRT_PATH)
  end
end

local function load_fungal_env()
  fungal_env = {}

  for k, v in pairs(cheatgui_stash) do fungal_env[k] = v end
  fungal_env.dofile = _dofile
  fungal_env.dofile_once = _dofile_once
  setfenv(_dofile, fungal_env)
  setfenv(_dofile_once, fungal_env)

  for _, v in ipairs(MOCKED_FUNCTIONS) do
    fungal_env[v] = function(...)
      -- haha do nothing
    end
  end

  local fungal_script_src = cheatgui_stash.ModTextFileGetContent("data/scripts/magic/fungal_shift.lua")
  local fscript = loadstring(fungal_script_src)
  setfenv(fscript, fungal_env)
  fscript()
end

local function get_player()
  return (EntityGetWithTag( "player_unit" ) or {})[1]
end

local function get_player_pos()
  local player = get_player()
  if not player then return 0, 0 end
  return EntityGetTransform(player)
end

local function predict_transform()
  local _from, _to = nil, nil
  fungal_env.ConvertMaterialEverywhere = function(from_material, to_material)
    _from = CellFactory_GetUIName(from_material) --:gsub("$", "")
    _to = CellFactory_GetUIName(to_material) --:gsub("$", "")
  end
  pcall(fungal_env.fungal_shift, get_player(), get_player_pos())
  return _from, _to
end

function fungal_predict_transform()
  if not fungal_env then load_fungal_env() end
  if not fungal_env then return nil end
  return predict_transform()
end