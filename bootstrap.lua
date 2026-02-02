local UILIB_URL = "https://pastebin.com/raw/SfEvdu6y"

local ok, source = pcall(function()
    if typeof(request) == "function" then
        local resp = request({ Url = UILIB_URL, Method = "GET" })
        if resp and resp.Body then
            return resp.Body
        end
    end
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

-- Tabs (copied from StealABrainrot)
local pages = {
    main = window:CreatePage({ Title = "Main", Icon = "rbxassetid://132070472411182" }),
    helper = window:CreatePage({ Title = "Helper", Icon = "rbxassetid://130200273118631" }),
    stealer = window:CreatePage({ Title = "Stealer", Icon = "rbxassetid://138531621616068" }),
    shop = window:CreatePage({ Title = "Shop", Icon = "rbxassetid://95979593371652" }),
    autoJoiner = window:CreatePage({ Title = "Auto Joiner", Icon = "rbxassetid://122626540897089" }),
    misc = window:CreatePage({ Title = "Miscellaneous", Icon = "rbxassetid://81683171903925" }),
    settings = window:CreatePage({ Title = "Settings", Icon = "rbxassetid://135452049601292" }),
}

-- Settings page using the library's built-in GUI settings section
Library:CreateGUISettingsSection({
    Page = pages.settings,
    SectionTitle = "GUI Settings",
    FileName = "ui_settings.json",
})

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
    VirtualUser = game:GetService("VirtualUser"),
}

local player = Services.Players.LocalPlayer
local state = { character = player and player.Character or nil }
state.humanoid = state.character and state.character:FindFirstChildOfClass("Humanoid") or nil

local function setCharacter(char)
    state.character = char
    state.humanoid = char and char:FindFirstChildOfClass("Humanoid") or nil
end

if player then
    player.CharacterAdded:Connect(setCharacter)
    player.CharacterRemoving:Connect(function()
        setCharacter(nil)
    end)
end

local function disconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        conn:Disconnect()
    end
end

local function notify(title, text, duration)
    if Library and typeof(Library.Notify) == "function" then
        pcall(function()
            Library:Notify({
                Title = title or "Info",
                Text = text or "",
                Duration = duration or 3,
                Type = "Info",
            })
        end)
    end
end

local function clean(str)
    return tostring(str or ""):gsub("%+", ""):gsub("^%s*(.-)%s*$", "%1")
end

local function parseMoney(value)
    if not value or value == "TBA" then
        return 0
    end
    local cleaned = clean(value):gsub(",", "")
    local number, suffix = cleaned:match("^%$?([%d%.]+)([MKBT]?)")
    number = tonumber(number)
    if not number then
        return 0
    end
    if suffix == "B" then
        return number * 1e9
    elseif suffix == "M" then
        return number * 1e6
    elseif suffix == "K" then
        return number * 1e3
    elseif suffix == "T" then
        return number * 1e12
    end
    return number
end

local function formatMoneyPerSec(value)
    if type(value) == "string" then
        return value
    end
    if type(value) ~= "number" then
        return "??/s"
    end
    local abs = math.abs(value)
    if abs >= 1e12 then
        return string.format("%.1fT/s", value / 1e12)
    elseif abs >= 1e9 then
        return string.format("%.1fB/s", value / 1e9)
    elseif abs >= 1e6 then
        return string.format("%.1fM/s", value / 1e6)
    elseif abs >= 1e3 then
        return string.format("%.1fK/s", value / 1e3)
    end
    return string.format("%d/s", value)
end

local function gen_request(checkurl)
    if typeof(request) ~= "function" then
        return nil
    end
    local ok, resp = pcall(request, { Url = checkurl, Method = "GET" })
    if ok then
        return resp
    end
    return nil
end

local function hexDecode(hex)
    if type(hex) ~= "string" then
        return nil
    end
    hex = hex:gsub("%s+", ""):gsub("[^0-9a-fA-F]", "")
    if (#hex % 2) ~= 0 then
        return nil
    end
    local out = table.create(#hex / 2)
    for i = 1, #hex, 2 do
        local byte = tonumber(string.sub(hex, i, i + 1), 16)
        if not byte then
            return nil
        end
        out[#out + 1] = string.char(byte)
    end
    return table.concat(out)
end

local function decrypt(encryptedText, key)
    local decrypted = {}
    for i = 1, #encryptedText do
        local encryptedCharCode = string.byte(encryptedText, i)
        local keyCharCode = string.byte(key, (i - 1) % #key + 1)
        local decryptedCharCode = (encryptedCharCode - keyCharCode + 256) % 256
        table.insert(decrypted, string.char(decryptedCharCode))
    end
    return table.concat(decrypted)
end

local function vectorKeyToString(vec)
    return string.format("%d,%d,%d", math.floor(vec.X + 0.5), math.floor(vec.Y + 0.5), math.floor(vec.Z + 0.5))
end

local function colorKeyFromColor3(color)
    return string.format(
        "%d,%d,%d",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

-- Plot/Base skin changer state
local plotSkinOptions = { "Normal" }
local plotSkinEntries = {}
local plotSkinSelection = "Normal"
local plotSkinCurrentBase = nil
local plotSkinBaseConns = {}
local plotSkinMonitorThread = nil
local plotSkinOriginalColors = {}
local plotSkinColorConns = {}
local plotSkinLoaded = false
local plotSkinVfxState = { clones = {}, cleanup = nil }
local plotSkinVfxFolders = { "PlotSkins", "PlotSkinsVFX", "Plot", "PlotVFX" }
local SharedVFX = nil

-- Anti-AFK
local antiAfkEnabled = false
local antiAfkThread = nil

local function getPlayerBase()
    local plots = Services.Workspace:FindFirstChild("Plots")
    if not plots then
        return nil
    end
    local fallback = nil
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local yourBase = sign and sign:FindFirstChild("YourBase")
        if yourBase then
            local isMine =
                (yourBase:IsA("BoolValue") and yourBase.Value == true)
                or (yourBase:IsA("BaseScript") and yourBase.Enabled == true)
                or yourBase.Enabled == true
            if isMine then
                return plot
            end
        end
        local ownerValue = sign
            and (sign:FindFirstChild("Owner") or sign:FindFirstChild("Player") or sign:FindFirstChild("Username"))
        if ownerValue then
            if ownerValue:IsA("ObjectValue") and ownerValue.Value == player then
                return plot
            end
            if ownerValue:IsA("StringValue") and ownerValue.Value == player.Name then
                return plot
            end
        end
        local attrOwner = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerName")
        if attrOwner and tostring(attrOwner) == player.Name then
            fallback = plot
        end
    end
    return fallback
end

-- Infinite Jump
local InfJump = { enabled = false, conn = nil, canJump = true }

function InfJump:start()
    if self.conn then
        return
    end
    self.canJump = true
    self.conn = Services.UserInputService.JumpRequest:Connect(function()
        if not self.enabled then
            return
        end
        local char = player and player.Character
        if not (char and self.canJump) then
            return
        end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if rootPart and humanoid and humanoid.Health > 0 then
            if humanoid.FloorMaterial == Enum.Material.Air then
                local currentVel = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, 50, currentVel.Z)
                self.canJump = false
                task.delay(0.1, function()
                    self.canJump = true
                end)
            end
        end
    end)
end

function InfJump:stop()
    self.enabled = false
    if self.conn then
        disconnect(self.conn)
    end
    self.conn = nil
    self.canJump = true
end

-- Grapple boost
local useItemRemote = nil
local function getUseItemRemote()
    if useItemRemote and typeof(useItemRemote.FireServer) == "function" then
        return useItemRemote
    end
    return nil
end

local GrappleBoost = {
    enabled = false,
    speed = 10,
    hookName = "Grapple Hook",
    fireStrength = 100 / 120,
    interval = 0.1,
    moveConn = nil,
    loopThread = nil,
    charConn = nil,
    healthConn = nil,
}

do
    local saved = Library and Library._GetSetting and Library:_GetSetting("grapple_boost", nil)
    if type(saved) == "table" and tonumber(saved.value) then
        GrappleBoost.speed = math.clamp(tonumber(saved.value), 1, 10)
    end
end

function GrappleBoost:getEquippedHook()
    local char = state.character
    if not char then
        return nil
    end
    return char:FindFirstChild(self.hookName)
end

function GrappleBoost:attachHealthLock(char)
    disconnect(self.healthConn)
    task.spawn(function()
        task.wait(0.1)
        if not (self.enabled and char) then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
        if not hum then
            hum = char:WaitForChild("Humanoid", 5)
        end
        if not hum then
            return
        end
        if self.healthConn then
            disconnect(self.healthConn)
        end
        self.healthConn = hum.HealthChanged:Connect(function()
            if self.enabled and self:getEquippedHook() then
                hum.Health = 100
            end
        end)
        hum.Health = 100
    end)
end

function GrappleBoost:start()
    if self.enabled then
        return
    end
    local remote = getUseItemRemote()
    if not remote then
        notify("Grapple Boost", "UseItem remote not found. Ensure Packages/Net exists.", 4)
        return
    end
    self.enabled = true
    disconnect(self.charConn)
    if player then
        self.charConn = player.CharacterAdded:Connect(function(char)
            if not self.enabled then
                return
            end
            self:attachHealthLock(char)
        end)
    end
    if state.character then
        self:attachHealthLock(state.character)
    end

    disconnect(self.moveConn)
    self.moveConn = Services.RunService.RenderStepped:Connect(function(delta)
        if not self.enabled then
            return
        end
        local char = state.character
        if not char then
            return
        end
        if not char:FindFirstChild(self.hookName) then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            char:TranslateBy(dir * self.speed * delta * 10)
        else
            char:TranslateBy(dir * delta * 10)
        end
    end)

    if self.loopThread then
        task.cancel(self.loopThread)
    end
    self.loopThread = task.spawn(function()
        while self.enabled do
            local remoteObj = getUseItemRemote()
            if remoteObj and self:getEquippedHook() then
                pcall(function()
                    remoteObj:FireServer(self.fireStrength)
                end)
            end
            task.wait(self.interval)
        end
    end)
end

function GrappleBoost:stop()
    self.enabled = false
    disconnect(self.moveConn)
    disconnect(self.charConn)
    disconnect(self.healthConn)
    self.moveConn = nil
    self.charConn = nil
    self.healthConn = nil
    if self.loopThread then
        task.cancel(self.loopThread)
    end
    self.loopThread = nil
end

function GrappleBoost:setSpeed(value)
    if type(value) == "number" then
        self.speed = value
    end
end

-- Plot/Base skin helpers
local function loadPlotSkinOptions()
    if plotSkinLoaded then
        return true
    end
    local ok, indexModule = pcall(function()
        return require(Services.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Index"))
    end)
    if not ok or type(indexModule) ~= "table" then
        warn("Eps1llon Hub: could not load plot skin definitions.", indexModule)
        return false
    end
    plotSkinLoaded = true
    table.clear(plotSkinOptions)
    table.insert(plotSkinOptions, "Normal")
    table.clear(plotSkinEntries)
    local discovered = {}
    for name, entry in pairs(indexModule) do
        if type(entry) == "table" and type(entry.BaseColors) == "table" then
            local parsed = { colorMap = {}, nameMap = {}, paletteColors = {}, mainColor = nil }
            for key, color in pairs(entry.BaseColors) do
                if typeof(color) == "Color3" then
                    if typeof(key) == "Vector3" then
                        parsed.colorMap[vectorKeyToString(key)] = color
                    elseif type(key) == "string" then
                        parsed.nameMap[key:lower()] = color
                    end
                end
            end
            if type(entry.Palettes) == "table" then
                for _, palette in ipairs(entry.Palettes) do
                    if type(palette) == "table" then
                        for _, paletteColor in ipairs(palette) do
                            if typeof(paletteColor) == "Color3" then
                                table.insert(parsed.paletteColors, paletteColor)
                            end
                        end
                    end
                end
            end
            if typeof(entry.MainColor) == "Color3" then
                parsed.mainColor = entry.MainColor
            elseif #parsed.paletteColors > 0 then
                parsed.mainColor = parsed.paletteColors[1]
            end
            if next(parsed.colorMap) or next(parsed.nameMap) or parsed.mainColor or (#parsed.paletteColors > 0) then
                plotSkinEntries[name] = parsed
                table.insert(discovered, name)
            end
        end
    end
    table.sort(discovered)
    for _, skinName in ipairs(discovered) do
        table.insert(plotSkinOptions, skinName)
    end
    return true
end

local function cleanupPlotSkinVfx()
    if plotSkinVfxState.cleanup then
        pcall(plotSkinVfxState.cleanup)
    end
    for _, inst in ipairs(plotSkinVfxState.clones or {}) do
        if inst and inst.Destroy then
            pcall(inst.Destroy, inst)
        end
    end
    plotSkinVfxState.clones = {}
    plotSkinVfxState.cleanup = nil
end

local function cleanupPlotSkinBaseConns()
    for _, conn in pairs(plotSkinBaseConns) do
        disconnect(conn)
    end
    table.clear(plotSkinBaseConns)
end

local function restoreOriginalColors(targetBase)
    for part, originalColor in pairs(plotSkinOriginalColors) do
        if not part or not part.Parent then
            plotSkinOriginalColors[part] = nil
        elseif (not targetBase or part:IsDescendantOf(targetBase)) then
            if plotSkinColorConns[part] then
                disconnect(plotSkinColorConns[part])
                plotSkinColorConns[part] = nil
            end
            if part.Color ~= originalColor then
                part.Color = originalColor
            end
        end
    end
end

local function trackOriginalColor(part)
    if not (part and part:IsA("BasePart")) then
        return false
    end
    if plotSkinOriginalColors[part] then
        return true
    end
    plotSkinOriginalColors[part] = part.Color
    return true
end

local function shouldSkipPlotSkinPart(part)
    if not part then
        return true
    end
    local current = part
    while current and current ~= plotSkinCurrentBase do
        local name = typeof(current.Name) == "string" and current.Name:lower() or ""
        if
            name == "animalpodiums"
            or name:find("podium")
            or name == "claim"
            or name == "collect"
            or name == "purchases"
            or name == "unlock"
            or name == "humanoidrootpart"
            or name == "humanoid"
        then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isAllowedPlotSkinPart(part)
    if not (plotSkinCurrentBase and part) then
        return false
    end
    local candidates = {
        plotSkinCurrentBase:FindFirstChild("Skin"),
        plotSkinCurrentBase:FindFirstChild("Root"),
        plotSkinCurrentBase:FindFirstChild("MainRoot"),
        plotSkinCurrentBase:FindFirstChild("Structure"),
    }
    for _, container in ipairs(candidates) do
        if container and part:IsDescendantOf(container) then
            return true
        end
    end
    return part:IsDescendantOf(plotSkinCurrentBase)
end

local function matchNamedSkinColor(part, namedMap)
    if not namedMap or not next(namedMap) then
        return nil
    end
    local current = part
    while current do
        local name = typeof(current.Name) == "string" and current.Name:lower()
        if name then
            for token, color in pairs(namedMap) do
                if token ~= "" and name:find(token, 1, true) then
                    return color
                end
            end
        end
        if current == plotSkinCurrentBase then
            break
        end
        current = current.Parent
    end
    return nil
end

local function paletteColorForPart(part, skinEntry)
    local palette = skinEntry and skinEntry.paletteColors
    if not palette or #palette == 0 then
        return skinEntry and skinEntry.mainColor or nil
    end
    local fullName = part:GetFullName()
    local hash = 0
    for i = 1, #fullName do
        hash = (hash + string.byte(fullName, i) * i) % 2147483647
    end
    local idx = (hash % #palette) + 1
    return palette[idx]
end

local function applySkinToPart(part, skinEntry)
    if shouldSkipPlotSkinPart(part) then
        return
    end
    if not isAllowedPlotSkinPart(part) then
        return
    end
    if not trackOriginalColor(part) then
        return
    end
    local originalColor = plotSkinOriginalColors[part]
    if not originalColor then
        return
    end
    local targetColor = nil
    if skinEntry then
        targetColor = skinEntry.colorMap[colorKeyFromColor3(originalColor)]
        if not targetColor then
            targetColor = matchNamedSkinColor(part, skinEntry.nameMap)
        end
        if not targetColor then
            targetColor = paletteColorForPart(part, skinEntry)
        end
    end
    if targetColor then
        if part.Color ~= targetColor then
            part.Color = targetColor
        end
        if not plotSkinColorConns[part] then
            plotSkinColorConns[part] = part:GetPropertyChangedSignal("Color"):Connect(function()
                if plotSkinSelection ~= "Normal" then
                    applySkinToPart(part, plotSkinEntries[plotSkinSelection])
                end
            end)
        end
    elseif part.Color ~= originalColor then
        part.Color = originalColor
    end
end

local function applySkinToBase(base)
    if not base then
        return
    end
    local entry = plotSkinEntries[plotSkinSelection]
    for _, desc in ipairs(base:GetDescendants()) do
        if desc:IsA("BasePart") then
            applySkinToPart(desc, entry)
        end
    end
end

local function findPlotSkinVfxTemplate(name)
    local containers = {}
    local rsVfx = Services.ReplicatedStorage:FindFirstChild("Vfx") or Services.ReplicatedStorage:FindFirstChild("VFX")
    if rsVfx then
        table.insert(containers, rsVfx)
    end
    if SharedVFX and SharedVFX.Library then
        table.insert(containers, SharedVFX.Library)
    end
    for _, container in ipairs(containers) do
        local direct = container:FindFirstChild(name)
        if direct then
            return direct
        end
        for _, folderName in ipairs(plotSkinVfxFolders) do
            local folder = container:FindFirstChild(folderName)
            if folder then
                local match = folder:FindFirstChild(name) or folder:FindFirstChild(name .. "VFX")
                if match then
                    return match
                end
            end
        end
    end
    return nil
end

local function applyPlotSkinVfx(base)
    cleanupPlotSkinVfx()
    if not base or plotSkinSelection == "Normal" then
        return
    end
    local vfxTemplate = findPlotSkinVfxTemplate(plotSkinSelection)
    if not vfxTemplate then
        return
    end
    local ok, cf = pcall(base.GetBoundingBox, base)
    local targetCFrame = ok and cf or nil
    local attachPart = (base:IsA("Model") and base.PrimaryPart) or base:FindFirstChildWhichIsA("BasePart")
    local function cloneAndAttach(item)
        local clone = item:Clone()
        table.insert(plotSkinVfxState.clones, clone)
        if clone:IsA("Attachment") then
            if not attachPart then
                local root = base:FindFirstChildWhichIsA("BasePart")
                attachPart = root
            end
            clone.Parent = attachPart
        elseif clone:IsA("Model") or clone:IsA("Folder") then
            if targetCFrame then
                clone:PivotTo(targetCFrame)
            end
            clone.Parent = base
        elseif clone:IsA("PVInstance") then
            if targetCFrame then
                clone:PivotTo(targetCFrame)
            end
            clone.Parent = base
        else
            clone.Parent = base
        end
    end
    if vfxTemplate:IsA("Folder") then
        for _, child in ipairs(vfxTemplate:GetChildren()) do
            cloneAndAttach(child)
        end
    else
        cloneAndAttach(vfxTemplate)
    end
end

local function detachPlotSkinBase(restoreParts)
    if plotSkinCurrentBase and restoreParts then
        restoreOriginalColors(plotSkinCurrentBase)
    end
    cleanupPlotSkinBaseConns()
    for part, conn in pairs(plotSkinColorConns) do
        disconnect(conn)
        plotSkinColorConns[part] = nil
    end
    cleanupPlotSkinVfx()
    plotSkinCurrentBase = nil
end

local function attachPlotSkinBase(base)
    if not base or plotSkinSelection == "Normal" then
        detachPlotSkinBase(plotSkinSelection == "Normal")
        return
    end
    if plotSkinCurrentBase ~= base then
        detachPlotSkinBase(false)
        plotSkinCurrentBase = base
        plotSkinBaseConns.descAdded = base.DescendantAdded:Connect(function(obj)
            if plotSkinSelection ~= "Normal" and obj:IsA("BasePart") then
                applySkinToPart(obj, plotSkinEntries[plotSkinSelection])
            end
        end)
        plotSkinBaseConns.descRemoving = base.DescendantRemoving:Connect(function(obj)
            if obj:IsA("BasePart") then
                local conn = plotSkinColorConns[obj]
                if conn then
                    disconnect(conn)
                    plotSkinColorConns[obj] = nil
                end
                plotSkinOriginalColors[obj] = nil
                applySkinToPart(obj, nil)
            end
        end)
        plotSkinBaseConns.ancestry = base.AncestryChanged:Connect(function(_, parent)
            if not parent then
                detachPlotSkinBase(false)
            end
        end)
    end
    applySkinToBase(base)
    applyPlotSkinVfx(base)
end

local function monitorPlayerBase()
    if plotSkinMonitorThread then
        return
    end
    plotSkinMonitorThread = task.spawn(function()
        while plotSkinSelection ~= "Normal" do
            local base = getPlayerBase()
            if base then
                attachPlotSkinBase(base)
            else
                detachPlotSkinBase(false)
            end
            task.wait(1)
        end
        detachPlotSkinBase(true)
        cleanupPlotSkinVfx()
        plotSkinMonitorThread = nil
    end)
end

local function setPlotSkinSelection(selection)
    if not selection or selection == "" then
        selection = "Normal"
    end
    loadPlotSkinOptions()
    if selection ~= "Normal" and not plotSkinEntries[selection] then
        selection = "Normal"
    end
    plotSkinSelection = selection
    if selection == "Normal" then
        detachPlotSkinBase(true)
        return
    end
    attachPlotSkinBase(getPlayerBase())
    monitorPlayerBase()
end

local function startAntiAfk()
    if antiAfkThread then
        return
    end
    antiAfkEnabled = true
    antiAfkThread = task.spawn(function()
        while antiAfkEnabled do
            pcall(function()
                if Services.VirtualUser then
                    Services.VirtualUser:CaptureController()
                    Services.VirtualUser:ClickButton2(Vector2.new())
                end
            end)
            task.wait(60)
        end
    end)
end

local function stopAntiAfk()
    antiAfkEnabled = false
    if antiAfkThread then
        task.cancel(antiAfkThread)
    end
    antiAfkThread = nil
end

-- Sections (Main / Shop / Misc)
local sections = {
    character = pages.main:CreateSection({
        Title = "Character",
        Icon = "rbxassetid://132944044601566",
        HelpText = "Modify your character's movement abilities like speed and jump height.",
    }),
    autoBrainrot = pages.shop:CreateSection({
        Title = "Auto Brainrot Purchase",
        Icon = "rbxassetid://88521808497905",
        HelpText = "This feature is coming soon.",
    }),
    itemPurchase = pages.shop:CreateSection({
        Title = "Item Purchase",
        Icon = "rbxassetid://113665504429833",
        HelpText = "Automatically purchases selected items from the in-game shop.",
    }),
    server = pages.misc:CreateSection({
        Title = "Server",
        Icon = "rbxassetid://116427573380481",
        HelpText = "Utilities for managing and changing game servers.",
    }),
    graphics = pages.misc:CreateSection({
        Title = "Graphics",
        Icon = "rbxassetid://138347320198139",
        HelpText = "Enhance visual quality or improve performance by adjusting graphics settings.",
    }),
    world = pages.misc:CreateSection({
        Title = "World",
        Icon = "rbxassetid://119605181458611",
        HelpText = "General world modifications, like preventing AFK kicks.",
    }),
}

-- Shop items
local shopItems = {
    "Trap",
    "Speed Coil",
    "Iron Slap",
    "Gravity Coil",
    "Bee Launcher",
    "Gold Slap",
    "Coil Combo",
    "Rage Table",
    "Diamond Slap",
    "Grapple Hook",
    "Taser Gun",
    "Emerald Slap",
    "Invisibility Cloak",
    "Boogie Bomb",
    "Ruby Slap",
    "Medusa's Head",
    "Dark Matter Slap",
    "Flame Slap",
    "Quantum Cloner",
    "All Seeing Sentry",
    "Nuclear Slap",
    "Rainbowrath Sword",
    "Galaxy Slap",
    "Laser Cape",
    "Glitched Slap",
    "Body Swap Potion",
    "Splatter Slap",
    "Paintball Gun",
    "Heart Balloon",
    "Magnet",
    "BeeHive",
    "Gummy Bear",
    "Subspace Mine",
    "Heatseeker",
    "Attack Doge",
}

local purchaseRemote = nil
local sortRemote = nil

local function purchaseItem(selectedItem)
    if not selectedItem or selectedItem == "" then
        return
    end
    if not (purchaseRemote and sortRemote) then
        notify("Shop", "Purchase disabled: remotes not configured.", 4)
        return
    end
    local success = purchaseRemote:InvokeServer(selectedItem)
    if success == true then
        sortRemote:FireServer(selectedItem, 18)
        notify("Shop", "Successfully purchased: " .. selectedItem, 3)
    else
        notify("Shop", "Purchase failed. Check your coins.", 4)
    end
end

if sections.itemPurchase then
    sections.itemPurchase:CreateDropdown({
        Title = "Select Item to Purchase",
        Items = shopItems,
        Callback = purchaseItem,
    })
end

if sections.character then
    sections.character:CreateToggle({
        Title = "Infinite Jump",
        Default = false,
        SaveKey = "inf_jump_enabled",
        Callback = function(value)
            InfJump.enabled = value and true or false
            if value then
                InfJump:start()
            else
                InfJump:stop()
            end
        end,
    })
    local grappleSliderToggle = sections.character:CreateSliderToggle({
        Title = "Grapple Boost",
        Min = 1,
        Max = 10,
        Default = GrappleBoost.speed,
        DefaultToggle = false,
        Decimals = 1,
        SaveKey = "grapple_boost",
        Callback = function(value, toggled)
            local wasEnabled = GrappleBoost.enabled
            GrappleBoost:setSpeed(value)
            if toggled then
                GrappleBoost:start()
                if not wasEnabled then
                    notify("Grapple Boost", "Auto-fire + movement boost while Grapple Hook is equipped.", 3)
                end
            else
                if wasEnabled then
                    GrappleBoost:stop()
                    notify("Grapple Boost", "Disabled.", 2)
                end
            end
        end,
    })
    if grappleSliderToggle and grappleSliderToggle.GetSliderValue then
        GrappleBoost:setSpeed(grappleSliderToggle:GetSliderValue())
    end
    if grappleSliderToggle and grappleSliderToggle.GetToggleState and grappleSliderToggle:GetToggleState() then
        GrappleBoost:start()
    end
end

-- Server tools (Misc)
local serverSection = sections.server
if serverSection then
    local serverHopToggle = serverSection:CreateToggle({
        Title = "Server Hop",
        Default = false,
        Callback = function(value)
            if value then
                notify("Server Hop", "Finding a new server...", 2)
                task.delay(0.5, function()
                    Services.TeleportService:Teleport(game.PlaceId, player)
                end)
                task.delay(1, function()
                    pcall(function()
                        if serverHopToggle and serverHopToggle.SetState then
                            serverHopToggle:SetState(false)
                        end
                    end)
                end)
            end
        end,
    })

    local jobIdInput = serverSection.CreateInputBox and serverSection:CreateInputBox({
        Title = "Join Job ID",
        Placeholder = "Paste Job ID here...",
        Default = "",
        Callback = function(_) end,
    })

    serverSection:CreateButton({
        Title = "Join by ID",
        Callback = function()
            local jobId = jobIdInput and jobIdInput.GetText and jobIdInput:GetText() or ""
            if jobId and jobId ~= "" then
                notify("Teleport", "Attempting to join instance: " .. jobId, 3)
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
            else
                notify("Error", "Job ID cannot be empty.", 3)
            end
        end,
    })

    serverSection:CreateButton({
        Title = "Copy Job ID",
        Callback = function()
            if typeof(setclipboard) == "function" then
                setclipboard(game.JobId)
                notify("Clipboard", "Current Job ID copied!", 3)
            else
                notify("Error", "Could not copy to clipboard.", 3)
            end
        end,
    })
end

-- Bases & Anti-AFK (World)
local skinAfkSection = sections.world
if skinAfkSection then
    loadPlotSkinOptions()
    skinAfkSection:CreateDropdown({
        Title = "Plot Skin Changer",
        Items = plotSkinOptions,
        SaveKey = "plot_skin_selection",
        Callback = function(selection)
            setPlotSkinSelection(selection)
        end,
    })
    local savedSkin = nil
    if Library and Library._GetSetting then
        savedSkin = Library:_GetSetting("plot_skin_selection", nil)
    end
    if savedSkin and savedSkin ~= "Normal" then
        setPlotSkinSelection(savedSkin)
    end

    skinAfkSection:CreateToggle({
        Title = "Anti-AFK",
        Default = false,
        SaveKey = "anti_afk_enabled",
        Callback = function(value)
            if value then
                startAntiAfk()
                notify("Anti-AFK", "Virtual input running to prevent idle kicks.", 3)
            else
                stopAntiAfk()
                notify("Anti-AFK", "Disabled.", 2)
            end
        end,
    })
end

-- Auto Joiner logic
local autoJoinerActive = false
local autoJoinerThread = nil
local joinedServers = {}
local autoJoiner_moneyFilterEnabled = false
local autoJoiner_minMoney = 0
local PREM_BACKEND_URL = "https://backend-for-premium-joiner-production.up.railway.app/brainrots"
local DECRYPTION_KEY = "A7q#zP!t8*K$vB2@cM5nF&hW9gL^eR4u"

local function fetchPremiumServers()
    local success, servers = pcall(function()
        local response = gen_request(PREM_BACKEND_URL)
        if response and response.StatusCode == 200 then
            local answer = Services.HttpService:JSONDecode(response.Body)
            if type(answer) == "table" then
                if answer.payload then
                    local hex = hexDecode(answer.payload)
                    if hex then
                        local decoded = decrypt(hex, DECRYPTION_KEY)
                        if decoded then
                            local okList, list = pcall(Services.HttpService.JSONDecode, Services.HttpService, decoded)
                            if okList and type(list) == "table" then
                                return list
                            end
                        end
                    end
                elseif answer[1] then
                    return answer
                end
            end
        end
        return nil
    end)
    if success and type(servers) == "table" then
        return servers
    else
        warn("Eps1llon Hub (Auto Joiner): Failed to fetch or decrypt premium server list.", servers)
        return nil
    end
end

local function autoJoinerLoop()
    while autoJoinerActive do
        local servers = fetchPremiumServers()
        if servers and #servers > 0 then
            for _, serverData in ipairs(servers) do
                local job_id = clean(serverData.jobId or serverData.instanceId)
                if job_id and job_id ~= "" and not joinedServers[job_id] then
                    local shouldJoin = true
                    if autoJoiner_moneyFilterEnabled then
                        local serverMoney = parseMoney(serverData.moneyPerSec)
                        if serverMoney < autoJoiner_minMoney then
                            shouldJoin = false
                        end
                    end
                    if shouldJoin then
                        local money_value = parseMoney(serverData.moneyPerSec)
                        local prettyMoney = formatMoneyPerSec(money_value ~= 0 and money_value or serverData.moneyPerSec)
                        local serverName = serverData.name or (serverData.serverId or "Unknown")
                        notify("Auto Joiner", string.format("Joining %s (%s)", serverName, prettyMoney or "??/s"), 3)
                        joinedServers[job_id] = true
                        local place_id = (money_value and money_value >= 10000000)
                                and 109983668079237
                            or tonumber(serverData.serverId)
                        if place_id then
                            pcall(
                                Services.TeleportService.TeleportToPlaceInstance,
                                Services.TeleportService,
                                place_id,
                                job_id,
                                player
                            )
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end

local finderSection = pages.autoJoiner:CreateSection({
    Title = "Finder",
    Icon = "rbxassetid://110882457725395",
    HelpText = "Automatically finds and joins premium servers with valuable items.",
})

finderSection:CreateToggle({
    Title = "Auto Join Premium Servers",
    Default = false,
    Callback = function(value)
        autoJoinerActive = value
        if value then
            if not autoJoinerThread then
                notify("Auto Joiner", "Started searching for new premium servers.", 3)
                joinedServers = {}
                autoJoinerThread = task.spawn(autoJoinerLoop)
            end
        else
            if autoJoinerThread then
                task.cancel(autoJoinerThread)
                autoJoinerThread = nil
                notify("Auto Joiner", "Stopped searching.", 3)
            end
        end
    end,
})

finderSection:CreateToggle({
    Title = "Server Location",
    Default = false,
    Callback = function()
        -- placeholder
    end,
})

finderSection:CreateDropdown({
    Title = "Auto Joiner Server Location",
    Items = { "US, Chicago", "RU, Moscow", "EU, Germany" },
    Callback = function()
        -- placeholder
    end,
})

finderSection:CreateToggle({
    Title = "Money Per Sec Filter",
    Default = false,
    Callback = function(value)
        autoJoiner_moneyFilterEnabled = value
    end,
})

finderSection:CreateDropdown({
    Title = "Minimum Money Per Second",
    Items = { "10m/s", "15m/s", "20m/s", "25m/s", "30m/s", "35m/s", "40m/s", "45m/s", "50m/s" },
    Callback = function(selectedValue)
        local num = selectedValue and selectedValue:match("(%d+)m/s")
        if num then
            autoJoiner_minMoney = tonumber(num) * 1e6
        end
    end,
})

InfJump:start()

return window
