moduleVersion = 0.02
pID = "_Wulfy_Widgets"

--Wulfy Widgets by @wulfygrl
--built around the Encoder by Tipsy Hobbit (steam_id: 13465982)
--based on the functions from TyrantNomad's Easy Modules Unified by @TyrantNomad
--(but almost entirely rewritten)

isRegistered = false

githubSource = "https://raw.githubusercontent.com/wulfygrl/wulfys-widgets-mtg-tts/main/wulfyWidgets.lua"

function onload(saved_data)
  createChipButtons()
end

function selfUpdateCheck()
  WebRequest.get(githubSource, selfUpdate)
end

function selfUpdate(webRequest)
  local gitVersion = tonumber(webRequest.text:match('moduleVersion%s=%s(%d+%.%d+)'))
  if gitVersion ~= nil and gitVersion > moduleVersion then
    self.script_code = webRequest.text
    self.reload()
  end
end

function createChipButtons()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then
    isRegistered = enc.call("APIpropertyExists", {propID = pID})
  else
    isRegistered = false
  end
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
  -- Register toggle button
  self.createButton({
    label=(isRegistered and "Unregister" or "Register"),
    click_function=(isRegistered and "unRegisterModule" or "registerModule"),
    function_owner=self,
    position={0,0.15,0.55},
    rotation = {0,0,0},
    color = (isRegistered and {238/255, 25/255, 110/255} or {1,156/255,196/255}),
    hover_color = {90/255,24/255,51/255},
    font_color = (isRegistered and {1,156/255,196/255} or {90/255,24/255,51/255}),
    font_size = 60,
    height=60,
    width=425,
  })
end

function clearChipButtons()
  local chipButtons = self.getButtons()
  for i,btn in pairs(chipButtons) do
    self.removeButton(i-1)
  end
end
function refreshChipButtons()
  clearChipButtons()
  createChipButtons()
end

function registerModule()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then 
    local properties
    properties = {
      propID = pID,
      name = "Wulfys Widgets",
      values = {"wulfyWidgets"},
      funcOwner = self,
      tags = "basic,counter",
      visible = false,
      visible_in_hand=0,
      activateFunc = 'ModuleActivation'
    }
    enc.call("APIregisterProperty", properties)
    local value = {
      valueID = 'wulfyWidgets',
      validType = 'nil',
      desc = 'Data for wulfy widgets module',
      default = {},
    }
    enc.call("APIregisterValue", value)
    refreshChipButtons()
  else 
    broadcastToAll("No encoder found") 
  end
end

function unRegisterModule()
  local enc = Global.getVar('Encoder')
  if enc ~= nil then
    isRegistered = enc.call("APIpropertyExists", {propID = pID})
    if isRegistered then
      enc.call("APIremoveProperty", {propID = pID})
    end
  else
    broadcastToAll("No encoder found")
  end
  refreshChipButtons()
end

function DoNothing()
end
