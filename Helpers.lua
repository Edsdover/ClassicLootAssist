function cla_callback(duration, callback)
    local newFrame = CreateFrame("Frame")
    newFrame:SetScript("OnUpdate", function (self, elapsed)
        duration = duration - elapsed
        if duration <= 0 then
            callback()
            newFrame:SetScript("OnUpdate", nil)
        end
    end)
end

function cla_has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function cla_mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end

function cla_print_color(text, color)
    print("\124cff" .. color .. text .. "\124r")
end

function cla_bool_to_string(bool)
    return bool and 'true' or 'false'
end

function cla_get_channel()
    if IsInRaid() then
        return "RAID"
    else
        return "PARTY"
    end
end