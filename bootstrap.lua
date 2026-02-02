local UILIB_URL = "https://pastebin.com/raw/SfEvdu6y"

local ok, source = pcall(function()
    return game:HttpGet(UILIB_URL)
end)
if not ok or typeof(source) ~= "string" then
    warn("UI library fetch failed")
    return
end

local loadOk, factory = pcall(loadstring, source)
if not loadOk or typeof(factory) ~= "function" then
    warn("UI library load failed")
    return
end

local Library = factory()
if typeof(Library) ~= "table" or typeof(Library.CreateWindow) ~= "function" then
    warn("UI library init failed")
    return
end

local window = Library:CreateWindow("Eps1llon Hub | Steal A Brainrot", "Steal A Brainrot Premium")

-- Main page placeholder
window:CreatePage({ Title = "Main" })

-- Settings page using the library's built-in GUI settings section
local settingsPage = window:CreatePage({ Title = "Settings" })
Library:CreateGUISettingsSection({
    Page = settingsPage,
    SectionTitle = "GUI Settings",
    FileName = "ui_settings.json",
})

return window
