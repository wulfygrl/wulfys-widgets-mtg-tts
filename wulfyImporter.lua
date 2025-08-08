moduleVersion = 0.02
pID = "w_importer"
modName = "Wulfy Importer"
-- Wulfy Importer by @wulfygrl
-- Built for use with the Encoder by Tipsy Hobbit (steam_id: 13465982)
--   (but will work to import cards without it)
-- Necessary for supporting my Wulfy Widgets modules.

--[[ Initialize constants ]]--

GITHUB_SOURCE = 'https://raw.githubusercontent.com/wulfygrl/wulfys-widgets-mtg-tts/main/wulfyImporter.lua'
COLORS = {
  dark={0, 59/255, 32/255},
  mdark={15/255, 88/255, 55/255},
  mid={39/255, 117/255, 82/255},
  mlight={73/255, 147/255, 113/255},
  light={117/255,176/255,149/255}
}
--Initialize ENCDATA, add to it later with table.insert
ENCDATA = {
  properties={},
  values={}
}

--[[ Helper Functions ]]--

-- Noop function for display buttons 
function pass() return nil end
-- Log wrapper for colors
logStyle(pID, COLORS.mlight, "", "")
function wLog(msg, pre, tags)
  tags = tags or pID 
  log(msg, pre, tags)
end

--[[ Module Setup ]]--

function onLoad(saved_data)
  chipButtons()
end
-- Checks for newer version on Github and applies if found.
function selfUpdate()
  wLog(modName .. " update check. Current: ".. moduleVersion)
  WebRequest.get(GITHUB_SOURCE, function(wr)
    if wr.is_error then
      wLog('Error fetching code from GitHub:\n'..wr.error, '', 'error')
      return
    end
    local gitVersion = tonumber(wr.text:match('moduleVersion%s=%s(%d+%.%d+)'))
    if gitVersion == nil then 
      wLog('Couldn\'t parse git version.','','error') 
      return 
    end
    wLog("Git version = "..gitVersion)
    if gitVersion > moduleVersion then
      self.script_code = wr.text
      wLog("Reloading "..modName)
      self.reload()
    end
  end)
end
-- Redraws buttons on module chip
function chipButtons()
  self.clearButtons()
  self.createButton({ -- Title Background
    click_function="pass",
    function_owner=self,
    position={0,0.15,-0.25},
    rotation={180,0,0},
    height=240,
    width=525,
    color=COLORS.dark
  })
  self.createButton({ -- Title
    label= modName:gsub(' ','\n'),
    click_function="pass",
    function_owner=self,
    position={0,0.15,-0.25},
    height= 0,
    width= 0,
    color = COLORS.dark,
    font_size = 100,
    font_color = COLORS.light
  })
  self.createButton({ -- Version info
    label = "VERSION "..moduleVersion,
    click_function="pass",
    function_owner=self,
    position={0,0.15,0.075},
    rotation = {0,0,0},
    height=0,
    width=0,
    font_size = 60,
    font_color = COLORS.dark
  })
  self.createButton({ -- Update Button
    label="Update",
    click_function="selfUpdate",
    function_owner=self,
    position={0,0.15,0.27},
    color=COLORS.mid,
    hover_color=COLORS.mdark,
    font_color=COLORS.dark,
    height=60,
    width=450,
  })
  self.createButton({ -- Register Toggle Button
    label=(isRegistered and 'Unr' or 'R')..'egister',
    click_function=(isRegistered and 'unR' or 'r')..'egisterModule',
    function_owner=self,
    position={0,0.15,0.55},
    rotation = {0,0,0},
    color = (isRegistered and COLORS.mid or COLORS.light),
    hover_color = (isRegistered and COLORS.mlight or COLORS.mdark),
    font_color = (isRegistered and COLORS.light or COLORS.dark),
    font_size = 60,
    height=60,
    width=425,
  })
end
-- Registers module with Encoder, or skips if none found.
function registerModule()
  local enc = Global.getVar('Encoder')
  if enc == nil then wLog('No encoder found.') return end
  for i,prop in ipairs(ENCDATA.properties) do repeat
    if enc.call('APIpropertyExists', prop) then break end
    enc.call('APIregisterProperty', prop)
  until true end
  for i,val in ipairs(ENCDATA.values) do repeat
    if enc.call('APIvalueExists', val) then break end
    enc.call('APIregisterValue', val)
  until true end
  isRegistered = true
  chipButtons()
end
-- Removes registered properties from Encoder.
function unRegisterModule()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then 
    for i,prop in ipairs(ENCDATA.properties) do 
      if enc.call('APIpropertyExists', prop) then 
        enc.call('APIremoveProperty', prop)
      end
    end
  end
  isRegistered = false
  chipButtons()
end

--[[ End module setup functions ]]--

