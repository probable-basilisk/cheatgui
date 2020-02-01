print("Loading hacky KB?")

if _hacky_keyboard_defined then
  return
end

_hacky_keyboard_defined = true

hack_type = function()
  return ""
end

if not require then
  print("No require? Urgh.")
  return
end

local ffi = require('ffi')
if not ffi then
  print("No FFI? Well that's a pain.")
  return
end

_keyboard_present = true

ffi.cdef([[
  const uint8_t* SDL_GetKeyboardState(int* numkeys);
  uint32_t SDL_GetKeyFromScancode(uint32_t scancode);
  char* SDL_GetScancodeName(uint32_t scancode);
  char* SDL_GetKeyName(uint32_t key);
]])
_SDL = ffi.load('SDL2.dll')

local code_to_a = {}
local shifts = {}

for i = 0, 284 do
  local keycode = _SDL.SDL_GetKeyFromScancode(i)
  if keycode > 0 then
    local keyname = ffi.string(_SDL.SDL_GetKeyName(keycode))
    if keyname and #keyname > 0 then
      code_to_a[i] = keyname:lower()
      if keyname:lower():find("shift") then
        table.insert(shifts, i)
      end
    end
  end
end

local prev_state = {}
for i = 0, 284 do
  prev_state[i] = 0
end

function hack_update_keys()
  local keys = _SDL.SDL_GetKeyboardState(nil)
  local pressed = {}
  -- start at scancode 1 because we don't care about "UNKNOWN"
  for scancode = 1, 284 do 
    if keys[scancode] > 0 and prev_state[scancode] <= 0 then
      pressed[#pressed+1] = code_to_a[scancode]
    end
    prev_state[scancode] = keys[scancode]
  end
  local shift_held = false
  for _, shiftcode in ipairs(shifts) do
    if keys[shiftcode] > 0 then
      shift_held = true
      break
    end
  end
  return pressed, shift_held
end

local REPLACEMENTS = {
  space = " "
}

hack_type = function(current_str, no_shift)
  local pressed, shift_held = hack_update_keys()
  local hit_enter = false
  for _, key in ipairs(pressed) do
    if (no_shift or shift_held) and REPLACEMENTS[key] then
      current_str = current_str .. REPLACEMENTS[key]
    elseif (no_shift or shift_held) and (#key == 1) then
      current_str = current_str .. key
    elseif key == "backspace" then
      current_str = current_str:sub(1,-2)
    elseif key == "enter" or key == "return" then
      hit_enter = true
    end
  end
  return current_str, hit_enter
end

print("Hacky KB loaded?")