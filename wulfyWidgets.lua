moduleVersion = 0.04
pID="wulfy"
--Wulfy Widgets by @wulfygrl
--built around the Encoder by Tipsy Hobbit (steam_id: 13465982)
--based on the functions from TyrantNomad's Easy Modules Unified by @TyrantNomad
--(but almost entirely rewritten)

props = {
  { propID = 'w_powtou',
    name = 'PowTou',
    values = {'w_pow','w_tou'},
    funcOwner = self,
    tags = "basic",
    visible = true,
    visible_in_hand = 0,
    activateFunc = 'togglePowTou',
    btnFunc= 'powtouBtn' }
}
vals = {
  { valueID = 'w_pow',
    type = 'number',
    desc = 'Calculated power',
    default = 0, },
  { valueID = 'w_tou',
    type = 'number',
    desc = 'Calculated toughness',
    default = 0, }
}

isRegistered = false
githubSource = "https://raw.githubusercontent.com/wulfygrl/wulfys-widgets-mtg-tts/main/wulfyWidgets.lua"

function onload(saved_data)
  chipButtons()
end

logStyle('wm', {1,0.4,1}, "","")
-- wrapper to color my log messages
function wLog(msg, pre, tags)
  tags = tags or 'wm' 
  log(msg, pre, tags)
end

function selfUpdateCheck()
  wLog("Wulfy Widgets update check. Current: "..moduleVersion)
  WebRequest.get(githubSource, function(wr)
    if wr.is_error then
      wLog("Error fetching code from GitHub:\n"..wr.error)
    else
      local gitVersion = tonumber(wr.text:match('moduleVersion%s=%s(%d+%.%d+)'))
      if gitVersion ~= nil then 
        wLog("Git version = "..gitVersion)
        if gitVersion ~= nil and gitVersion > moduleVersion then
          self.script_code = wr.text
          wLog("Reloading Wulfy Widgets.")
          self.reload()
        end
      end
    end
  end)
end

function chipButtons()
  self.clearButtons()
  -- Title Background
  self.createButton({
    click_function="DoNothing",
    function_owner=self,
    position={0,0.15,-0.25},
    rotation={180,0,0},
    height= 240,
    width= 525,
    color = {90/255,24/255,51/255}
  })
  -- Title
  self.createButton({
    label= "Wulfy's\nWidgets",
    click_function="DoNothing",
    function_owner=self,
    position={0,0.15,-0.25},
    height= 0,
    width= 0,
    color = {90/255,24/255,51/255},
    font_size = 100,
    font_color = {1,156/255,196/255}
  })
  -- Version info
  self.createButton({
    label = "VERSION "..moduleVersion,
    click_function=("DoNothing"),
    function_owner=self,
    position={0,0.15,0.075},
    rotation = {0,0,0},
    height=0,
    width=0,
    font_size = 60,
    font_color = {90/255,24/255,51/255}
    -- font_color = {1,156/255,196/255}
  })
  -- Update Button
  self.createButton({
    label="Update",
    click_function="selfUpdateCheck",
    function_owner=self,
    position={0,0.15,0.27},
    color = {238/255, 25/255, 110/255},
    hover_color = {90/255,24/255,51/255},
    height=60,
    width=450,
  })
  -- Register Button
  -- self.createButton({
  --   click_function="DoNothing",
  --   function_owner=self,
  --   position={0,0.15,0.55},
  --   height=0,
  --   width=0,
  --   font_size = 60,
  -- })
  self.createButton({
    label=(isRegistered and "Unregister" or "Register"),
    click_function=(isRegistered and "unRegisterModule" or "registerModule"),
    function_owner=self,
    position={0,0.15,0.55},
    rotation = {0,0,0}, --(isRegistered and {180,0,0} or {0,0,0}),
    color = (isRegistered and {238/255, 25/255, 110/255} or {1,156/255,196/255}),
    hover_color = {90/255,24/255,51/255},
    font_color = (isRegistered and {1,156/255,196/255} or {90/255,24/255,51/255}),
    font_size = 60,
    height=60,
    width=425,
  })
end

function registerModule()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then 
    for i,prop in pairs(props) do
      if not enc.call("APIpropertyExists",prop) then
        enc.call("APIregisterProperty", prop)
      end
    end
    for i,val in pairs(vals) do
      if not enc.call("APIvalueExists",val) then
        enc.call("APIregisterValue", val)
      end
    end
    isRegistered = true
    chipButtons()
  else 
    wLog("No encoder found") 
  end
end
function unRegisterModule()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then
    for i,prop in pairs(props) do
      if enc.call("APIpropertyExists", {propID = pID}) then
        enc.call("APIremoveProperty", {propID = pID})
      end
    end
    isRegistered = false
  else
    wLog("No encoder found")
  end
  chipButtons()
end

function togglePowTou(obj,ply)
  local pID='w_powtou'
  local enc = Global.getVar('Encoder')
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APItoggleProperty",{obj=obj,propID=pID})
    if enc.call('APIobjIsPropEnabled',{obj=obj,propID=pID}) then
      wLog('Enabled!')
    else
      wLog('Disabled :c')
    end
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function createButtons(t)
  wLog('Starting Create Buttons')
  local enc = Global.getVar('Encoder')
  if enc == nil then return nil end
  for i,prop in pairs(props) do
    wLog('Checking if prop '..prop.propID..' is enabled.')
    local active = enc.call('APIobjIsPropEnabled', {obj=t.obj, propID=prop.propID})
    wLog(active)
    if active then
      wLog('Calling '..prop.btnFunc)
      self.call(prop.btnFunc, {o=t.obj})
    end
  end
end

function powtouBtn(o)
  local obj = o.o
  local enc = Global.getVar('Encoder')
  if enc == nil then return end
  local widthPerDigit = 25
  local baseWidth = 250
  local horizontalSize = 320
  local verticalSize = 130
  local powerText = 1
  local toughnessText = 1
  wLog(obj.getGUID())
  local flip = enc.call('APIgetFlip', {obj=obj})
  obj.createButton({
    label = "/",
    font_color = {1,1,1},
    font_size= 80,
    click_function = 'DoNothing',
    function_owner = self,
    height = 0,
    width = 0,
    color = {133/255,133/255,133/255},
    hover_color = {133/255,133/255,133/255},
    position=
    {
        0.75*flip,
        0.28*flip,
        1.3315
    },
    rotation={0,0,90-90*flip}
  })
end

--[[
A compact pure-Lua JSON library taken from:
https://gist.githubusercontent.com/tylerneylon/59f4bcf316be525b30ab/raw/7f69cc2cea38bf68298ed3dbfc39d197d53c80de/json.lua
Modified so json.parse fits in one function.
Ignored json.stringify since we only need parsing.
--]]
json = {}
function json.parse(str, pos, end_delim)
  local skip_delim
  if json.skip_delim == nil then
    json.skip_delim = function(str, pos, delim, err_if_missing)
      pos = pos + #str:match('^%s*', pos)
      if str:sub(pos, pos) ~= delim then
        if err_if_missing then
          error('Expected ' .. delim .. ' near position ' .. pos)
        end
        return pos, false
      end
      return pos + 1, true
    end
  end
  skip_delim = json.skip_delim
  local parse_str_val
  if json.parse_str_val == nil then
    json.parse_str_val = function(str, pos, val)
      val = val or ''
      local early_end_error = 'End of input found while parsing string.'
      if pos > #str then error(early_end_error) end
      local c = str:sub(pos, pos)
      if c == '"'  then return val, pos + 1 end
      if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
      -- We must have a \ character.
      local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
      local nextc = str:sub(pos + 1, pos + 1)
      if not nextc then error(early_end_error) end
      return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
    end
  end
  parse_str_val = json.parse_str_val
  local parse_num_val
  if json.parse_num_val == nil then
    json.parse_num_val = function(str, pos)
      local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
      local val = tonumber(num_str)
      if not val then error('Error parsing number at position ' .. pos .. '.') end
      return val, pos + #num_str
    end
  end
  parse_num_val = json.parse_num_val
  pos = pos or 1
  if pos > #str then error('Reached unexpected end of input.') end
  local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
  local first = str:sub(pos, pos)
  if first == '{' then  -- Parse an object.
    local obj, key, delim_found = {}, true, true
    pos = pos + 1
    while true do
      key, pos = json.parse(str, pos, '}')
      if key == nil then return obj, pos end
      if not delim_found then error('Comma missing between object items.') end
      pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
      obj[key], pos = json.parse(str, pos)
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '[' then  -- Parse an array.
    local arr, val, delim_found = {}, true, true
    pos = pos + 1
    while true do
      val, pos = json.parse(str, pos, ']')
      if val == nil then return arr, pos end
      if not delim_found then error('Comma missing between array items.') end
      arr[#arr + 1] = val
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '"' then  -- Parse a string.
    return parse_str_val(str, pos + 1)
  elseif first == '-' or first:match('%d') then  -- Parse a number.
    return parse_num_val(str, pos)
  elseif first == end_delim then  -- End of an object or array.
    return nil, pos + 1
  else  -- Parse true, false, or null.
    local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
    for lit_str, lit_val in pairs(literals) do
      local lit_end = pos + #lit_str - 1
      if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
    end
    local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
    error('Invalid json syntax starting at ' .. pos_info_str)
  end
end

function DoNothing()
end
