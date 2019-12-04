local ADDON_NAME, ADDON_TABLE = ...

SLASH_CLA1 = "/cla"

CLA_LOOTLIST = {} -- String encoded NAME:GUID
CLA_SKINNING_TARGETS = { "Core Hound", "Ancient Core Hound" }
CLA_PLAYERS_WITH_ADDON = {}
CLA_MESSAGE_COLOR = "96a9eb"
CLA_ADDON_PREFIX = "CLA"
CLA_DEBUG = true
CLA_SHOW_LOOT = true
CLA_NUMBER = 0
RAID_LOOT_ARRAY = {}

function SlashCmdList.CLA(command)
    if CLA_DEBUG then
        print('The /cla command was issued with parameter ' .. command)
    end

    if command == "" then
        CLA_PrintSettings()
    elseif command == "help" then
        CLA_PrintHelp()
    elseif command == "pros" then
        CLA_PrintPlayersWithAddon()
    elseif command == "noobs" then
        print("The noobs command is not implemented yet")
    elseif command == "debug" then
        -- Toggle DEBUG
        if CLA_DEBUG then
            CLA_DEBUG = false
            print("CLA debug mode has been disabled")
        else
            CLA_DEBUG = true
            print("CLA debug mode has been enabled")
        end

    elseif command == "loot show" then
        CLA_SHOW_LOOT = true
        print("CLA loot messages enabled")
    elseif command == "loot hide" then
        CLA_SHOW_LOOT = false
        print("CLA loot messages disabled")
    else
        print("The command /cla " .. command .. " was not recognized")
    end
end

function CLA_OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix("CLA")

        if CLA_DEBUG then
            print('The CLA prefix was registered')
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target = ...

        if prefix ~= "CLA" then return end

        if text == "DISCOVER" then
            C_ChatInfo.SendAddonMessage("CLA", "REPORT", "WHISPER", sender)

            if CLA_DEBUG then
                print("SendAddonMessage just sent a REPORT by whisper to " .. sender)
            end

            return
        end

        if text == "REPORT" then
            if not cla_has_value(CLA_PLAYERS_WITH_ADDON, sender) then
                table.insert(CLA_PLAYERS_WITH_ADDON, sender)
            end
        
            return
        end

        -- At this point it must be a name:destGuid message.
        if CLA_DEBUG then
            print("A loot event was detected: " .. text)
        end

        if CLA_LOOTLIST[text] ~= nil then
            CLA_LOOTLIST[text] = CLA_LOOTLIST[text] + 1
        else
            CLA_LOOTLIST[text] = 1

            cla_callback(1, function()
                local tableSplitResult = cla_mysplit(text, ':')

                local creatureName = tableSplitResult[1]
                local creatureGuid = tableSplitResult[2]

                if CLA_LOOTLIST[text] > 1 then -- Only show for master looter!
                    local _, playerIsMasterLooter = GetLootMethod();

                    if playerIsMasterLooter or CLA_SHOW_LOOT then
                        cla_print_color("The " .. creatureName .. " that just died has loot on it!", CLA_MESSAGE_COLOR)
                    end
                    
                elseif CLA_LOOTLIST[text] == 1 then
                    if cla_has_value(CLA_SKINNING_TARGETS, creatureName) then
                        cla_print_color(sender .. " can loot the " .. creatureName, CLA_MESSAGE_COLOR)
                    end
                end
            end)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        print(event)
        print("PARTY_MEMBERS_CHANGED")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local numGroupMembers = GetNumGroupMembers();
        local time, eventName, _, _, _, _, _, destGuid, destName = CombatLogGetCurrentEventInfo()
        for i=1,numGroupMembers,1 do
            local memberName, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
            RAID_LOOT_ARRAY[i] = memberName
          end
        
          print("RAID_LOOT_ARRAY:", dump(RAID_LOOT_ARRAY))


        if eventName == "UNIT_DIED" then
            CLA_NUMBER = CLA_NUMBER + 1
            print("CLA_NUMBER", CLA_NUMBER)
            print(numGroupMembers)

            if CLA_DEBUG then
                print("A UNIT_DIED event was detected on mob " .. destName .. " with GUID " .. destGuid)
            end

            cla_callback(1, function()
                local hasLoot, _ = CanLootUnit(destGuid)

                if CLA_DEBUG then
                    if hasLoot then
                        print("It has been detected that you can loot the " .. destName)
                    else
                        print("It has been detected that you can not loot the " .. destName)
                    end
                end

                if hasLoot then
                    C_ChatInfo.SendAddonMessage("CLA", destName .. ":" .. destGuid, cla_get_channel())
                end
            end)
        end
    end
end
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end