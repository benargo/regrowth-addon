---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Utils.DateFormat
local DateFormat = {};
Regrowth.Utils = Regrowth.Utils or {};
Regrowth.Utils.DateFormat = DateFormat;

function DateFormat:formatEpochForDisplay(epoch)
    if not epoch or epoch == 0 then
        return "Never";
    end

    return date("%d/%m/%Y %H:%M", epoch);
end

function DateFormat:formatEpochAsDateOnly(epoch)
    if not epoch or epoch == 0 then
        return "Never";
    end

    return date("%d/%m/%Y", epoch);
end
