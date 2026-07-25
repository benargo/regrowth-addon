---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Utils.String
local String = {};
Regrowth.Utils = Regrowth.Utils or {};
Regrowth.Utils.String = String;

function String:iEquals(reference, control)
    if (type(reference) ~= "string"
            or type(control) ~= "string"
        ) then
        return false
    end

    return string.lower(strtrim(reference)) == string.lower(strtrim(control));
end

function String:strStartsWith(str, startStr, insensitive)
    str = tostring(str);
    startStr = tostring(startStr);

    if (insensitive ~= false) then
        str = strlower(str);
        startStr = strlower(startStr);
    end

    return string.sub(str, 1, string.len(startStr)) == startStr;
end
