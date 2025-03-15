# Discord Linking and Ban Sync for FiveM
# Made By GuardianLabs

This resource for FiveM ensures players are properly linked to your Discord server before they can join, checks for bans, and logs ban attempts. The script ensures a smooth integration between FiveM and Discord, offering a seamless experience for server administrators.

## Features

- **Discord Linking**: Players must link their Discord account to join the server.
- **Ban Sync**: Syncs bans from your Discord server with FiveM.
- **Server Invite**: Sends a Discord invite link to users who are not linked to Discord or need to join your server.
- **Ban Logging**: Logs ban attempts to a specified Discord channel.

## Installation

1. Download or clone this repository to your FiveM server.
2. Extract it to your `resources` folder.
3. Add this resource to your `server.cfg`:
   ```bash
   ensure GuardianBanSync

# Configuration
` The configuration for this script is located in the config/config.lua file. Modify the following parameters based on your server's settings: `

-- Your Discord Bot Token. This is required for accessing the Discord API.
Config.BotToken = `your-bot-token-here`

-- The ID of your Discord Server (Guild). This is required for checking if users are in your server and checking bans.
Config.GuildID = `your-guild-id-here`

-- The ID of the Discord channel where ban attempts will be logged.
Config.LogChannelID = `your-log-channel-id-here'`

-- The Discord invite URL for your server. Used when a player needs to join your Discord.
Config.DiscordInvite = `https://discord.gg/your-invite-link-here`

## Thank you for installing our script into your server ifyou have any issues with this script or have any questions join our development discord https://discord.gg/guardianlabs
