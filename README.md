local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "ScriptX made by Juan1522", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})

Tab:AddButton({
	Name = "Assy",
	Callback = function()
      		print("button pressed")
  	end    
})

OrionLib:Init()
