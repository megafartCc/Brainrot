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

local THEME = Library.Theme or {}
local DEFAULT_ACCENT = THEME.accent or Color3.fromRGB(50, 130, 250)
THEME.accentA = THEME.accentA or DEFAULT_ACCENT
THEME.accentB = THEME.accentB or Color3.fromRGB(0, 204, 204)
THEME.panel2 = THEME.panel2 or Color3.fromRGB(22, 24, 30)
THEME.text = THEME.text or Color3.fromRGB(230, 235, 240)
THEME.gold = THEME.gold or Color3.fromRGB(255, 215, 0)

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
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
    PathfindingService = game:GetService("PathfindingService"),
    TweenService = game:GetService("TweenService"),
    VirtualUser = game:GetService("VirtualUser"),
}

local player = Services.Players.LocalPlayer
local state = { character = player and player.Character or nil }
state.humanoid = state.character and state.character:FindFirstChildOfClass("Humanoid") or nil

local function setCharacter(char)
    state.character = char
    state.humanoid = char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function getHRP()
    local char = state.character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
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

local function toTitleCase(text)
    if type(text) ~= "string" then
        return ""
    end
    return text:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
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

local function getAttrNumber(inst, keys)
    if not inst then
        return nil
    end
    for _, key in ipairs(keys) do
        local a = inst:GetAttribute(key)
        if a ~= nil then
            local n = tonumber(a)
            if n then
                return n
            end
        end
        local child = inst:FindFirstChild(key)
        if child and child.Value ~= nil then
            local n = tonumber(child.Value)
            if n then
                return n
            end
        end
    end
    return nil
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

local useItemRemote = nil
local purchaseRemote = nil
local sortRemote = nil
local stealSuccessRemote = nil
local quantumTeleportRemote = nil
local sentryCooldownRemote = nil


local function nameHasAll(name, parts)
    for _, p in ipairs(parts) do
        if not name:find(p, 1, true) then
            return false
        end
    end
    return true
end

local function findRemote(className, predicate)
    local rs = Services.ReplicatedStorage
    local roots = {
        rs,
        rs:FindFirstChild("Packages"),
        rs:FindFirstChild("Net"),
        rs:FindFirstChild("Remotes"),
        rs:FindFirstChild("RemoteEvents"),
        rs:FindFirstChild("RemoteFunctions"),
    }
    for _, root in ipairs(roots) do
        if root and root.GetDescendants then
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA(className) and predicate(inst) then
                    return inst
                end
            end
        end
    end
    return nil
end

local function resolveRemotes()
    if not (useItemRemote and useItemRemote.Parent) then
        useItemRemote = findRemote("RemoteEvent", function(inst)
            local n = inst.Name:lower()
            return n == "useitem" or n == "use_item" or nameHasAll(n, { "use", "item" })
        end)
    end
    if not (purchaseRemote and purchaseRemote.Parent) then
        purchaseRemote = findRemote("RemoteFunction", function(inst)
            local n = inst.Name:lower()
            return n:find("purchase") or n:find("buy")
        end)
    end
    if not (sortRemote and sortRemote.Parent) then
        sortRemote = findRemote("RemoteEvent", function(inst)
            local n = inst.Name:lower()
            return n:find("sort") and (n:find("item") or n:find("inventory"))
        end)
    end
    if not (stealSuccessRemote and stealSuccessRemote.Parent) then
        stealSuccessRemote = findRemote("RemoteEvent", function(inst)
            local n = inst.Name:lower()
            return n:find("steal") and (n:find("success") or n:find("stolen"))
        end)
    end
    if not (quantumTeleportRemote and quantumTeleportRemote.Parent) then
        quantumTeleportRemote = findRemote("RemoteEvent", function(inst)
            local n = inst.Name:lower()
            return (n:find("quantum") and n:find("teleport")) or (n:find("cloner") and n:find("teleport"))
        end)
    end
    if not (sentryCooldownRemote and sentryCooldownRemote.Parent) then
        sentryCooldownRemote = findRemote("RemoteEvent", function(inst)
            local n = inst.Name:lower()
            return (n:find("sentry") or n:find("turret")) and n:find("cooldown")
        end)
    end
end

resolveRemotes()
Services.ReplicatedStorage.DescendantAdded:Connect(function()
    resolveRemotes()
end)

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

local medusaNames = {
    ["medusa's head"] = true,
    ["medusa"] = true,
}
local medusaCounterEnabled = false
local medusaCounterConn = nil
local medusaToolConns = {}
local medusaPlayerConns = {}
local lastMedusaUse = 0
local lastBoogieUse = 0
local lastCounterUse = 0


local function isMedusaToolName(name)
    if not name then
        return false
    end
    local lower = name:lower()
    if medusaNames[lower] then
        return true
    end
    return lower:find('medusa') ~= nil
end

local function isBoogieName(name)
    if not name then
        return false
    end
    local lower = name:lower()
    return lower:find('boogie') ~= nil
end

local function safeDisconnectMedusa(conn)
    if conn and typeof(conn) == 'RBXScriptConnection' then
        pcall(function()
            conn:Disconnect()
        end)
    end
end

local function getMedusaTool()
    local char = state.character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA('Tool') and isMedusaToolName(item.Name) then
                return item
            end
        end
    end
    local backpack = player and player:FindFirstChildOfClass('Backpack')
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA('Tool') and isMedusaToolName(item.Name) then
                return item
            end
        end
    end
end

local function getBoogieTool()
    local char = state.character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA('Tool') and isBoogieName(item.Name) then
                return item
            end
        end
    end
    local backpack = player and player:FindFirstChildOfClass('Backpack')
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA('Tool') and isBoogieName(item.Name) then
                return item
            end
        end
    end
end

local function enemyHasMedusa(character)
    if not character then
        return false
    end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA('Tool') and isMedusaToolName(item.Name) then
            return true
        end
    end
    return false
end

local function activateMedusa(tool)
    if not tool then
        return
    end
    local now = Services.Workspace:GetServerTimeNow()
    if now - lastMedusaUse <= 1.5 then
        return
    end
    local hum = state.character and state.character:FindFirstChildOfClass('Humanoid')
    if not hum then
        return
    end
    if tool.Parent ~= state.character then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
    pcall(function()
        if type(tool.Activate) == 'function' then
            tool:Activate()
        end
    end)
    lastMedusaUse = now
    task.delay(0.35, function()
        local h = state.character and state.character:FindFirstChildOfClass('Humanoid')
        if h then
            pcall(function()
                h:UnequipTools()
            end)
        end
    end)
end

local function activateBoogie(tool)
    if not tool then
        return
    end
    local now = Services.Workspace:GetServerTimeNow()
    if now - lastBoogieUse <= 1.5 then
        return
    end
    local hum = state.character and state.character:FindFirstChildOfClass('Humanoid')
    if not hum then
        return
    end
    if tool.Parent ~= state.character then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
    pcall(function()
        if type(tool.Activate) == 'function' then
            tool:Activate()
        end
    end)
    lastBoogieUse = now
    task.delay(0.35, function()
        local h = state.character and state.character:FindFirstChildOfClass('Humanoid')
        if h then
            pcall(function()
                h:UnequipTools()
            end)
        end
    end)
end

local function useCounterTool()
    local now = Services.Workspace:GetServerTimeNow()
    if now - lastMedusaUse > 1.5 then
        local medusa = getMedusaTool()
        if medusa then
            activateMedusa(medusa)
            return true
        end
    end
    if now - lastBoogieUse > 1.5 then
        local boogie = getBoogieTool()
        if boogie then
            activateBoogie(boogie)
            return true
        end
    end
    return false
end

local function unbindMedusaTool(tool)
    if medusaToolConns[tool] then
        safeDisconnectMedusa(medusaToolConns[tool])
        medusaToolConns[tool] = nil
    end
end

local function bindMedusaTool(tool)
    if not tool or not tool:IsA('Tool') or medusaToolConns[tool] then
        return
    end
    if not isMedusaToolName(tool.Name) then
        return
    end
    local conn
    conn = tool.Activated:Connect(function()
        if not medusaCounterEnabled then
            return
        end
        local attackerRoot = tool.Parent and tool.Parent:FindFirstChild('HumanoidRootPart')
        local myHRP = getHRP()
        if not (attackerRoot and myHRP) then
            return
        end
        local dist = (attackerRoot.Position - myHRP.Position).Magnitude
        if dist <= 20 then
            useCounterTool()
        end
    end)
    medusaToolConns[tool] = conn
    tool.Destroying:Connect(function()
        unbindMedusaTool(tool)
    end)
end

local function unbindPlayerMedusa(plr)
    local list = medusaPlayerConns[plr]
    if list then
        for _, c in ipairs(list) do
            safeDisconnectMedusa(c)
        end
        medusaPlayerConns[plr] = nil
    end
end

local function bindPlayerMedusa(plr)
    if not plr or plr == player then
        return
    end
    unbindPlayerMedusa(plr)
    local conns = {}
    local function scan(char)
        if not char then
            return
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA('Tool') then
                bindMedusaTool(child)
            end
        end
        local c1 = char.ChildAdded:Connect(function(obj)
            if obj:IsA('Tool') then
                bindMedusaTool(obj)
            end
        end)
        table.insert(conns, c1)
    end
    local cChar = plr.Character or plr.CharacterAdded:Wait()
    scan(cChar)
    local c2 = plr.CharacterAdded:Connect(function(newChar)
        scan(newChar)
    end)
    table.insert(conns, c2)
    medusaPlayerConns[plr] = conns
end

local function startMedusaCounter()
    if medusaCounterConn then
        return
    end
    medusaCounterEnabled = true
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= player then
            bindPlayerMedusa(plr)
        end
    end
    medusaPlayerConns['added'] = Services.Players.PlayerAdded:Connect(bindPlayerMedusa)
    medusaCounterConn = Services.RunService.Heartbeat:Connect(function()
        if not medusaCounterEnabled then
            return
        end
        local myHRP = getHRP()
        if not myHRP then
            return
        end
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= player then
                local ch = plr.Character
                local hrp = ch and ch:FindFirstChild('HumanoidRootPart')
                if hrp and enemyHasMedusa(ch) then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist <= 5 then
                        useCounterTool()
                        break
                    end
                end
            end
        end
    end)
end

local function stopMedusaCounter()
    medusaCounterEnabled = false
    if medusaCounterConn then
        safeDisconnectMedusa(medusaCounterConn)
        medusaCounterConn = nil
    end
    if medusaPlayerConns['added'] then
        safeDisconnectMedusa(medusaPlayerConns['added'])
        medusaPlayerConns['added'] = nil
    end
    for tool, conn in pairs(medusaToolConns) do
        safeDisconnectMedusa(conn)
        medusaToolConns[tool] = nil
    end
    for plr, _ in pairs(medusaPlayerConns) do
        if plr ~= 'added' then
            unbindPlayerMedusa(plr)
        end
    end
end


-- Invisible spoof
local Invisible = {
    enabled = false,
    heartbeat = nil,
    charConn = nil,
    healthConn = nil,
    anim = nil,
    track = nil,
    animId = 'rbxassetid://112089880074848',
    posOffset = Vector3.new(0, -2.6, 0),
    rotOffset = Vector3.new(-160, 0, 0),
    playbackTime = 3.05,
}

function Invisible:loadTrack(hum)
    if not hum then
        return
    end
    if not self.anim then
        self.anim = Instance.new('Animation')
        self.anim.AnimationId = self.animId
    end
    local loader = hum:FindFirstChildOfClass('Animator') or hum
    if loader then
        self.track = loader:LoadAnimation(self.anim)
    end
end

function Invisible:cleanupTrack()
    if self.track then
        self.track:Stop()
        self.track:Destroy()
    end
    if self.anim then
        self.anim:Destroy()
    end
    self.track = nil
    self.anim = nil
end

function Invisible:attachHealthGuard(char)
    disconnect(self.healthConn)
    local hum = char and char:FindFirstChildOfClass('Humanoid')
    if not hum then
        return
    end
    self.healthConn = hum.HealthChanged:Connect(function(health)
        if self.enabled and health < 100 then
            hum.Health = 100
        end
    end)
end

function Invisible:start()
    if self.heartbeat then
        return
    end
    self.enabled = true
    self:loadTrack(state.humanoid)
    self:attachHealthGuard(state.character)

    disconnect(self.charConn)
    if player then
        self.charConn = player.CharacterAdded:Connect(function(char)
            self:attachHealthGuard(char)
            local hum = char:WaitForChild('Humanoid', 5)
            self:loadTrack(hum)
        end)
    end

    self.heartbeat = Services.RunService.Heartbeat:Connect(function()
        if not self.enabled then
            return
        end
        local char = state.character
        local hum = state.humanoid
        local hrp = getHRP()
        if not (char and hum and hrp and hum.Health > 0) then
            return
        end
        local originalCFrame = hrp.CFrame
        local originalVelocity = hrp.AssemblyLinearVelocity

        if self.track then
            self.track:Stop()
            if not self.track.Parent then
                self:loadTrack(hum)
            end
            if self.track then
                self.track:Play(0.01, 1, 0)
                self.track.TimePosition = self.playbackTime
            end
        end

        local spoofed = originalCFrame
            * CFrame.new(self.posOffset)
            * CFrame.Angles(math.rad(self.rotOffset.X), math.rad(self.rotOffset.Y), math.rad(self.rotOffset.Z))

        hrp.CFrame = spoofed
        Services.RunService.RenderStepped:Wait()
        hrp.CFrame = originalCFrame
        hrp.AssemblyLinearVelocity = originalVelocity
    end)
end

function Invisible:stop()
    self.enabled = false
    disconnect(self.heartbeat)
    disconnect(self.charConn)
    disconnect(self.healthConn)
    self.heartbeat = nil
    self.charConn = nil
    self.healthConn = nil
    self:cleanupTrack()
end

-- No animation
local NO_ANIMATION_ID = 'rbxassetid://75602578104627'
local NoAnimation = { enabled = false, charConn = nil, track = nil }

function NoAnimation:stopTrack()
    if self.track then
        self.track:Stop()
        self.track:Destroy()
    end
    self.track = nil
end

function NoAnimation:apply(hum)
    if not hum then
        return false
    end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    local anim = Instance.new('Animation')
    anim.AnimationId = NO_ANIMATION_ID
    local loader = hum:FindFirstChildOfClass('Animator') or hum
    self.track = loader:LoadAnimation(anim)
    anim:Destroy()
    if not self.track then
        return false
    end
    self.track.Priority = Enum.AnimationPriority.Action4
    self.track.Looped = true
    self.track:Play()
    return true
end

function NoAnimation:start()
    if self.enabled then
        return
    end
    self.enabled = true
    self:stopTrack()
    self:apply(state.humanoid)

    disconnect(self.charConn)
    if player then
        self.charConn = player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild('Humanoid', 5)
            if self.enabled then
                self:stopTrack()
                self:apply(hum)
            end
        end)
    end
end

function NoAnimation:stop()
    self.enabled = false
    disconnect(self.charConn)
    self.charConn = nil
    self:stopTrack()
end

-- Grappling speed boost
-- Aimbot (Web / Laser / Paintball)
local Aimbot = {
    enabled = false,
    laserEnabled = false,
    paintEnabled = false,
    toolConns = { web = {}, laser = {}, paint = {} },
    containerConns = {},
    charAddedConn = nil,
    lastUse = { web = 0, laser = 0, paint = 0 },
    fovRadius = 200,
    fovCircle = nil,
    fovConn = nil,
    fovGui = nil,
    fovFrame = nil,
    fovTextDrawing = nil,
    fovTextLabel = nil,
    currentTargetName = 'None',
    targetUpdateConn = nil,
    lastLabelUpdate = 0,
    touchMode = false,
}

local function getUseItemRemote()
    resolveRemotes()
    if useItemRemote and typeof(useItemRemote.FireServer) == 'function' then
        return useItemRemote
    end
    return nil
end

function Aimbot:useFovMode()
    return not Services.UserInputService.TouchEnabled
end

function Aimbot:destroyFovCircle()
    if self.fovConn then
        disconnect(self.fovConn)
        self.fovConn = nil
    end
    if self.targetUpdateConn then
        disconnect(self.targetUpdateConn)
        self.targetUpdateConn = nil
    end
    if self.fovTextDrawing then
        pcall(function()
            if self.fovTextDrawing.Remove then
                self.fovTextDrawing:Remove()
            else
                self.fovTextDrawing:Destroy()
            end
        end)
        self.fovTextDrawing = nil
    end
    if self.fovTextLabel then
        pcall(function()
            self.fovTextLabel:Destroy()
        end)
        self.fovTextLabel = nil
    end
    if self.fovFrame then
        pcall(function()
            self.fovFrame:Destroy()
        end)
        self.fovFrame = nil
    end
    if self.fovCircle then
        pcall(function()
            if self.fovCircle.Remove then
                self.fovCircle:Remove()
            else
                self.fovCircle:Destroy()
            end
        end)
        self.fovCircle = nil
    end
    if self.fovGui then
        pcall(function()
            self.fovGui:Destroy()
        end)
        self.fovGui = nil
    end
end

function Aimbot:createFovCircle()
    self:destroyFovCircle()
    if not self:useFovMode() then
        return
    end
    local radius = self.fovRadius or 200
    if Drawing and typeof(Drawing.new) == 'function' then
        local ok, circle = pcall(Drawing.new, 'Circle')
        if ok and circle then
            circle.Filled = false
            circle.NumSides = 64
            circle.Thickness = 1.5
            circle.Transparency = 0.4
            circle.Color = Color3.fromRGB(120, 180, 255)
            circle.Radius = radius
            self.fovCircle = circle
            local textOk, textObj = pcall(Drawing.new, 'Text')
            if textOk and textObj then
                textObj.Center = true
                textObj.Outline = true
                textObj.Size = 16
                textObj.Transparency = 0.9
                textObj.Color = circle.Color
                textObj.Text = 'Target: ' .. (self.currentTargetName or 'None')
                self.fovTextDrawing = textObj
            end
            self.fovConn = Services.RunService.RenderStepped:Connect(function()
                if not (self.enabled and self.fovCircle) then
                    return
                end
                local cam = Services.Workspace.CurrentCamera
                if not cam then
                    self.fovCircle.Visible = false
                    if self.fovTextDrawing then
                        self.fovTextDrawing.Visible = false
                    end
                    return
                end
                local mousePos = Services.UserInputService:GetMouseLocation()
                self.fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
                self.fovCircle.Radius = radius
                self.fovCircle.Visible = true
                if self.fovTextDrawing then
                    self.fovTextDrawing.Position = Vector2.new(mousePos.X, mousePos.Y + radius + 12)
                    self.fovTextDrawing.Text = 'Target: ' .. (self.currentTargetName or 'None')
                    self.fovTextDrawing.Visible = true
                end
            end)
            return
        end
    end

    -- Fallback UI circle
    local gui = Instance.new('ScreenGui')
    gui.Name = 'AimbotFOV'
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    local parent = game:GetService('CoreGui')
    local okParent, holder = pcall(gethui)
    if okParent and holder then
        gui.Parent = holder
    else
        gui.Parent = parent
    end
    local frame = Instance.new('Frame')
    frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = gui
    self.fovFrame = frame
    local label = Instance.new('TextLabel')
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 1, 6)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(120, 180, 255)
    label.TextStrokeTransparency = 0.1
    label.Text = 'Target: ' .. (self.currentTargetName or 'None')
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.Parent = frame
    self.fovTextLabel = label
    local stroke = Instance.new('UIStroke')
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(120, 180, 255)
    stroke.Transparency = 0.4
    stroke.Parent = frame
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    self.fovGui = gui
    self.fovConn = Services.RunService.RenderStepped:Connect(function()
        if not self.enabled then
            return
        end
        local mousePos = Services.UserInputService:GetMouseLocation()
        frame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
        if self.fovTextLabel then
            self.fovTextLabel.Text = 'Target: ' .. (self.currentTargetName or 'None')
            self.fovTextLabel.Visible = true
        end
    end)
end

function Aimbot:updateTargetLabel(target)
    local name = 'None'
    if target and target.Parent then
        name = target.Parent.Name or 'None'
    end
    self.currentTargetName = name
    if self.fovTextDrawing then
        self.fovTextDrawing.Text = 'Target: ' .. name
        self.fovTextDrawing.Visible = self.enabled
    end
    if self.fovTextLabel then
        self.fovTextLabel.Text = 'Target: ' .. name
        self.fovTextLabel.Visible = self.enabled
    end
end

function Aimbot:findTarget(maxDistance)
    if self:useFovMode() then
        return self:getFovTarget(maxDistance, false)
    end
    local myHRP = getHRP()
    if not myHRP then
        return nil
    end
    local best, bestDist
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if (not maxDistance or dist <= maxDistance) and (not bestDist or dist < bestDist) then
                    best = hrp
                    bestDist = dist
                end
            end
        end
    end
    return best
end

function Aimbot:getFovTarget(maxDistance, allowFallback)
    local cam = Services.Workspace.CurrentCamera
    if not cam then
        return nil
    end
    local myHRP = getHRP()
    if not myHRP then
        return nil
    end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local center = Vector2.new(mousePos.X, mousePos.Y)
    local best, bestScreenDist
    local fallbackBest, fallbackDist

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hrp and hum and hum.Health > 0 then
                local worldPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                local dist3d = (hrp.Position - myHRP.Position).Magnitude
                if not maxDistance or dist3d <= maxDistance then
                    if onScreen and worldPos.Z > 0 then
                        local screenDist = (Vector2.new(worldPos.X, worldPos.Y) - center).Magnitude
                        if screenDist <= (self.fovRadius or 200) then
                            if not bestScreenDist or screenDist < bestScreenDist then
                                best = hrp
                                bestScreenDist = screenDist
                            end
                        end
                    end
                    if not fallbackDist or dist3d < fallbackDist then
                        fallbackBest = hrp
                        fallbackDist = dist3d
                    end
                end
            end
        end
    end

    if best then
        return best
    end
    if allowFallback then
        return fallbackBest
    end
    return nil
end

function Aimbot:getNearestEnemy(maxDistance)
    local target = self:findTarget(maxDistance)
    self:updateTargetLabel(target)
    return target
end

function Aimbot:fire(kind, target)
    if not target then
        return
    end
    local remote = getUseItemRemote()
    if not remote then
        return
    end
    local now = Services.Workspace:GetServerTimeNow()
    local cooldown = (kind == 'web') and 0.25 or 0.2
    if now - (self.lastUse[kind] or 0) < cooldown then
        return
    end
    self.lastUse[kind] = now
    if kind == 'paint' then
        remote:FireServer(target.Position)
    else
        remote:FireServer(target.Position, target)
    end
end

function Aimbot:bindTool(tool)
    if not tool or not tool:IsA('Tool') then
        return
    end
    local name = (tool.Name or ''):lower()
    local hasConn = false
    if name:find('web') and not self.toolConns.web[tool] then
        self.toolConns.web[tool] = tool.Activated:Connect(function()
            if not self.enabled then
                return
            end
            local target = self:getNearestEnemy(nil)
            if target then
                self:fire('web', target)
            end
        end)
        hasConn = true
    end
    if name:find('laser') and name:find('cape') and not self.toolConns.laser[tool] then
        self.toolConns.laser[tool] = tool.Activated:Connect(function()
            if not self.laserEnabled then
                return
            end
            local target = self:getNearestEnemy(nil)
            if target then
                self:fire('laser', target)
            end
        end)
        hasConn = true
    end
    if name:find('paintball') and not self.toolConns.paint[tool] then
        self.toolConns.paint[tool] = tool.Activated:Connect(function()
            if not self.paintEnabled then
                return
            end
            local target = self:getNearestEnemy(nil)
            if target then
                self:fire('paint', target)
            end
        end)
        hasConn = true
    end
    if hasConn then
        tool.Destroying:Connect(function()
            disconnect(self.toolConns.web[tool])
            disconnect(self.toolConns.laser[tool])
            disconnect(self.toolConns.paint[tool])
            self.toolConns.web[tool] = nil
            self.toolConns.laser[tool] = nil
            self.toolConns.paint[tool] = nil
        end)
    end
end

function Aimbot:watchContainer(container)
    if not container then
        return
    end
    for _, child in ipairs(container:GetChildren()) do
        self:bindTool(child)
    end
    local conn = container.ChildAdded:Connect(function(obj)
        self:bindTool(obj)
    end)
    table.insert(self.containerConns, conn)
end

function Aimbot:start()
    resolveRemotes()
    if self.enabled then
        return
    end
    self.enabled = true
    self.touchMode = Services.UserInputService.TouchEnabled
    self:updateTargetLabel(nil)
    self:createFovCircle()
    self.laserEnabled = true
    self.paintEnabled = true
    self.lastUse = { web = 0, laser = 0, paint = 0 }
    disconnect(self.targetUpdateConn)
    self.lastLabelUpdate = 0
    self.targetUpdateConn = Services.RunService.RenderStepped:Connect(function()
        if not self.enabled then
            return
        end
        local now = Services.Workspace:GetServerTimeNow()
        if now - (self.lastLabelUpdate or 0) < 0.05 then
            return
        end
        self.lastLabelUpdate = now
        local target = self:findTarget(nil)
        self:updateTargetLabel(target)
    end)

    self:watchContainer(state.character)
    self:watchContainer(player and player:FindFirstChildOfClass('Backpack'))

    disconnect(self.charAddedConn)
    if player then
        self.charAddedConn = player.CharacterAdded:Connect(function(char)
            for _, c in ipairs(self.containerConns) do
                disconnect(c)
            end
            table.clear(self.containerConns)
            self:watchContainer(char)
            self:watchContainer(player:FindFirstChildOfClass('Backpack'))
        end)
    end
end

function Aimbot:stop()
    self.enabled = false
    self.laserEnabled = false
    self.paintEnabled = false
    self:updateTargetLabel(nil)
    self:destroyFovCircle()
    disconnect(self.targetUpdateConn)
    self.targetUpdateConn = nil
    disconnect(self.charAddedConn)
    self.charAddedConn = nil

    for _, conn in pairs(self.toolConns.web) do
        disconnect(conn)
    end
    for _, conn in pairs(self.toolConns.laser) do
        disconnect(conn)
    end
    for _, conn in pairs(self.toolConns.paint) do
        disconnect(conn)
    end
    self.toolConns = { web = {}, laser = {}, paint = {} }

    for _, conn in ipairs(self.containerConns) do
        disconnect(conn)
    end
    table.clear(self.containerConns)
end


-- Kick on steal
local autoKickOnStealEnabled = false
local autoKickConn = nil
local autoKickUiConn = nil
local autoKickUiChanged = {}

local function forceKickSelf(msg)
    local lp = player
    if lp and typeof(lp.Kick) == 'function' then
        lp:Kick(msg or 'You Stole a Brainrot')
    end
end

local function stripRichText(text)
    if type(text) ~= 'string' then
        return ''
    end
    return text:gsub('%b<>', '')
end

local function extractStolenFromText(text)
    if type(text) ~= 'string' then
        return nil
    end
    local plain = stripRichText(text)
    local match = plain:match('[Yy]ou%s+[Ss]tole%s+(.*)')
    if not match or match == '' then
        return nil
    end
    match = match:gsub('^%s+', ''):gsub('%s+$', '')
    match = match:gsub('[^%w%p%s]', '')
    if match == '' then
        return nil
    end
    return toTitleCase(match)
end

local function clearAutoKickUiChanges()
    for inst, conn in pairs(autoKickUiChanged) do
        disconnect(conn)
        autoKickUiChanged[inst] = nil
    end
end

local function watchStealUi(inst)
    if not (inst and (inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox'))) then
        return
    end
    local function check()
        if not autoKickOnStealEnabled then
            return
        end
        local txt = inst.ContentText
        if type(txt) ~= 'string' or txt == '' then
            txt = inst.Text
        end
        if type(txt) ~= 'string' then
            return
        end
        if txt:lower():find('you stole') then
            local cleanedName = extractStolenFromText(txt) or 'Brainrot'
            forceKickSelf('You Stole ' .. cleanedName)
        end
    end
    check()
    disconnect(autoKickUiChanged[inst])
    autoKickUiChanged[inst] = inst:GetPropertyChangedSignal('Text'):Connect(check)
    inst.Destroying:Connect(function()
        disconnect(autoKickUiChanged[inst])
        autoKickUiChanged[inst] = nil
    end)
end

local function resolveStolenBrainrotName(...)
    local args = { ... }
    for _, arg in ipairs(args) do
        if type(arg) == 'table' then
            local candidate = arg.DisplayName or arg.Name or arg.Index or arg.Brainrot or arg[1]
            if candidate then
                local candStr = tostring(candidate)
                return toTitleCase(clean(candStr))
            end
        elseif type(arg) == 'string' and arg ~= '' then
            local cleaned = clean(arg)
            if cleaned ~= '' then
                return toTitleCase(cleaned)
            end
        end
    end
    local attr = player
        and (player:GetAttribute('StealingIndex')
            or player:GetAttribute('StealingName')
            or player:GetAttribute('StealingAnimal'))
    if type(attr) == 'string' and attr ~= '' then
        return toTitleCase(attr)
    end
    return 'a Brainrot'
end

local function startAutoKickOnSteal()
    resolveRemotes()
    if autoKickOnStealEnabled then
        return
    end
    autoKickOnStealEnabled = true

    task.spawn(function()
        local gui = player and (player:FindFirstChild('PlayerGui') or player:WaitForChild('PlayerGui', 5))
        if not gui then
            return
        end
        for _, desc in ipairs(gui:GetDescendants()) do
            watchStealUi(desc)
        end
        disconnect(autoKickUiConn)
        autoKickUiConn = gui.DescendantAdded:Connect(function(inst)
            watchStealUi(inst)
        end)
    end)

    if stealSuccessRemote and stealSuccessRemote.OnClientEvent then
        disconnect(autoKickConn)
        autoKickConn = stealSuccessRemote.OnClientEvent:Connect(function(...)
            if not autoKickOnStealEnabled then
                return
            end
            local stolenName = resolveStolenBrainrotName(...) or 'a Brainrot'
            local msg = stolenName:lower():find('you stole') and stolenName or ('You Stole ' .. stolenName)
            forceKickSelf(msg)
        end)
    else
        warn('Auto Kick On Steal: StealingSuccess remote missing; UI watcher only.')
    end
end

local function stopAutoKickOnSteal()
    autoKickOnStealEnabled = false
    disconnect(autoKickConn)
    autoKickConn = nil
    disconnect(autoKickUiConn)
    autoKickUiConn = nil
    clearAutoKickUiChanges()
end


-- Auto turret destroyer
local SENTRY_TOOL_NAME = 'Bat'
local SENTRY_COOLDOWN_ARGS = { '\6\1\8B\6\1\8B' }
local SentryDestroyer = {
    enabled = false,
    thread = nil,
    lastScan = 0,
    interval = 0.65,
    hitOnce = setmetatable({}, { __mode = 'k' }),
    attemptedIds = {},
    tracked = setmetatable({}, { __mode = 'k' }),
    ownerCache = setmetatable({}, { __mode = 'k' }),
    touchCache = setmetatable({}, { __mode = 'k' }),
    queue = {},
    queueSet = setmetatable({}, { __mode = 'k' }),
    conns = {},
    sentryConns = setmetatable({}, { __mode = 'k' }),
    ancestryConns = setmetatable({}, { __mode = 'k' }),
    processing = false,
}


local function isPlayerMatch(val)
    if val == nil then
        return false
    end
    if val == player then
        return true
    end
    local asString = tostring(val)
    if asString == (player and player.Name) or asString == tostring(player and player.UserId) then
        return true
    end
    local num = tonumber(val)
    return num and player and num == player.UserId
end

local function valueObjectMatchesPlayer(obj)
    return obj and obj:IsA('ValueBase') and isPlayerMatch(obj.Value)
end

local ownerAttributeKeys = {
    'Owner',
    'OwnerUserId',
    'OwnerId',
    'PlacerUserId',
    'PlacerId',
    'PlayerUserId',
    'PlayerId',
    'Creator',
    'CreatorId',
    'PlacedBy',
    'UserId',
    'OwnerName',
    'PlayerName',
}

local function hasOwnerAttributes(obj)
    if not obj then
        return false
    end
    for _, key in ipairs(ownerAttributeKeys) do
        local val = obj:GetAttribute(key)
        if isPlayerMatch(val) then
            return true
        end
        if type(val) == 'string' and player and player.Name and val:lower() == player.Name:lower() then
            return true
        end
    end
    return false
end

local function isMySentry(inst)
    if not inst then
        return false
    end
    local ownerTag = inst:FindFirstChild('Owner')
        or inst:FindFirstChild('Creator')
        or inst:FindFirstChild('Player')
        or inst:FindFirstChild('OwnerUserId')
        or inst:FindFirstChild('Placer')
        or inst:FindFirstChild('PlacedBy')

    if ownerTag and isPlayerMatch(ownerTag.Value) then
        return true
    end
    if hasOwnerAttributes(inst) then
        return true
    end
    for _, desc in ipairs(inst:GetDescendants()) do
        if desc:IsA('ValueBase') and valueObjectMatchesPlayer(desc) then
            return true
        end
        if hasOwnerAttributes(desc) then
            return true
        end
    end
    if player and player.Name then
        local full = inst:GetFullName():lower()
        if full:find(player.Name:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function isSentryRoot(inst)
    if not inst then
        return false
    end
    local name = inst.Name or ''
    return string.match(name, '^Sentry_%d+') ~= nil or string.match(name:lower(), '^sentry_%d+') ~= nil
end

local function getTurretTargetPart(model)
    if not model then
        return nil
    end
    if model:IsA('BasePart') then
        return model
    end
    local withTouch = model:FindFirstChildWhichIsA('TouchTransmitter', true)
    if withTouch and withTouch.Parent and withTouch.Parent:IsA('BasePart') then
        return withTouch.Parent
    end
    if model.PrimaryPart then
        return model.PrimaryPart
    end
    return model:FindFirstChildWhichIsA('BasePart', true)
end

local function shouldAttemptTurret(model)
    if not model then
        return false
    end
    local cachedOwner = SentryDestroyer.ownerCache[model]
    if cachedOwner == nil then
        cachedOwner = isMySentry(model)
        SentryDestroyer.ownerCache[model] = cachedOwner
    end
    if cachedOwner then
        SentryDestroyer.hitOnce[model] = true
        local idOwned = typeof(model.GetDebugId) == 'function' and model:GetDebugId() or model:GetFullName()
        if idOwned then
            SentryDestroyer.attemptedIds[idOwned] = true
        end
        return false
    end
    if SentryDestroyer.hitOnce[model] then
        return false
    end
    local id = typeof(model.GetDebugId) == 'function' and model:GetDebugId() or model:GetFullName()
    if id and SentryDestroyer.attemptedIds[id] then
        return false
    end
    return true
end

local function hasTouchTransmitter(model)
    if not model then
        return false
    end
    return model:FindFirstChild('TouchInterest', true) or model:FindFirstChildWhichIsA('TouchTransmitter', true)
end

local function markSentryAttempted(model)
    if not model then
        return
    end
    SentryDestroyer.hitOnce[model] = true
    local id = typeof(model.GetDebugId) == 'function' and model:GetDebugId() or model:GetFullName()
    if id then
        SentryDestroyer.attemptedIds[id] = true
    end
end

local function getSentryDestroyTool()
    local backpack = player and player:FindFirstChildOfClass('Backpack')
    local char = state.character
    local tool = backpack and backpack:FindFirstChild(SENTRY_TOOL_NAME)
    if not tool and char then
        tool = char:FindFirstChild(SENTRY_TOOL_NAME)
    end
    if not tool then
        for _, item in ipairs((char and char:GetChildren()) or {}) do
            if item:IsA('Tool') and (item.Name or ''):lower():find('bat') then
                tool = item
                break
            end
        end
        if not tool and backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA('Tool') and (item.Name or ''):lower():find('bat') then
                    tool = item
                    break
                end
            end
        end
    end
    return tool
end

local function getToolHandle(tool)
    if not tool then
        return nil
    end
    return tool:FindFirstChild('Handle') or tool:FindFirstChildWhichIsA('BasePart')
end

local function swingAtSentry(handle, target)
    if not (handle and target and target:IsA('BasePart')) then
        return false
    end
    if not (handle:IsDescendantOf(Services.Workspace) and target:IsDescendantOf(Services.Workspace)) then
        return false
    end
    if sentryCooldownRemote and typeof(sentryCooldownRemote.FireServer) == 'function' then
        sentryCooldownRemote:FireServer(table.unpack(SENTRY_COOLDOWN_ARGS))
    end
    if typeof(firetouchinterest) ~= 'function' then
        return false
    end
    local hit = false
    local ok1 = pcall(firetouchinterest, handle, target, 0)
    if ok1 then
        hit = true
    end
    local ok2 = pcall(firetouchinterest, handle, target, 1)
    if ok2 then
        hit = true
    end
    return hit
end

local function collectEnemySentries()
    local enemies = {}
    for _, object in ipairs(Services.Workspace:GetChildren()) do
        if isSentryRoot(object) and shouldAttemptTurret(object) then
            local hasTouch = object:FindFirstChild('TouchInterest', true)
                or object:FindFirstChildWhichIsA('TouchTransmitter', true)
            if hasTouch then
                table.insert(enemies, object)
            end
        end
    end
    return enemies
end

local function attackEnemySentries(enemies)
    if #enemies == 0 then
        return 0
    end
    local tool = getSentryDestroyTool()
    if not tool then
        warn(string.format("Auto Sentry Destroyer: tool '%s' not found.", SENTRY_TOOL_NAME))
        return 0
    end
    local handle = getToolHandle(tool)
    if not handle then
        return 0
    end
    local hum = state.humanoid or (state.character and state.character:FindFirstChildOfClass('Humanoid'))
    local backpack = player and player:FindFirstChildOfClass('Backpack')
    if hum and backpack and tool.Parent == backpack then
        hum:EquipTool(tool)
    elseif state.character and tool.Parent ~= state.character then
        tool.Parent = state.character
    end
    task.wait(0.1)
    if typeof(tool.Activate) == 'function' then
        tool:Activate()
    end
    local hits = 0
    for _, enemy in ipairs(enemies) do
        local target = getTurretTargetPart(enemy) or enemy:FindFirstChildWhichIsA('BasePart', true) or enemy
        markSentryAttempted(enemy)
        if swingAtSentry(handle, target) then
            hits = hits + 1
        end
    end
    task.wait(0.9)
    if backpack and state.character and tool.Parent == state.character then
        tool.Parent = backpack
    end
    return hits
end

local function scanAndDestroyTurrets()
    if not SentryDestroyer.enabled then
        return 0
    end
    local enemies = collectEnemySentries()
    if #enemies == 0 then
        return 0
    end
    local hits = attackEnemySentries(enemies)
    if hits > 0 then
        warn('[AutoTurretDestroy]', 'Attacked', hits, 'targets')
    end
    return hits
end

function SentryDestroyer:start()
    resolveRemotes()
    if self.enabled then
        return
    end
    self.enabled = true
    table.clear(self.queue)
    table.clear(self.queueSet)
    table.clear(self.tracked)
    table.clear(self.touchCache)
    table.clear(self.ownerCache)
    table.clear(self.attemptedIds)
    self.processing = false
    if self.conns.workspaceAdded then
        disconnect(self.conns.workspaceAdded)
        self.conns.workspaceAdded = nil
    end
    if self.conns.workspaceRemoved then
        disconnect(self.conns.workspaceRemoved)
        self.conns.workspaceRemoved = nil
    end
    local function trackSentry(model)
        if not (self.enabled and model and isSentryRoot(model)) then
            return
        end
        if self.tracked[model] then
            return
        end
        self.tracked[model] = true
        if not shouldAttemptTurret(model) then
            return
        end
        local hasTouch = hasTouchTransmitter(model)
        self.touchCache[model] = hasTouch and true or false
        if hasTouch then
            self:enqueue(model)
        end
        local conn = model.DescendantAdded:Connect(function(desc)
            if not self.enabled then
                return
            end
            if desc:IsA('TouchInterest') or desc:IsA('TouchTransmitter') then
                self.touchCache[model] = true
                self:enqueue(model)
            end
        end)
        self.sentryConns[model] = conn
        local ancConn = model.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self:untrack(model)
            end
        end)
        self.ancestryConns[model] = ancConn
    end
    self.conns.workspaceAdded = Services.Workspace.ChildAdded:Connect(function(obj)
        trackSentry(obj)
    end)
    self.conns.workspaceRemoved = Services.Workspace.ChildRemoved:Connect(function(obj)
        if self.tracked[obj] then
            self:untrack(obj)
        end
    end)
    for _, obj in ipairs(Services.Workspace:GetChildren()) do
        trackSentry(obj)
    end
end

function SentryDestroyer:stop()
    self.enabled = false
    if self.thread then
        task.cancel(self.thread)
    end
    self.thread = nil
    if self.conns.workspaceAdded then
        disconnect(self.conns.workspaceAdded)
        self.conns.workspaceAdded = nil
    end
    if self.conns.workspaceRemoved then
        disconnect(self.conns.workspaceRemoved)
        self.conns.workspaceRemoved = nil
    end
    for model, conn in pairs(self.sentryConns) do
        disconnect(conn)
        self.sentryConns[model] = nil
    end
    for model, conn in pairs(self.ancestryConns) do
        disconnect(conn)
        self.ancestryConns[model] = nil
    end
    table.clear(self.queue)
    table.clear(self.queueSet)
    table.clear(self.tracked)
    table.clear(self.touchCache)
    table.clear(self.ownerCache)
    self.processing = false
end

function SentryDestroyer:untrack(model)
    if not model then
        return
    end
    self.tracked[model] = nil
    self.queueSet[model] = nil
    self.touchCache[model] = nil
    self.ownerCache[model] = nil
    local conn = self.sentryConns[model]
    if conn then
        disconnect(conn)
        self.sentryConns[model] = nil
    end
    local ancConn = self.ancestryConns[model]
    if ancConn then
        disconnect(ancConn)
        self.ancestryConns[model] = nil
    end
end

function SentryDestroyer:enqueue(model)
    if not (self.enabled and model) then
        return
    end
    if self.queueSet[model] then
        return
    end
    if not shouldAttemptTurret(model) then
        return
    end
    self.queueSet[model] = true
    table.insert(self.queue, model)
    self:processQueue()
end

function SentryDestroyer:processQueue()
    if self.processing then
        return
    end
    self.processing = true
    task.spawn(function()
        if not self.enabled then
            self.processing = false
            return
        end
        local enemies = {}
        local retry = {}
        while #self.queue > 0 do
            local model = table.remove(self.queue, 1)
            self.queueSet[model] = nil
            if model and model.Parent and isSentryRoot(model) and shouldAttemptTurret(model) then
                local cachedOwner = self.ownerCache[model]
                if cachedOwner == nil then
                    cachedOwner = isMySentry(model)
                    self.ownerCache[model] = cachedOwner
                end
                if cachedOwner then
                    markSentryAttempted(model)
                else
                    local hasTouch = self.touchCache[model]
                    if hasTouch == nil then
                        hasTouch = hasTouchTransmitter(model) and true or false
                        self.touchCache[model] = hasTouch
                    end
                    if hasTouch then
                        table.insert(enemies, model)
                    else
                        table.insert(retry, model)
                    end
                end
            end
        end
        if #enemies > 0 then
            local hits = attackEnemySentries(enemies)
            if hits > 0 then
                warn('[AutoTurretDestroy]', 'Attacked', hits, 'targets')
            end
        end
        self.processing = false
        if not self.enabled then
            return
        end
        if #retry > 0 then
            task.delay(0.25, function()
                if not self.enabled then
                    return
                end
                for _, model in ipairs(retry) do
                    self:enqueue(model)
                end
            end)
        end
        if #self.queue > 0 then
            self:processQueue()
        end
    end)
end

-- Auto turret deploy
local AutoTurret = { enabled = false, promptConn = nil, promptEndConn = nil, timers = {}, lastDeploy = 0 }

local function getSentryTool()
    if state.character then
        for _, item in ipairs(state.character:GetChildren()) do
            if item:IsA('Tool') and (item.Name or ''):lower():find('sentry') then
                return item
            end
        end
    end
    local backpack = player and player:FindFirstChildOfClass('Backpack')
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA('Tool') and (item.Name or ''):lower():find('sentry') then
                return item
            end
        end
    end
end

local function deployTurret()
    local now = Services.Workspace:GetServerTimeNow()
    if now - AutoTurret.lastDeploy < 2 then
        return
    end
    local tool = getSentryTool()
    local hum = state.character and state.character:FindFirstChildOfClass('Humanoid')
    if not (tool and hum) then
        return
    end
    AutoTurret.lastDeploy = now
    if tool.Parent ~= state.character then
        hum:EquipTool(tool)
    end
    local remote = getUseItemRemote()
    if remote and typeof(remote.FireServer) == 'function' then
        remote:FireServer()
    elseif typeof(tool.Activate) == 'function' then
        tool:Activate()
    end
    task.delay(0.2, function()
        local h = state.character and state.character:FindFirstChildOfClass('Humanoid')
        if h then
            h:UnequipTools()
        end
    end)
end

local function isStealPrompt(prompt)
    if not (prompt and prompt:IsA('ProximityPrompt')) then
        return false
    end
    local lname = (prompt.Name or ''):lower()
    local action = (prompt.ActionText or ''):lower()
    return lname:find('steal')
        or lname:find('brainrot')
        or action:find('steal')
        or action:find('brainrot')
        or prompt:GetAttribute('Steal') == true
end

local function cancelTurretTimerForPrompt(prompt)
    if not prompt then
        return
    end
    local key = tostring(prompt:GetDebugId())
    if AutoTurret.timers[key] then
        task.cancel(AutoTurret.timers[key])
        AutoTurret.timers[key] = nil
    end
end

function AutoTurret:start()
    if self.enabled then
        return
    end
    self.enabled = true
    if self.promptConn or self.promptEndConn then
        return
    end
    self.promptConn = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        if not self.enabled or not isStealPrompt(prompt) then
            return
        end
        cancelTurretTimerForPrompt(prompt)
        local holdDuration = prompt.HoldDuration or 0
        local delayTime = math.max(holdDuration - 0.2, 0)
        local key = tostring(prompt:GetDebugId())
        self.timers[key] = task.delay(delayTime, function()
            deployTurret()
            cancelTurretTimerForPrompt(prompt)
        end)
        prompt.PromptHidden:Once(function()
            cancelTurretTimerForPrompt(prompt)
        end)
    end)
    self.promptEndConn = Services.ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
        if not self.enabled then
            return
        end
        cancelTurretTimerForPrompt(prompt)
    end)
end

function AutoTurret:stop()
    if not self.enabled then
        return
    end
    self.enabled = false
    disconnect(self.promptConn)
    disconnect(self.promptEndConn)
    self.promptConn = nil
    self.promptEndConn = nil
    for _, t in pairs(self.timers) do
        if t then
            task.cancel(t)
        end
    end
    self.timers = {}
end


-- Auto Cloner (manual trigger)

local function getQuantumTeleportRemote()
    resolveRemotes()
    if quantumTeleportRemote and typeof(quantumTeleportRemote.FireServer) == 'function' then
        return quantumTeleportRemote
    end
end

local AutoCloner = { enabled = false, button = nil, gui = nil }

local function getClonerTool()
    local char = state.character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA('Tool') and item.Name:lower():find('cloner') then
                return item
            end
        end
    end
    local bp = player and player:FindFirstChildOfClass('Backpack')
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA('Tool') and item.Name:lower():find('cloner') then
                return item
            end
        end
    end
end

local function performClone()
    local tool = getClonerTool()
    local hum = state.humanoid or (state.character and state.character:FindFirstChildOfClass('Humanoid'))
    if not (tool and hum) then
        notify('Auto Cloner', 'Quantum Cloner not found.', 3)
        return
    end
    if tool.Parent ~= state.character then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
    task.wait(0.1)
    pcall(function()
        if typeof(tool.Activate) == 'function' then
            tool:Activate()
        end
    end)
    task.wait(0.25)
    local remote = getQuantumTeleportRemote and getQuantumTeleportRemote()
    if remote then
        pcall(remote.FireServer, remote)
    end
    task.delay(0.15, function()
        local h = state.character and state.character:FindFirstChildOfClass('Humanoid')
        if h then
            pcall(h.UnequipTools, h)
        end
    end)
end

local function destroyClonerButton()
    if AutoCloner.button then
        pcall(function()
            AutoCloner.button:Destroy()
        end)
    end
    if AutoCloner.gui then
        pcall(function()
            AutoCloner.gui:Destroy()
        end)
    end
    AutoCloner.button = nil
    AutoCloner.gui = nil
end

local function createClonerButton()
    destroyClonerButton()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'AutoClonerButton'
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    local parent = game:GetService('CoreGui')
    local ok, holder = pcall(gethui)
    if ok and holder then
        gui.Parent = holder
    else
        gui.Parent = parent
    end
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.fromOffset(120, 40)
    btn.AnchorPoint = Vector2.new(0.5, 1)
    btn.Position = UDim2.new(0.5, 0, 0.95, 0)
    btn.BackgroundColor3 = THEME.accentA or Color3.fromRGB(80, 170, 255)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = 'CLONER'
    btn.Parent = gui
    btn.MouseButton1Click:Connect(function()
        if AutoCloner.enabled then
            performClone()
        end
    end)
    AutoCloner.button = btn
    AutoCloner.gui = gui
end

function AutoCloner:start()
    if self.enabled then
        return
    end
    self.enabled = true
    if Services.UserInputService.TouchEnabled then
        createClonerButton()
    else
        performClone()
        self.enabled = false
    end
end

function AutoCloner:stop()
    self.enabled = false
    destroyClonerButton()
end


-- Anti Ragdoll (inline script)
local ANTI_RAGDOLL_BLOCKED_STATES = {
    [Enum.HumanoidStateType.Physics] = true,
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
}

local AntiRagdoll = {
    enabled = false,
    character = player and player.Character or nil,
    humanoid = state.humanoid,
    stateConn = nil,
    charConn = nil,
    remoteConn = nil,
    heartbeatConn = nil,
    remoteRetry = nil,
    dampUntil = 0,
    ragdollModule = nil,
    ragdollRemote = nil,
}

function AntiRagdoll:loadRagdollAssets()
    if self.ragdollModule and self.ragdollRemote then
        return
    end
    local packages = Services.ReplicatedStorage:FindFirstChild('Packages')
    if not packages then
        return
    end
    local ragdollScript = packages:FindFirstChild('Ragdoll') or packages:WaitForChild('Ragdoll', 5)
    if not ragdollScript then
        return
    end
    self.ragdollRemote = self.ragdollRemote
        or ragdollScript:FindFirstChild('Ragdoll')
        or ragdollScript:WaitForChild('Ragdoll', 5)
    if not self.ragdollModule then
        local ok, mod = pcall(require, ragdollScript)
        if ok and type(mod) == 'table' then
            self.ragdollModule = mod
        end
    end
end

function AntiRagdoll:cleanRagdoll(char)
    if not (self.enabled and char) then
        return
    end

    local hum = self.humanoid or char:FindFirstChildOfClass('Humanoid')
    if hum then
        self.humanoid = hum
        hum.BreakJointsOnDeath = false

        local currentState = hum:GetState()
        if ANTI_RAGDOLL_BLOCKED_STATES[currentState] and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end

        hum.PlatformStand = false
        hum.Sit = false
        hum.AutoRotate = true

        if player:GetAttribute('RagdollEndTime') ~= 0 then
            pcall(player.SetAttribute, player, 'RagdollEndTime', 0)
        end

        local cam = Services.Workspace.CurrentCamera
        if cam and cam.CameraSubject ~= hum then
            cam.CameraSubject = hum
        end
    end

    local hrp = char:FindFirstChild('HumanoidRootPart')
    if hrp then
        hrp.Anchored = false
        -- Only damp velocity briefly right after a ragdoll attempt.
        if self.dampUntil > os.clock() then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end

    self:loadRagdollAssets()
    if self.ragdollModule and type(self.ragdollModule.Unragdoll) == 'function' then
        pcall(self.ragdollModule.Unragdoll, char)
    end

    for _, inst in ipairs(char:GetDescendants()) do
        if inst:IsA('Motor6D') and inst.Enabled == false then
            inst.Enabled = true
        elseif inst:IsA('BallSocketConstraint') or inst:IsA('HingeConstraint') then
            pcall(inst.Destroy, inst)
        elseif inst:IsA('NoCollisionConstraint') then
            local p0 = inst.Part0
            local p1 = inst.Part1
            if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
                pcall(inst.Destroy, inst)
            end
        elseif inst:IsA('Attachment') then
            local parent = inst.Parent
            if parent and parent:IsA('BasePart') then
                local hasConstraint = parent:FindFirstChildWhichIsA('BallSocketConstraint')
                    or parent:FindFirstChildWhichIsA('HingeConstraint')
                local hasDisabledMotor = false
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA('Motor6D') and child.Enabled == false then
                        hasDisabledMotor = true
                        break
                    end
                end
                if hasConstraint or hasDisabledMotor then
                    pcall(inst.Destroy, inst)
                end
            end
        end
    end
end

function AntiRagdoll:bindHumanoid(hum)
    if not hum then
        return
    end
    for state in pairs(ANTI_RAGDOLL_BLOCKED_STATES) do
        pcall(hum.SetStateEnabled, hum, state, false)
    end

    disconnect(self.stateConn)
    self.stateConn = hum.StateChanged:Connect(function(_, newState)
        if not self.enabled then
            return
        end
        if ANTI_RAGDOLL_BLOCKED_STATES[newState] then
            self.dampUntil = os.clock() + 0.15
            self:cleanRagdoll(self.character)
        end
    end)
end

function AntiRagdoll:bindCharacter(char)
    self.character = char
    self.humanoid = char and char:WaitForChild('Humanoid', 5)
    if not self.humanoid then
        return
    end
    self:bindHumanoid(self.humanoid)
    self:cleanRagdoll(char)
end

function AntiRagdoll:connectRemote()
    if self.remoteConn then
        return
    end
    self:loadRagdollAssets()
    if not self.ragdollRemote then
        return
    end
    self.remoteConn = self.ragdollRemote.OnClientEvent:Connect(function()
        if not self.enabled then
            return
        end
        self.dampUntil = os.clock() + 0.2
        self:cleanRagdoll(self.character)
    end)
end

function AntiRagdoll:start()
    if self.enabled then
        return
    end
    self.enabled = true
    self:loadRagdollAssets()

    if self.character then
        self:bindCharacter(self.character)
    elseif player and player.Character then
        self:bindCharacter(player.Character)
    end

    disconnect(self.charConn)
    self.charConn = player.CharacterAdded:Connect(function(newChar)
        if not self.enabled then
            return
        end
        self:bindCharacter(newChar)
    end)

    self:connectRemote()
    if not self.remoteConn then
        self.remoteRetry = task.spawn(function()
            while self.enabled and not self.remoteConn do
                task.wait(0.5)
                self:connectRemote()
            end
        end)
    end
end

function AntiRagdoll:stop()
    if not self.enabled then
        return
    end
    self.enabled = false
    disconnect(self.stateConn)
    disconnect(self.remoteConn)
    disconnect(self.charConn)
    disconnect(self.heartbeatConn)
    if self.remoteRetry and coroutine.status(self.remoteRetry) ~= 'dead' then
        task.cancel(self.remoteRetry)
    end
    self.stateConn = nil
    self.remoteConn = nil
    self.charConn = nil
    self.heartbeatConn = nil
    self.remoteRetry = nil
    self.dampUntil = 0

    local hum = self.humanoid or (self.character and self.character:FindFirstChildOfClass('Humanoid'))
    if hum then
        for state in pairs(ANTI_RAGDOLL_BLOCKED_STATES) do
            pcall(hum.SetStateEnabled, hum, state, true)
        end
        hum.PlatformStand = false
        hum.Sit = false
        hum.AutoRotate = true
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
    stealerMain = pages.stealer:CreateSection({
        Title = "Stealer",
        Icon = "rbxassetid://127132796651849",
        HelpText = "Tools designed to give you an advantage when stealing items from other players.",
    }),
    combat = pages.stealer:CreateSection({
        Title = "Combat",
        Icon = "rbxassetid://119605181458611",
        HelpText = "Reactive tools to counter enemy weapons.",
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


local function purchaseItem(selectedItem)
    resolveRemotes()
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
end

if sections.stealerMain then
    sections.stealerMain:CreateToggle({
        Title = 'Invisible',
        Default = false,
        SaveKey = 'invisible_enabled',
        Callback = function(value)
            if value then
                Invisible:start()
                notify('Invisible', 'Spoofing position to hide inside podium walls.', 3)
            else
                Invisible:stop()
                notify('Invisible', 'Disabled.', 2)
            end
        end,
    })
    sections.stealerMain:CreateToggle({
        Title = 'Auto Kick On Steal',
        Default = false,
        SaveKey = 'auto_kick_on_steal',
        Callback = function(value)
            if value then
                startAutoKickOnSteal()
                notify('Auto Kick', 'Will leave after stealing and delivering a brainrot.', 3)
            else
                stopAutoKickOnSteal()
                notify('Auto Kick', 'Disabled.', 2)
            end
        end,
    })
    sections.stealerMain:CreateToggle({
        Title = 'No Animation',
        Default = false,
        SaveKey = 'no_animation',
        Callback = function(value)
            if value then
                NoAnimation:start()
                notify('No Animation', 'Stopping default tracks and looping custom anim.', 3)
            else
                NoAnimation:stop()
                notify('No Animation', 'Restored default animations.', 2)
            end
        end,
    })
    sections.stealerMain:CreateToggle({
        Title = 'Auto Cloner',
        Default = false,
        SaveKey = nil,
        Callback = function(value)
            if value then
                AutoCloner:start()
                if Services.UserInputService.TouchEnabled then
                    notify('Auto Cloner', 'Tap CLONER button to clone/swap.', 3)
                else
                    notify('Auto Cloner', 'Running one-time clone/swap.', 2)
                end
            else
                AutoCloner:stop()
                notify('Auto Cloner', 'Disabled.', 2)
            end
        end,
    })
end

if sections.combat then
    sections.combat:CreateToggle({
        Title = 'Medusa Counter',
        Default = false,
        SaveKey = 'medusa_counter_enabled',
        Callback = function(value)
            if value then
                startMedusaCounter()
                notify('Medusa Counter', 'Auto-using Medusa when enemies are close.', 3)
            else
                stopMedusaCounter()
                notify('Medusa Counter', 'Disabled.', 2)
            end
        end,
    })
    sections.combat:CreateToggle({
        Title = 'Aimbot (Web/ Laser / Paintball)',
        Default = false,
        SaveKey = 'web_aimbot_enabled',
        Callback = function(value)
            if value then
                Aimbot:start()
                notify('Aimbot', 'Locking tools to nearest enemy.', 3)
            else
                Aimbot:stop()
                notify('Aimbot', 'Disabled.', 2)
            end
        end,
    })
    local antiRagdollToggle = sections.combat:CreateToggle({
        Title = 'Anti Ragdoll',
        Default = false,
        SaveKey = 'anti_ragdoll_enabled',
        Callback = function(value)
            if value then
                AntiRagdoll:start()
                notify('Anti Ragdoll', 'Blocking ragdoll constraints and forcing getting-up.', 3)
            else
                AntiRagdoll:stop()
                notify('Anti Ragdoll', 'Disabled.', 2)
            end
        end,
    })
    if antiRagdollToggle and antiRagdollToggle.GetState and antiRagdollToggle:GetState() then
        if AntiRagdoll and AntiRagdoll.start then
            AntiRagdoll:start()
        end
    end
    sections.combat:CreateToggle({
        Title = 'Auto Turret (While Stealing)',
        Default = false,
        SaveKey = 'auto_turret_enabled',
        Callback = function(value)
            if value then
                AutoTurret:start()
                notify('Auto Turret', 'Deploying a sentry right before steals finish.', 3)
            else
                AutoTurret:stop()
                notify('Auto Turret', 'Disabled.', 2)
            end
        end,
    })
    sections.combat:CreateToggle({
        Title = 'Auto Sentry Destroyer',
        Default = false,
        SaveKey = 'auto_sentry_destroyer',
        Callback = function(value)
            if value then
                SentryDestroyer:start()
                notify('Auto Sentry Destroyer', 'Auto-swinging bats at enemy sentries.', 3)
            else
                SentryDestroyer:stop()
                notify('Auto Sentry Destroyer', 'Disabled.', 2)
            end
        end,
    })
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
