---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Interface.PriorityLabel
local PriorityLabel = {};
Regrowth.Interface = Regrowth.Interface or {};
Regrowth.Interface.PriorityLabel = PriorityLabel;

-- Maps the plain English class word (as it'd appear at the end of a
-- priority/spec name like "Balance Druid" or "Shadow Priest") to the
-- classFileName WoW's own RAID_CLASS_COLORS table is keyed by.
local CLASS_NAME_TO_FILE_NAME = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"] = "HUNTER",
    ["Rogue"] = "ROGUE",
    ["Priest"] = "PRIEST",
    ["Shaman"] = "SHAMAN",
    ["Mage"] = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Druid"] = "DRUID",
    ["Monk"] = "MONK",
    ["Evoker"] = "EVOKER",
};

-- Colours a priority/spec label (e.g. "Balance Druid", "Shadow Priest") in
-- its WoW class colour, using Blizzard's own RAID_CLASS_COLORS so it always
-- matches the colours used everywhere else in the game UI. Labels that
-- don't end in a recognisable class name (e.g. "Tank", "Melee DPS" - role
-- categories that span multiple classes) are returned unmodified.
-- Class icon texture names, keyed the same way as RAID_CLASS_COLORS.
local CLASS_ICON_NAMES = {
    WARRIOR = "classicon_warrior",
    PALADIN = "classicon_paladin",
    HUNTER = "classicon_hunter",
    ROGUE = "classicon_rogue",
    PRIEST = "classicon_priest",
    SHAMAN = "classicon_shaman",
    MAGE = "classicon_mage",
    WARLOCK = "classicon_warlock",
    DRUID = "classicon_druid",
    MONK = "classicon_monk",
    EVOKER = "classicon_evoker",
};

function PriorityLabel:getPriorityIconText(icon)
    if Regrowth.Utils.Table:empty(icon) then
        return "";
    end

    return "|TInterface\\Icons\\" .. icon .. ":16|t ";
end

-- Determines a class icon for a priority/spec label the exact same way
-- colorizePriorityLabel determines its colour: by matching the last word
-- against a known class name. Labels with a specific spec qualifier (e.g.
-- "Balance Druid") still resolve correctly since only the trailing class
-- word is checked. Role-only labels ("Tank", "Melee DPS") that don't end
-- in a class name get no icon.
function PriorityLabel:getClassIconTextForPriorityLabel(name)
    if Regrowth.Utils.Table:empty(name) then
        return "";
    end

    local lastWord = name:match("(%S+)$");
    local classFileName = lastWord and CLASS_NAME_TO_FILE_NAME[lastWord];

    if not classFileName then
        return "";
    end

    local iconName = CLASS_ICON_NAMES[classFileName];

    if not iconName then
        return "";
    end

    return self:getPriorityIconText(iconName);
end

function PriorityLabel:colorizePriorityLabel(name)
    if Regrowth.Utils.Table:empty(name) then
        return name;
    end

    local lastWord = name:match("(%S+)$");
    local classFileName = lastWord and CLASS_NAME_TO_FILE_NAME[lastWord];

    if not classFileName then
        return name;
    end

    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName];

    if not classColor or not classColor.colorStr then
        return name;
    end

    return "|c" .. classColor.colorStr .. name .. "|r";
end
