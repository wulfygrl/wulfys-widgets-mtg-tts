moduleVersion = 0.01
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
  self.createButton({
    click_function="DoNothing",
    function_owner=self,
    position={0,0.15,-0.25},
    rotation={180,0,0},
    height= 240,
    width= 525,
    color = {90/255,24/255,51/255}
  })
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
  self.createButton({
    label="Update",
    click_function="selfUpdateCheck",
    function_owner=self,
    position={0,0.15,0.33},
    color = {238/255, 25/255, 110/255},
    hover_color = {90/255,24/255,51/255},
    height=60,
    width=450,
  })
end
  
function DoNothing()
end
