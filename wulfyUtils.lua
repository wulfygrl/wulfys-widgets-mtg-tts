moduleVersion = 0.02
pID = 'w_utils'
-- Copy the code between UNIVERSAL FUNCTIONS and END UNIVERSAL to the top of
-- any object in order to use this module's utility funcitons.

-- [[ UNIVERSAL ]] --
MOD_DATA = {
  modVersion = moduleVersion,
  modID = pID,
  modName = 'Wulfy Utils',
  gitFileName = 'wulfyUtils.lua',
  colors = {
    init = {
      primary = 'h0',
      secondary = 'h210'
    }
  },
}
ENC_DATA = {
  pID = pID
}
-- retrieve the utils module
function utils() return Global.getVar('wulfy_utils') end

-- Log message wrapper for this module.
function wLog(msg, pre, tags)
  utils().call('log_wrapper', {
    pID = MOD_DATA.modID,
    color = MOD_DATA.colors.primary.mlight,
    msg = msg,
    pre = pre,
    tags = tags,
  })
end

-- Same but for debug messages.
function wDebug(msg, pre, tags) if DEBUG then wLog(msg, pre, tags) end end

-- register this module
function registerModule()
  MOD_DATA.isRegistered = utils().call('registerWulfyMod', ENC_DATA)
  chipButtons()
end

-- unregister this module
function unregisterModule()
  MOD_DATA.isRegistered = utils().call('unregisterWulfyMod', ENC_DATA)
  chipButtons()
end

-- update this module
function selfUpdate()
  utils().call('updateCheck', { o = self, d = MOD_DATA })
end

function chipButtons()
  colors() --init colors just in case
  utils().call('drawChipButtons', { o = self, d = MOD_DATA })
end

-- return this module's colors, initializing them if needed.
function colors()
  if MOD_DATA.colors.init ~= nil then
    MOD_DATA.colors = utils().call('getColors', MOD_DATA.colors.init)
  end
  return MOD_DATA.colors
end

function onLoad(saved_data)
  if self.getDescription() == 'wulfy_utils' then
    Global.setVar('wulfy_utils', self)
    chipButtons()
  else
    local function init() initMod(saved_data) end
    local function checkUtils() return (utils() ~= nil) end
    local function spawnUtils()
      giturl = 'https://raw.githubusercontent.com/wulfygrl/wulfys-widgets-mtg-tts/refs/heads/main/wulfyUtils.lua'
      WebRequest.get(giturl, function(wr)
        if wr.is_error then
          log('Failed to fetch utils. wulfy mods will not function.','','error')
          return
        end
        utils_data = self.getData()
        utils_data.Nickname = 'Wulfy Utils'
        utils_data.Description = 'w_utils'
        utils_data.script_code = wr.text
        utils_data.script_State = ''
        spawnObjectData({
          data = utils_data,
          position = self.getPosition(),
          callback_function = init
        })
      end)
    end
    Wait.condition(init, checkUtils, 2, spawnUtils)
  end
end
-- [[ END UNIVERSAL ]]--

-- [[ UTILITY FUNCTIONS ]] --
DEBUG = true
--[[ Wrapper to color log messages according to the module's palette.
params:
  pID: module's primary property ID
  color: color for log messages with this label
  msg, pre, tags: regular parameters to the TTS log() function
--]]
LOG_STYLES = {}
function log_wrapper(p)
  local color = p.color or MOD_DATA.colors.primary.mlight
  local pID = p.pID or pID
  if LOG_STYLES[pID] ~= color then
    logStyle(pID, color, '', '')
    LOG_STYLES[pID] = color
  end
  local msg = p.msg or ''
  local pre = p.pre or ''
  local tags = p.tags or pID
  log(msg, pre, tags)
end

function registerWulfyMod(enc_data)
  local props = enc_data.properties or {}
  local vals = enc_data.values or {}
  local menus = enc_data.menus or {}
  local enc = Global.getVar('Encoder')
  if enc == nil then
    wLog('No encoder found')
    return false
  end
  for _, prop in ipairs(props) do
    repeat
      if enc.call('APIpropertyExists', prop) then break end
      enc.call('APIregisterProperty', prop)
    until true
  end
  for _, val in ipairs(vals) do
    repeat
      if enc.call('APIvalueExists', val) then break end
      enc.call('APIregisterValue', val)
    until true
  end
  for _, menu in ipairs(menus) do
    enc.call('APIregisterMenu', menu)
  end
  return true
end

function unregisterWulfyMod(enc_data)
  local props = enc_data.properties or {}
  local enc = Global.getVar('Encoder')
  if enc == nil then return false end
  for i, prop in ipairs(props) do
    if enc.call('APIpropertyExists', prop) then
      enc.call('APIremoveProperty', prop)
    end
  end
  return false
end

GITINFO = {
  baseurl = 'https://raw.githubusercontent.com',
  user = 'wulfygrl',
  repo = 'wulfys-widgets-mtg-tts',
  branch = 'main'
}
function updateCheck(p)
  local mod_data = p.d
  local obj = p.o
  if mod_data == nil or obj == nil then
    wLog('Missing argument to updateCheck.')
    return
  end
  local filename = mod_data.gitFileName
  local modName = mod_data.modName
  local moduleVersion = mod_data.modVersion
  if filename == nil or modName == nil or moduleVersion == nil then
    wLog('Missing module info. Skipping update.')
  end
  local giturl = string.format('%s/%s/%s/refs/heads/%s/%s',
    GITINFO.baseurl, GITINFO.user, GITINFO.repo, GITINFO.branch, filename)
  wDebug(modName .. " update check. Current: " .. moduleVersion)
  wDebug('Git url: ' .. giturl)
  WebRequest.get(giturl, function(wr)
    if wr.is_error then
      wLog('Error fetching code:\n' .. wr.error, '', 'error')
      return
    end
    local gitVersion = tonumber(wr.text:match('moduleVersion%s=%s(%d+%.%d+)'))
    if gitVersion == nil then
      wLog('Couldn\'t parse git version.', '', 'error')
      return
    end
    wDebug("Git version = " .. gitVersion)
    if gitVersion > moduleVersion then
      obj.script_code = wr.text
      wDebug("Reloading " .. modName)
      obj.reload()
    end
  end)
end

function drawChipButtons(p)
  local obj = p.o
  local data = p.d
  if data == nil then
    wLog('no mod_data passed to drawChipButtons')
    return
  end
  local colors = data.colors or self.colors()
  local title = data.modName or "MISSING"
  local version = data.modVersion or "MISSING"
  local isRegistered = data.isRegistered or false
  local function makeButtonsObj()
    local buttons = {
      title_bg = {
        label = '',
        click_function = "pass",
        function_owner = self,
        position = { 0, 0.15, -0.25 },
        rotation = { 180, 0, 0 },
        height = 240,
        width = 525,
        color = colors.primary.dark
      },
      title_txt = {
        label = title:gsub(' ', '\n'),
        click_function = "pass",
        function_owner = self,
        position = { 0, 0.15, -0.25 },
        height = 0,
        width = 0,
        font_size = 100,
        font_color = colors.primary.light
      },
      version = {
        label = 'VERSION' .. version,
        click_function = "pass",
        function_owner = self,
        position = { 0, 0.15, 0.075 },
        rotation = { 0, 0, 0 },
        height = 0,
        width = 0,
        font_size = 60,
        font_color = colors.primary.dark
      },
      update = {
        label = "Update",
        click_function = "selfUpdate",
        function_owner = obj,
        position = { 0, 0.15, 0.27 },
        height = 60,
        width = 450,
        color = colors.primary.mlight,
        hover_color = colors.primary.mid,
        font_color = colors.primary.dark
      },
      register = {
        label = 'Register',
        click_function = 'registerModule',
        function_owner = obj,
        position = { 0, 0.15, 0.55 },
        rotation = { 0, 0, 0 },
        font_size = 60,
        height = 60,
        width = 425,
        color = colors.secondary.mlight,
        hover_color = colors.secondary.mid,
        font_color = colors.secondary.dark
      }
    }
    if isRegistered then
      buttons.register.label = 'Unregister'
      buttons.register.click_function = 'unregisterModule'
      buttons.register.color = colors.primary.mlight
      buttons.register.hover_color = colors.primary.mid
      buttons.register.font_color = colors.primary.dark
    end
    for name, btn in pairs((data.extraButtons or {})) do
      buttons[name] = btn
    end
    return buttons
  end
  local buttons = data.buttonsOverride or makeButtonsObj()
  obj.clearButtons()
  for name, btn in pairs(buttons) do
    if not pcall(function() obj.createButton(btn) end) then
      wLog('Error drawing ' .. name .. 'button.')
    else
      wDebug('Drew button ' .. name)
    end
  end
end

function getColors(p)
  local c1, c2, h1, h2, hues
  hues = {
    h0 = { -- Red
      light = { 254 / 255, 169 / 255, 169 / 255 },
      mlight = { 211 / 255, 105 / 255, 105 / 255 },
      mid = { 169 / 255, 56 / 255, 56 / 255 },
      mdark = { 127 / 255, 21 / 255, 21 / 255 },
      dark = { 85 / 255, 0 / 255, 0 / 255 },
    },
    h15 = {
      light = { 254 / 255, 193 / 255, 169 / 255 },
      mlight = { 211 / 255, 135 / 255, 105 / 255 },
      mid = { 169 / 255, 89 / 255, 56 / 255 },
      mdark = { 127 / 255, 51 / 255, 21 / 255 },
      dark = { 85 / 255, 24 / 255, 0 / 255 },
    },
    h30 = { -- Red-orange
      light = { 254 / 255, 207 / 255, 169 / 255 },
      mlight = { 211 / 255, 153 / 255, 105 / 255 },
      mid = { 169 / 255, 108 / 255, 56 / 255 },
      mdark = { 127 / 255, 69 / 255, 21 / 255 },
      dark = { 85 / 255, 38 / 255, 0 / 255 },
    },
    h45 = {
      light = { 254 / 255, 218 / 255, 169 / 255 },
      mlight = { 211 / 255, 166 / 255, 105 / 255 },
      mid = { 169 / 255, 121 / 255, 56 / 255 },
      mdark = { 127 / 255, 82 / 255, 21 / 255 },
      dark = { 85 / 255, 48 / 255, 0 / 255 },
    },
    h60 = { -- Orange
      light = { 254 / 255, 226 / 255, 169 / 255 },
      mlight = { 211 / 255, 176 / 255, 105 / 255 },
      mid = { 169 / 255, 132 / 255, 56 / 255 },
      mdark = { 127 / 255, 92 / 255, 21 / 255 },
      dark = { 85 / 255, 56 / 255, 0 / 255 },
    },
    h75 = {
      light = { 254 / 255, 233 / 255, 169 / 255 },
      mlight = { 211 / 255, 185 / 255, 105 / 255 },
      mid = { 169 / 255, 141 / 255, 56 / 255 },
      mdark = { 127 / 255, 101 / 255, 21 / 255 },
      dark = { 85 / 255, 63 / 255, 0 / 255 },
    },
    h90 = { -- Yellow-orange
      light = { 254 / 255, 239 / 255, 169 / 255 },
      mlight = { 211 / 255, 193 / 255, 105 / 255 },
      mid = { 169 / 255, 150 / 255, 56 / 255 },
      mdark = { 127 / 255, 109 / 255, 21 / 255 },
      dark = { 85 / 255, 70 / 255, 0 / 255 },
    },
    h105 = {
      light = { 254 / 255, 246 / 255, 169 / 255 },
      mlight = { 211 / 255, 202 / 255, 105 / 255 },
      mid = { 169 / 255, 159 / 255, 56 / 255 },
      mdark = { 127 / 255, 118 / 255, 21 / 255 },
      dark = { 85 / 255, 77 / 255, 0 / 255 },
    },
    h120 = { -- Yellow
      light = { 254 / 255, 254 / 255, 169 / 255 },
      mlight = { 211 / 255, 211 / 255, 105 / 255 },
      mid = { 169 / 255, 169 / 255, 56 / 255 },
      mdark = { 127 / 255, 127 / 255, 21 / 255 },
      dark = { 85 / 255, 85 / 255, 0 / 255 },
    },
    h135 = {
      light = { 231 / 255, 245 / 255, 163 / 255 },
      mlight = { 186 / 255, 204 / 255, 102 / 255 },
      mid = { 145 / 255, 164 / 255, 55 / 255 },
      mdark = { 105 / 255, 123 / 255, 21 / 255 },
      dark = { 68 / 255, 82 / 255, 0 / 255 },
    },
    h150 = { -- Light Green
      light = { 211 / 255, 237 / 255, 158 / 255 },
      mlight = { 164 / 255, 197 / 255, 98 / 255 },
      mid = { 123 / 255, 158 / 255, 53 / 255 },
      mdark = { 86 / 255, 119 / 255, 20 / 255 },
      dark = { 53 / 255, 79 / 255, 0 / 255 },
    },
    h165 = {
      light = { 185 / 255, 226 / 255, 150 / 255 },
      mlight = { 136 / 255, 188 / 255, 94 / 255 },
      mid = { 96 / 255, 151 / 255, 50 / 255 },
      mdark = { 62 / 255, 113 / 255, 19 / 255 },
      dark = { 34 / 255, 75 / 255, 0 / 255 },
    },
    h180 = { -- Green
      light = { 135 / 255, 203 / 255, 135 / 255 },
      mlight = { 84 / 255, 169 / 255, 84 / 255 },
      mid = { 45 / 255, 135 / 255, 45 / 255 },
      mdark = { 17 / 255, 102 / 255, 17 / 255 },
      dark = { 0 / 255, 68 / 255, 0 / 255 },
    },
    h195 = {
      light = { 116 / 255, 174 / 255, 149 / 255 },
      mlight = { 72 / 255, 145 / 255, 114 / 255 },
      mid = { 39 / 255, 116 / 255, 83 / 255 },
      mdark = { 15 / 255, 87 / 255, 56 / 255 },
      dark = { 0 / 255, 58 / 255, 33 / 255 },
    },
    h210 = { -- Teal
      light = { 101 / 255, 152 / 255, 152 / 255 },
      mlight = { 63 / 255, 127 / 255, 127 / 255 },
      mid = { 34 / 255, 102 / 255, 102 / 255 },
      mdark = { 13 / 255, 76 / 255, 76 / 255 },
      dark = { 0 / 255, 51 / 255, 51 / 255 },
    },
    h225 = {
      light = { 112 / 255, 141 / 255, 163 / 255 },
      mlight = { 72 / 255, 108 / 255, 136 / 255 },
      mid = { 41 / 255, 79 / 255, 109 / 255 },
      mdark = { 18 / 255, 54 / 255, 82 / 255 },
      dark = { 4 / 255, 32 / 255, 54 / 255 },
    },
    h240 = { -- Blue
      light = { 119 / 255, 135 / 255, 170 / 255 },
      mlight = { 78 / 255, 97 / 255, 141 / 255 },
      mid = { 46 / 255, 66 / 255, 113 / 255 },
      mdark = { 22 / 255, 41 / 255, 85 / 255 },
      dark = { 6 / 255, 21 / 255, 57 / 255 },
    },
    h255 = {
      light = { 127 / 255, 127 / 255, 178 / 255 },
      mlight = { 85 / 255, 85 / 255, 148 / 255 },
      mid = { 51 / 255, 51 / 255, 119 / 255 },
      mdark = { 26 / 255, 26 / 255, 89 / 255 },
      dark = { 9 / 255, 9 / 255, 59 / 255 },
    },
    h270 = { -- Indigo
      light = { 135 / 255, 123 / 255, 175 / 255 },
      mlight = { 96 / 255, 81 / 255, 145 / 255 },
      mid = { 64 / 255, 48 / 255, 117 / 255 },
      mdark = { 38 / 255, 23 / 255, 87 / 255 },
      dark = { 19 / 255, 7 / 255, 58 / 255 },
    },
    h285 = {
      light = { 142 / 255, 120 / 255, 172 / 255 },
      mlight = { 106 / 255, 78 / 255, 143 / 255 },
      mid = { 75 / 255, 45 / 255, 115 / 255 },
      mdark = { 49 / 255, 21 / 255, 86 / 255 },
      dark = { 27 / 255, 5 / 255, 57 / 255 },
    },
    h300 = { -- Purple
      light = { 150 / 255, 116 / 255, 170 / 255 },
      mlight = { 117 / 255, 74 / 255, 141 / 255 },
      mid = { 88 / 255, 42 / 255, 113 / 255 },
      mdark = { 61 / 255, 18 / 255, 85 / 255 },
      dark = { 37 / 255, 3 / 255, 56 / 255 },
    },
    h315 = {
      light = { 165 / 255, 110 / 255, 165 / 255 },
      mlight = { 137 / 255, 68 / 255, 137 / 255 },
      mid = { 110 / 255, 37 / 255, 110 / 255 },
      mdark = { 83 / 255, 14 / 255, 83 / 255 },
      dark = { 55 / 255, 0 / 255, 55 / 255 },
    },
    h330 = { -- Pink
      light = { 204 / 255, 136 / 255, 174 / 255 },
      mlight = { 169 / 255, 84 / 255, 132 / 255 },
      mid = { 136 / 255, 45 / 255, 96 / 255 },
      mdark = { 102 / 255, 17 / 255, 65 / 255 },
      dark = { 68 / 255, 0 / 255, 38 / 255 },
    },
    h345 = {
      light = { 227 / 255, 151 / 255, 174 / 255 },
      mlight = { 189 / 255, 94 / 255, 123 / 255 },
      mid = { 151 / 255, 50 / 255, 81 / 255 },
      mdark = { 114 / 255, 19 / 255, 48 / 255 },
      dark = { 76 / 255, 0 / 255, 23 / 255 },
    },
  }
  h1 = 330
  if p.primary ~= nil then h1 = p.primary:match('h(%d+)') end
  c1 = hues['h' .. h1]
  if p.secondary ~= nil then
    h2 = p.secondary:match('h(%d+)')
  else
    h2 = (h1 + 210) % 360
  end
  c2 = hues['h' .. h2]
  return {
    primary = c1,
    secondary = c2,
  }
end

function pass() return nil end
