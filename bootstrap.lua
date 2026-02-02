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

-- Auto Joiner logic (copied from StealABrainrot)
local Services = {
    Players = game:GetService("Players"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
}

local player = Services.Players.LocalPlayer

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

return window
