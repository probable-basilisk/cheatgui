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

local a_to_code = {}
a_to_code.UNKNOWN = 0
a_to_code.A = 4
a_to_code.B = 5
a_to_code.C = 6
a_to_code.D = 7
a_to_code.E = 8
a_to_code.F = 9
a_to_code.G = 10
a_to_code.H = 11
a_to_code.I = 12
a_to_code.J = 13
a_to_code.K = 14
a_to_code.L = 15
a_to_code.M = 16
a_to_code.N = 17
a_to_code.O = 18
a_to_code.P = 19
a_to_code.Q = 20
a_to_code.R = 21
a_to_code.S = 22
a_to_code.T = 23
a_to_code.U = 24
a_to_code.V = 25
a_to_code.W = 26
a_to_code.X = 27
a_to_code.Y = 28
a_to_code.Z = 29
a_to_code["1"] = 30
a_to_code["2"] = 31
a_to_code["3"] = 32
a_to_code["4"] = 33
a_to_code["5"] = 34
a_to_code["6"] = 35
a_to_code["7"] = 36
a_to_code["8"] = 37
a_to_code["9"] = 38
a_to_code["0"] = 39
a_to_code.RETURN = 40
a_to_code.ESCAPE = 41
a_to_code.BACKSPACE = 42
a_to_code.TAB = 43
a_to_code[" "] = 44
a_to_code["-"] = 45
a_to_code["="] = 46
a_to_code["["] = 47
a_to_code["]"] = 48
a_to_code.BACKSLASH = 49
a_to_code.NONUSHASH = 50
a_to_code.SEMICOLON = 51
a_to_code.APOSTROPHE = 52
a_to_code.GRAVE = 53
a_to_code.COMMA = 54
a_to_code.PERIOD = 55
a_to_code.SLASH = 56
a_to_code.CAPSLOCK = 57
a_to_code.F1 = 58
a_to_code.F2 = 59
a_to_code.F3 = 60
a_to_code.F4 = 61
a_to_code.F5 = 62
a_to_code.F6 = 63
a_to_code.F7 = 64
a_to_code.F8 = 65
a_to_code.F9 = 66
a_to_code.F10 = 67
a_to_code.F11 = 68
a_to_code.F12 = 69
a_to_code.PRINTSCREEN = 70
a_to_code.SCROLLLOCK = 71
a_to_code.PAUSE = 72
a_to_code.INSERT = 73
a_to_code.HOME = 74
a_to_code.PAGEUP = 75
a_to_code.DELETE = 76
a_to_code.END = 77
a_to_code.PAGEDOWN = 78
a_to_code.RIGHT = 79
a_to_code.LEFT = 80
a_to_code.DOWN = 81
a_to_code.UP = 82
a_to_code.NUMLOCKCLEAR = 83
a_to_code.KP_DIVIDE = 84
a_to_code.KP_MULTIPLY = 85
a_to_code.KP_MINUS = 86
a_to_code.KP_PLUS = 87
a_to_code.KP_ENTER = 88
a_to_code.KP_1 = 89
a_to_code.KP_2 = 90
a_to_code.KP_3 = 91
a_to_code.KP_4 = 92
a_to_code.KP_5 = 93
a_to_code.KP_6 = 94
a_to_code.KP_7 = 95
a_to_code.KP_8 = 96
a_to_code.KP_9 = 97
a_to_code.KP_0 = 98
a_to_code.KP_PERIOD = 99
a_to_code.NONUSBACKSLASH = 100
a_to_code.APPLICATION = 101
a_to_code.POWER = 102
a_to_code.KP_EQUALS = 103
a_to_code.F13 = 104
a_to_code.F14 = 105
a_to_code.F15 = 106
a_to_code.F16 = 107
a_to_code.F17 = 108
a_to_code.F18 = 109
a_to_code.F19 = 110
a_to_code.F20 = 111
a_to_code.F21 = 112
a_to_code.F22 = 113
a_to_code.F23 = 114
a_to_code.F24 = 115
a_to_code.EXECUTE = 116
a_to_code.HELP = 117
a_to_code.MENU = 118
a_to_code.SELECT = 119
a_to_code.STOP = 120
a_to_code.AGAIN = 121
a_to_code.UNDO = 122
a_to_code.CUT = 123
a_to_code.COPY = 124
a_to_code.PASTE = 125
a_to_code.FIND = 126
a_to_code.MUTE = 127
a_to_code.VOLUMEUP = 128
a_to_code.VOLUMEDOWN = 129
a_to_code.KP_COMMA = 133
a_to_code.KP_EQUALSAS400 = 134
a_to_code.INTERNATIONAL1 = 135
a_to_code.INTERNATIONAL2 = 136
a_to_code.INTERNATIONAL3 = 137
a_to_code.INTERNATIONAL4 = 138
a_to_code.INTERNATIONAL5 = 139
a_to_code.INTERNATIONAL6 = 140
a_to_code.INTERNATIONAL7 = 141
a_to_code.INTERNATIONAL8 = 142
a_to_code.INTERNATIONAL9 = 143
a_to_code.LANG1 = 144
a_to_code.LANG2 = 145
a_to_code.LANG3 = 146
a_to_code.LANG4 = 147
a_to_code.LANG5 = 148
a_to_code.LANG6 = 149
a_to_code.LANG7 = 150
a_to_code.LANG8 = 151
a_to_code.LANG9 = 152
a_to_code.ALTERASE = 153
a_to_code.SYSREQ = 154
a_to_code.CANCEL = 155
a_to_code.CLEAR = 156
a_to_code.PRIOR = 157
a_to_code.RETURN2 = 158
a_to_code.SEPARATOR = 159
a_to_code.OUT = 160
a_to_code.OPER = 161
a_to_code.CLEARAGAIN = 162
a_to_code.CRSEL = 163
a_to_code.EXSEL = 164
a_to_code.KP_00 = 176
a_to_code.KP_000 = 177
a_to_code.THOUSANDSSEPARATOR = 178
a_to_code.DECIMALSEPARATOR = 179
a_to_code.CURRENCYUNIT = 180
a_to_code.CURRENCYSUBUNIT = 181
a_to_code.KP_LEFTPAREN = 182
a_to_code.KP_RIGHTPAREN = 183
a_to_code.KP_LEFTBRACE = 184
a_to_code.KP_RIGHTBRACE = 185
a_to_code.KP_TAB = 186
a_to_code.KP_BACKSPACE = 187
a_to_code.KP_A = 188
a_to_code.KP_B = 189
a_to_code.KP_C = 190
a_to_code.KP_D = 191
a_to_code.KP_E = 192
a_to_code.KP_F = 193
a_to_code.KP_XOR = 194
a_to_code.KP_POWER = 195
a_to_code.KP_PERCENT = 196
a_to_code.KP_LESS = 197
a_to_code.KP_GREATER = 198
a_to_code.KP_AMPERSAND = 199
a_to_code.KP_DBLAMPERSAND = 200
a_to_code.KP_VERTICALBAR = 201
a_to_code.KP_DBLVERTICALBAR = 202
a_to_code.KP_COLON = 203
a_to_code.KP_HASH = 204
a_to_code.KP_SPACE = 205
a_to_code.KP_AT = 206
a_to_code.KP_EXCLAM = 207
a_to_code.KP_MEMSTORE = 208
a_to_code.KP_MEMRECALL = 209
a_to_code.KP_MEMCLEAR = 210
a_to_code.KP_MEMADD = 211
a_to_code.KP_MEMSUBTRACT = 212
a_to_code.KP_MEMMULTIPLY = 213
a_to_code.KP_MEMDIVIDE = 214
a_to_code.KP_PLUSMINUS = 215
a_to_code.KP_CLEAR = 216
a_to_code.KP_CLEARENTRY = 217
a_to_code.KP_BINARY = 218
a_to_code.KP_OCTAL = 219
a_to_code.KP_DECIMAL = 220
a_to_code.KP_HEXADECIMAL = 221
a_to_code.LCTRL = 224
a_to_code.LSHIFT = 225
a_to_code.LALT = 226
a_to_code.LGUI = 227
a_to_code.RCTRL = 228
a_to_code.RSHIFT = 229
a_to_code.RALT = 230
a_to_code.RGUI = 231
a_to_code.MODE = 257
a_to_code.AUDIONEXT = 258
a_to_code.AUDIOPREV = 259
a_to_code.AUDIOSTOP = 260
a_to_code.AUDIOPLAY = 261
a_to_code.AUDIOMUTE = 262
a_to_code.MEDIASELECT = 263
a_to_code.WWW = 264
a_to_code.MAIL = 265
a_to_code.CALCULATOR = 266
a_to_code.COMPUTER = 267
a_to_code.AC_SEARCH = 268
a_to_code.AC_HOME = 269
a_to_code.AC_BACK = 270
a_to_code.AC_FORWARD = 271
a_to_code.AC_STOP = 272
a_to_code.AC_REFRESH = 273
a_to_code.AC_BOOKMARKS = 274
a_to_code.BRIGHTNESSDOWN = 275
a_to_code.BRIGHTNESSUP = 276
a_to_code.DISPLAYSWITCH = 277
a_to_code.KBDILLUMTOGGLE = 278
a_to_code.KBDILLUMDOWN = 279
a_to_code.KBDILLUMUP = 280
a_to_code.EJECT = 281
a_to_code.SLEEP = 282
a_to_code.APP1 = 283
a_to_code.APP2 = 284

local code_to_a = {}
for string_name, code in pairs(a_to_code) do
  code_to_a[code] = string_name
end

ffi.cdef([[
  const uint8_t* SDL_GetKeyboardState(int* numkeys);
]])
_SDL = ffi.load('SDL2.dll')

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
  return pressed
end

hack_type = function(current_str)
  local pressed = hack_update_keys()
  for _, key in ipairs(pressed) do
    if #key == 1 then
      current_str = current_str .. key
    elseif key == "BACKSPACE" then
      current_str = current_str:sub(1,-2)
    end
  end
  return current_str
end

print("Hacky KB loaded?")