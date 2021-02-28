local fungal_env = nil

local function load_fungal_env()
  fungal_env = {}
  for k, v in pairs(cheatgui_stash) do fungal_env[k] = v end
  local fungal_script_src = ModTextFileGetContent("data/scripts/magic/fungal_shift.lua")
  local fscript = loadstring(fungal_script_src)
  setfenv(fscript, fungal_env)
end

function fungal_predict_transform()
  if not fungal_env then load_fungal_env() end
end