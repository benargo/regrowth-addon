---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Utils.DateFormat');
local DateFormat = Regrowth.Utils.DateFormat;

-- 2024-01-15 10:30:00 UTC
local KNOWN_EPOCH = 1705314600;

function Tests:FormatEpochForDisplayReturnsNeverForNil()
    AreEqual("Never", DateFormat:formatEpochForDisplay(nil));
end

function Tests:FormatEpochForDisplayReturnsNeverForZero()
    AreEqual("Never", DateFormat:formatEpochForDisplay(0));
end

function Tests:FormatEpochForDisplayFormatsKnownEpoch()
    AreEqual(date("%d/%m/%Y %H:%M", KNOWN_EPOCH), DateFormat:formatEpochForDisplay(KNOWN_EPOCH));
end

function Tests:FormatEpochAsDateOnlyReturnsNeverForNil()
    AreEqual("Never", DateFormat:formatEpochAsDateOnly(nil));
end

function Tests:FormatEpochAsDateOnlyReturnsNeverForZero()
    AreEqual("Never", DateFormat:formatEpochAsDateOnly(0));
end

function Tests:FormatEpochAsDateOnlyFormatsKnownEpoch()
    AreEqual(date("%d/%m/%Y", KNOWN_EPOCH), DateFormat:formatEpochAsDateOnly(KNOWN_EPOCH));
end
