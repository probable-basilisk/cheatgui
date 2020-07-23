dofile_once("data/hax/lib/pollnet.lua")
dofile_once("data/scripts/lib/coroutines.lua")

-- this empty table is used as a special value that will suppress
-- printing any kind of "RES>" value (normally "[no value]" would print)
local UNPRINTABLE_RESULT = {}

-- (from http://lua-users.org/wiki/SplitJoin)
local strfind = string.find
local tinsert = table.insert
local strsub = string.sub
local function strsplit(text, delimiter)
  local list = {}
  local pos = 1
  if strfind("", delimiter, 1) then -- this would result in endless loops
    error("Delimiter matches empty string!")
  end
  while 1 do
    local first, last = strfind(text, delimiter, pos)
    if first then -- found?
      tinsert(list, strsub(text, pos, first-1))
      pos = last+1
    else
      tinsert(list, strsub(text, pos))
      break
    end
  end
  return list
end

local function is_localhost(addr)
  local parts = strsplit(addr, ":")
  return parts[1] == "127.0.0.1" -- IPV6?
end

local function reload_utils(console_env)
  local env_utils, err = loadfile("data/hax/utils.lua")
  if type(env_utils) ~= "function" then
    console_env.print("Error loading utils: " .. tostring(err))
    return
  end
  setfenv(env_utils, console_env)
  local happy, err = pcall(env_utils)
  if not happy then
    console_env.print("Error executing utils: " .. tostring(err))
  end
  console_env.print("Utils loaded.")
end

local _persistent_funcs = {}

local function add_persistent_func(name, f)
  _persistent_funcs[name] = f
end

local function remove_persistent_func(name)
  _persistent_funcs[name] = nil
end

local function run_persistent_funcs()
  for fname, f in pairs(_persistent_funcs) do
    local happy, err = pcall(f, fname)
    if not happy then cprint(err) end
  end
end

local _help_info = nil
local function reload_help(fn)
  fn = fn or "tools_modding/lua_api_documentation.txt"
  local f, err = io.open(fn)
  if not f then error("Couldn't open " .. fn) end
  local res = f:read("*a")
  f:close()
  if not res then error("Couldn't read " .. fn) end
  _help_info = {}
  res = res:gsub("\r", "") -- get rid of horrible carriage returns
  local lines = strsplit(res, "\n")
  for _, line in ipairs(lines) do
    local paren_idx = line:find("%(")
    if paren_idx then
      local funcname = line:sub(1, paren_idx-1)
      _help_info[funcname] = line
    end
  end
end

local function help_str(funcname)
  if not _help_info then reload_help() end
  return _help_info[funcname]
end

local function _strinfo(v)
  if v == nil then return "nil" end
  local vtype = type(v)
  if vtype == "number" then
    return ("%0.4f"):format(v)
  elseif vtype == "string" then
    return '"' .. v .. '"'
  elseif vtype == "boolean" then
    return tostring(v)
  else
    return ("[%s] %s"):format(vtype, tostring(v))
  end
end

local function strinfo(...)
  local frags = {}
  local nargs = select('#', ...)
  if nargs == 0 then
    return "[no value]"
  end
  if nargs == 1 and select(1, ...) == UNPRINTABLE_RESULT then
    return UNPRINTABLE_RESULT
  end
  for idx = 1, nargs do
    frags[idx] = _strinfo(select(idx, ...))
  end
  return table.concat(frags, ", ")
end

local function make_complete(console_env)
  return function(s)
    local opts = {}

    local parts = strsplit(s, "%.") -- strsplit takes a pattern, so have to escape "."
    local cur = console_env
    local prefix = ""
    for idx = 1, (#parts) - 1 do
      cur = cur[parts[idx]]
      if not cur then return UNPRINTABLE_RESULT end
      prefix = prefix .. parts[idx] .. "."
    end
    if type(cur) ~= "table" then return UNPRINTABLE_RESULT end
    local lastpart = parts[#parts]
    if not lastpart then return UNPRINTABLE_RESULT end
    for k, _ in pairs(cur) do
      if k:find(lastpart) == 1 then
        table.insert(opts, k)
      end
    end
    if #opts > 0 then
      table.sort(opts)
      console_env.send("COM>" .. prefix .. " " .. table.concat(opts, ","))
    end
    return UNPRINTABLE_RESULT
  end
end

local function make_console_env(client)
  local console_env = {}
  for k, v in pairs(getfenv()) do
    console_env[k] = v
  end

  function console_env.print(...)
    local msg = table.concat({...}, " ")
    client.sock:send("GAME> " .. msg)
    return UNPRINTABLE_RESULT
  end

  function console_env.send(msg)
    client.sock:send(msg)
  end

  function console_env.print_table(t)
    local s = {}
    for k, v in pairs(t) do
      table.insert(s, k .. ": " .. type(v))
    end
    console_env.print(table.concat(s, "\n"))
  end

  function console_env.log(...)
    local msg = table.concat({...}, " ")
    print(client.addr .. ": " .. msg)
  end

  function console_env.info(...)
    console_env.print(strinfo(...))
    return UNPRINTABLE_RESULT
  end

  function console_env.dofile(fn)
    local s = loadfile(fn)
    if type(s) == 'string' then
      -- work around Noita's broken loadfile that returns error
      -- message as first argument rather than as second
      error(fn .. ": " .. s)
    end
    setfenv(s, console_env)
    return s()
  end

  function console_env.help(funcname)
    console_env.send("HELP> " .. (help_str(funcname) or (funcname .. "-> [no help available]")))
    return UNPRINTABLE_RESULT
  end

  console_env.complete = make_complete(console_env)
  console_env.add_persistent_func = add_persistent_func
  console_env.set_persistent_func = add_persistent_func -- alias
  console_env.remove_persistent_func = remove_persistent_func
  console_env.strinfo = strinfo
  console_env.help_str = help_str
  console_env.UNPRINTABLE_RESULT = UNPRINTABLE_RESULT
  
  reload_utils(console_env)

  return console_env
end

local function _collect(happy, ...)
  if happy then
    return happy, strinfo(...)
  else
    return happy, ...
  end
end

local SCRATCH_SIZE = 1000000 -- might as well have a safe meg of space
local ws_server_socket = nil
local http_server = nil
local ws_clients = {}

local auth_token = nil
local function get_token()
  if not auth_token then
    auth_token = lib_pollnet.nanoid()
  end
  return auth_token
end

local function on_new_client(sock, addr)
  print("New client: " .. addr)
  if ws_clients[addr] then ws_clients[addr].sock:close() end
  local new_client = {addr = addr, sock = sock, authorized = false}
  new_client.console_env = make_console_env(new_client)
  ws_clients[addr] = new_client
end

function listen_console_connections()
  if not ws_server_socket then
    ws_server_socket = lib_pollnet.listen_ws("127.0.0.1:9777", SCRATCH_SIZE)
    ws_server_socket:on_connection(on_new_client)
    http_server = lib_pollnet.serve_http("127.0.0.1:8777", "mods/cheatgui/www")
  end
  return get_token()
end

function close_console_connections()
  for _, sock in pairs(ws_clients) do sock:close() end
  ws_clients = {}
  if ws_server_socket then ws_server_socket:close() end
  ws_server_socket = nil
  if http_server then http_server:close() end
  http_server = nil
end

local function check_authorization(client, msg)
  if not is_localhost(client.addr) then
    client.sock:send("SYS> UNAUTHORIZED: NOT LOCALHOST!")
    client.sock:close()
    client.sock = nil
    return
  end

  if msg:find(get_token()) then
    client.authorized = true
    client.sock:send("SYS> AUTHORIZED")
    GamePrint("Accepted console connection: " .. client.addr)
  else
    client.sock:send("SYS> UNAUTHORIZED: INVALID TOKEN")
    client.sock:close()
    client.sock = nil
  end
end

local function _handle_client_message(client, msg)
  if not client.authorized then
    return check_authorization(client, msg)
  end

  local f, err = nil, nil
  if not msg:find("\n") then
    -- if this is a single line, try putting "return " in front
    -- (convenience to allow us to inspect values)
    f, err = loadstring("return " .. msg)
  end
  if not f then -- multiline, or not an expression
    f, err = loadstring(msg)
    if not f then
      client.sock:send("ERR> Parse error: " .. tostring(err))
      return
    end
  end
  setfenv(f, client.console_env)
  local happy, retval = _collect(pcall(f))
  if happy then
    if retval ~= UNPRINTABLE_RESULT then
      client.sock:send("RES> " .. tostring(retval))
    end
  else
    client.sock:send("ERR> " .. tostring(retval))
  end
end

local count = 0
function _socket_update()
  if not ws_server_socket then return end
  local happy, msg = ws_server_socket:poll()
  if not happy then
    print("Main WS server closed?")
    close_console_connections()
    return
  end

  for addr, client in pairs(ws_clients) do
    if client.sock then
      local happy, msg = client.sock:poll()
      if not happy then
        print("Sock error: " .. tostring(msg))
        client.sock:close()
        client.sock = nil
        ws_clients[addr] = nil
      elseif msg then
        _handle_client_message(client, msg)
      end
    else
      ws_clients[addr] = nil
    end
  end

  if (count % 60 == 0) and http_server then
    local happy, errmsg = http_server:poll()
    if not happy then
      print("HTTP server closed: " .. tostring(errmsg))
      http_server:close()
      http_server = nil
    end
  end

  count = count + 1
end