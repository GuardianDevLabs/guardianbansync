function getPlayerDiscord(playerId)
    print("🔍 Checking Discord ID for Player:", playerId)

    for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
        local identifier = GetPlayerIdentifier(playerId, i)
        print("🆔 Identifier Found:", identifier) -- Debugging

        if string.sub(identifier, 1, 8) == "discord:" then
            local discordId = string.sub(identifier, 9)
            print("✅ Discord ID:", discordId)
            return discordId
        end
    end

    print("❌ No Discord ID found for Player:", playerId)
    return nil
end

function isUserInDiscord(discordId, callback)
    local url = "https://discord.com/api/v10/guilds/" .. Config.GuildID .. "/members/" .. discordId

    PerformHttpRequest(url, function(statusCode, response, headers)
        print("📡 Discord Membership API Response:", statusCode, response) -- Debugging

        if statusCode == 200 then
            callback(true)
        else
            callback(false)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. Config.BotToken })
end

function isUserBanned(discordId, callback)
    local url = "https://discord.com/api/v10/guilds/" .. Config.GuildID .. "/bans/" .. discordId

    PerformHttpRequest(url, function(statusCode, response, headers)
        print("📡 Discord Ban API Response:", statusCode, response) -- Debugging

        if statusCode == 200 then
            callback(true)
        else
            callback(false)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. Config.BotToken })
end

function logBanAttempt(discordId, playerName, playerIp)
    local embed = {
        title = "🚨 Ban Sync Alert 🚨",
        color = 16711680, -- Red color
        fields = {
            { name = "**Player**", value = playerName, inline = true },
            { name = "**Discord ID**", value = discordId, inline = true },
            { name = "**IP Address**", value = "||" .. playerIp .. "||", inline = false },
            { name = "**Status**", value = "Tried to join but is banned from Discord!", inline = false }
        },
        footer = {
            text = "Guardian Labs - BanSync",
            icon_url = "https://cdn.discordapp.com/icons/1337271515808530543/a_c39ac61c8cd6642dc3ce0222c24780ce.gif?size=4096"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    
    local payload = {
        username = "Ban Logger",
        embeds = { embed }
    }

    PerformHttpRequest("https://discord.com/api/v10/channels/" .. Config.LogChannelID .. "/messages", 
        function(statusCode, response, headers) 
            if statusCode == 200 or statusCode == 201 then
                print("✅ Ban attempt logged successfully.")
            else
                print("⚠️ Failed to send log to Discord. Status Code:", statusCode, response)
            end
        end, 
        "POST", 
        json.encode(payload), 
        { ["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. Config.BotToken }
    )
end

function sendStyledKickMessage(setKickReason, deferrals, title, subtitle, description)
    local message = [[
        <style>
            body {
                font-family: Arial, sans-serif;
                color: white;
                margin: 0;
                padding: 0;
                background-color: #2d2d2d;
            }
            .message-box {
                width: 550px;
                margin: auto;
                background-color: #333;
                border: 5px solid #ff0000; /* Red border */
                padding: 30px;
                border-radius: 15px;
                box-shadow: 0 0 25px rgba(255, 0, 0, 0.8);
                text-align: center;
            }
            .title {
                font-size: 30px;
                font-weight: bold;
                color: #ff6666;
                margin-bottom: 15px;
                border-bottom: 2px solid #ff6666;
            }
            .subtitle {
                font-size: 22px;
                color: #e0e0e0;
                margin-bottom: 20px;
            }
            .description {
                font-size: 20px;
                color: #cccccc;
            }
            .appeal {
                font-size: 16px;
                color: #b3b3b3;
                font-style: italic;
                margin-top: 25px;
            }
        </style>
        <div class="message-box">
            <div class="title">🚫 ]] .. title .. [[</div>
            <div class="subtitle">]] .. subtitle .. [[</div>
            <div class="description">]] .. description .. [[</div>
            <div class="appeal">🔗 Join our Discord for more information.</div>
        </div>
    ]]
    deferrals.done(message)
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    deferrals.defer()
    local playerId = source
    local discordId = getPlayerDiscord(playerId)
    local playerIp = GetPlayerEndpoint(playerId) or "Unknown"

    if not discordId then
        sendStyledKickMessage(setKickReason, deferrals, "Discord Not Linked", "You must link your Discord to join.", "Please ensure your Discord is connected.")
        return
    end

    -- Check if the user is banned first
    isUserBanned(discordId, function(isBanned)
        if isBanned then
            logBanAttempt(discordId, name, playerIp)
            sendStyledKickMessage(setKickReason, deferrals, "You Are Banned", "You are banned from our Discord server.", "If you believe this was a mistake, contact staff at " .. Config.DiscordInvite)
            return
        end

        -- Only check if they are in the Discord server after confirming they aren’t banned
        isUserInDiscord(discordId, function(isMember)
            if not isMember then
                sendStyledKickMessage(setKickReason, deferrals, "Not in Discord Server", "You must be in our Discord server to join.", "Join here: " .. Config.DiscordInvite)
            else
                deferrals.done()
            end
        end)
    end)
end)