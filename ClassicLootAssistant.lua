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

-- local frame = CreateFrame("Frame")
-- frame:RegisterEvent("CHAT_MSG_LOOT")
-- frame:SetScript("OnEvent", function(self, event, ...)
--     local text, playerName, playerName2 
-- end)

local function filter(self,event,message,sender,...)
    TEMP_OBJ = {}
    -- TODO plural catches others loot
    -- if string.find(message, "receives loot") ~= nil then
    if string.find(message, "receive loot") ~= nil then
        x = 1
        for i in string.gmatch(message, "%S+") do
            TEMP_OBJ[x] = i
            x = x + 1
        end
    end
    print(event, "event")
    print(RAID_LOOT_ARRAY[1])
    return false
  end
  ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", filter)

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
    -- elseif event == "CHANNEL_ROSTER_UPDATE" then

    --     print(event)
    --     print("CHANNEL_ROSTER_UPDATE")
    -- elseif event == "CHAT_MSG_RESTRICTED" then

    --     print(event)
    --     print("CHAT_MSG_RESTRICTED")
    elseif event == "LOOT_ITEM_SELF" then

        print(event)
        print("LOOT_ITEM_SELF")

    -- elseif event == "CHAT_MSG_LOOT" then
    
    --     local lootstring, _, _, _, player = ...
    --     local itemLink = string.match(lootstring,"|%x+|Hitem:.-|h.-|h|r")
    --     local itemString = string.match(itemLink, "item[%-?%d:]+")
    --     local _, _, quality, _, _, class, subclass, _, equipSlot, texture, _, ClassID, SubClassID = GetItemInfo(itemString)
 
    --     if UnitName("player") == player then 
    --         print(itemLink, itemString, "itemString")
    --     end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target = ...
        -- print(prefix, text, channel, sender, target)
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
            print("A loot event was detected: " .. sender, target)
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

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local time, eventName, _, _, _, _, _, destGuid, destName = CombatLogGetCurrentEventInfo()

        -- We shouldn't be assigning the table everytime a NPC dies but I can't get the RAID_ROSTER_UPDATE event to trigger
        -- If the table and number of players in raid dont match we need to redraw the table.
        local numGroupMembers = GetNumGroupMembers();
        if table.getn(RAID_LOOT_ARRAY) ~= numGroupMembers then
            for i=1,numGroupMembers,1 do
                local memberName, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
                RAID_LOOT_ARRAY[i] = memberName
            end
        end
        -- Track NPC deaths and increase CLA_NUMBER which keeps track of where we are in loot rotation
        if eventName == "UNIT_DIED" then
            CLA_NUMBER = CLA_NUMBER + 1
            -- To rotate around the loot table we need to reset the count to the number of players in the loot table/raid.
            -- If the CLA_NUMBER is one more than total then the loot falls back on addon player
            if numGroupMembers < CLA_NUMBER then
                CLA_NUMBER = 1
            end

            cla_callback(1, function()
                local playerName = UnitName("player");
                local hasLoot, _ = CanLootUnit(destGuid)

                if CLA_DEBUG then
                    if hasLoot then
                        -- Set the addon player as index 1 in the table and reset the unit death count to match to keys
                        -- if playerName == RAID_LOOT_ARRAY[1] then
                        --     CLA_NUMBER = 1
                        -- end
                        print(numGroupMembers < CLA_NUMBER, "numGroupMembers")
                        print(CLA_NUMBER)

                        print("RAID_LOOT_ARRAY:", dump(RAID_LOOT_ARRAY))

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