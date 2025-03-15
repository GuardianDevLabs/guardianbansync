function getPlayerDiscord(playerId)
    print("🔍 Checking Discord ID for Player:", playerId)

    -- Loop through all identifiers to find the Discord identifier
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
    print("Checking if Discord ID is in server...")
    print("Guild ID: " .. Config.GuildID)
    print("Discord ID: " .. discordId)

    local url = "https://discord.com/api/v10/guilds/" .. Config.GuildID .. "/members/" .. discordId
    PerformHttpRequest(url, function(statusCode, response, headers)
        print("📡 Discord Membership API Response:", statusCode, response)  -- Debugging
        if statusCode == 200 then
            callback(true)
        elseif statusCode == 403 then
            print("❌ Bot lacks permission to view the member list.")
            callback(false)
        elseif statusCode == 404 then
            print("❌ Player not found in server. This may also indicate the wrong Discord ID or Guild ID.")
            callback(false)
        else
            print("❌ API Error. Status Code: " .. statusCode)
            callback(false)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. Config.BotToken })
end

function isUserBanned(discordId, callback)
    local url = "https://discord.com/api/v10/guilds/" .. Config.GuildID .. "/bans/" .. discordId

    PerformHttpRequest(url, function(statusCode, response, headers)
        print("📡 Discord Ban API Response:", statusCode, response) -- Debugging

        if statusCode == 200 then
            local banData = json.decode(response)
            local bannedBy = banData.user.username .. "#" .. banData.user.discriminator -- Banned user's info
            local banReason = banData.reason or "No reason provided" -- Handle case where no reason is given

            -- Pass correct bannedBy and banReason
            callback(true, banReason, bannedBy)
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

function sendStyledKickMessage(setKickReason, deferrals, messageContent, isBan)
    -- Adjusted box size to be slightly bigger, 10px wider on the right side, smaller height, and much larger logo
    local message = [[
        <div style="background-color: rgba(30, 30, 30, 0.5); padding: 10px; border: solid 2px #354557; border-radius: 10px; margin-top: 10px; position: relative; width: calc(100% - 20px); height: 350px; max-width: calc(100% - 20px); box-sizing: border-box; margin-left: auto; margin-right: auto;">
            <h1 style="color: #8A2BE2; font-size: 2rem; margin: 0; padding-bottom: 5px;">]] .. Config.ServerName .. [[</h1>
    ]]

    -- If it's a ban message, place it right under the server name
    if isBan then
        message = message .. [[
            <p style="font-size: 1.3rem; font-weight: bold; margin: 5px 0 0 0; padding: 0; line-height: 1.4;">
                ]] .. messageContent .. [[
            </p>
        ]]
    else
        -- Otherwise, use normal message styling
        message = message .. [[
            <p style="font-size: 1.3rem; margin: 10px 0; padding: 0; line-height: 1.6;">
                ]] .. messageContent .. [[
            </p>
        ]]
    end

    -- Adjust logo size and position (much larger size)
    message = message .. [[
        <img src="]] .. Config.ServerLogo .. [[" style="position: absolute; right: 15px; bottom: 15px; opacity: 65%; max-width: 200px; max-height: 200px;">
        </div>
    ]] 

    -- Send the message
    deferrals.done(message)
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    deferrals.defer()
    local playerId = source
    local discordId = getPlayerDiscord(playerId)
    local playerIp = GetPlayerEndpoint(playerId) or "Unknown"

    if not discordId then
        sendStyledKickMessage(setKickReason, deferrals, "Please ensure your Discord is connected.", false)
        return
    end

    print("Checking if player with Discord ID " .. discordId .. " is banned or in the Discord server.")

    -- First, check if the user is banned
    isUserBanned(discordId, function(isBanned, banReason)
        if isBanned then
            logBanAttempt(discordId, name, playerIp)
            -- Send ban message with appeal link and proper line breaks
            sendStyledKickMessage(setKickReason, deferrals, 
                [[Banned By: Guardian Core BanSync<br>Ban Reason: ]] .. (banReason or "No reason provided") .. [[

<br><br><br><br><br><a href="]] .. Config.AppealLink .. [[" style="color: #8A2BE2;">Click here to appeal your ban</a>
]], true)
        else
            -- If not banned, check if the user is in the Discord server
            isUserInDiscord(discordId, function(isMember)
                if not isMember then
                    sendStyledKickMessage(setKickReason, deferrals, 
                        [[<span style="color: white; font-weight: bold;">You must join our Discord server to play.</span><br><br><br><br><br><br><a href="]] .. Config.DiscordInvite .. [[" style="color: #8A2BE2;">Click here to join our Discord</a>
                    ]], false)
                    print("Player is not in the Discord server.")
                else
                    deferrals.done()  -- Player can connect if they are in the server and not banned
                    print("Player is in the Discord server.")
                end
            end)
        end
    end)
end)
