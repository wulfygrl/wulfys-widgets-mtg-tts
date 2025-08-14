moduleVersion = 0.03
pID = "w_importer"
-- Wulfy Importer by @wulfygrl
-- Built for use with the Encoder by Tipsy Hobbit (steam_id: 13465982)
--   (but will work to import cards without it)
-- Necessary for supporting my Wulfy Widgets modules.

MOD_DATA = {
  modVersion = moduleVersion,
  modID = pID,
  modName = 'Wulfy Importer',
  gitFileName = 'wulfyImporter.lua',
  colors = {
    init = {
      primary = 'h195',
      secondary = 'h30'
    }
  },
}
ENC_DATA = {
  pID = pID
}
-- [[ UNIVERSAL ]] --
-- retrieve the utils module
function utils() return Global.getVar('wulfy_utils') end

-- Wrap json.lua object
function json()
  return {
    decode = function(s) return utils().call('jsonDecode',{str=s}) end,
    encode = function(o) return utils().call('jsonEncode',{obj=o}) end
  }
end

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

function onLoad(save_data)
  s = JSON.decode(save_data)
  local function init() initMod(s) end
  local function utilsExists()
    return (utils() or (s.utilsGUID and getObjectFromGUID(s.utilsGUID))) ~= nil
  end
  local function utilsSpawned() return utils() ~= nil end
  local function spawnUtils()
    giturl = 'https://raw.githubusercontent.com/wulfygrl/wulfys-widgets-mtg-tts/refs/heads/main/wulfyUtils.lua'
    WebRequest.get(giturl, function(wr)
      if wr.is_error then
        log('Failed to fetch utils. wulfy mods will not function.', '', 'error')
        return
      end
      local utils_data = self.getData()
      utils_data.Nickname = 'Wulfy Utils'
      utils_data.Description = 'wulfy_utils'
      utils_data.LuaScript = wr.text
      utils_data.LuaScriptState = ''
      spawnObjectData({
        data = utils_data,
        position = self.getPosition() + Vector(1, 0, 0),
        callback_function = init
      })
    end)
  end
  -- if this is utils obj or we already have utils, skip to init.
  if pID == 'w_utils' or utilsSpawned() then
    init()
  elseif not utilsExists() then
    spawnUtils()
  else
    Wait.condition(init, utilsSpawned, 2, spawnUtils)
  end
end

function onSave()
  save_data = (saveMod ~= nil and saveMod() or {})
  if utils() ~= nil then save_data.utilsGUID = utils().getGUID() end
  return JSON.encode(save_data)
end

-- [[ END UNIVERSAL ]]--

function initMod(s)
  chipButtons()
end
