---@type Regrowth
local _, Regrowth = ...;

local msgPrefix = "|cff10b981[RegrowthLootTool]|r"

function Regrowth:empty(mixed)
    mixed = mixed or false;

    ---@type string
    local varType = type(mixed);

    if (varType == "boolean") then
        return not mixed;
    end

    if (varType == "string") then
        return strtrim(mixed) == "";
    end

    if (varType == "table") then
        for _, val in pairs(mixed) do
            if (val ~= nil) then
                return false;
            end
        end

        return true;
    end

    if (varType == "number") then
        return mixed == 0;
    end

    if (varType == "function"
            or varType == "CFunction"
            or varType == "userdata"
        ) then
        return false;
    end

    return true;
end

function Regrowth:isArray(tbl)
    local i = 0;

    for _ in pairs(tbl) do
        i = i + 1;
        if tbl[i] == nil then
            return false;
        end
    end

    return true;
end

function Regrowth:getFullyQualifiedName(name, realm)
    realm = not self:empty(realm) and realm or nil;
    name = tostring(name);

    if (self:empty(name)) then
        return "";
    end

    local nameHasRealmSeparator = name:match("-");

    if (nameHasRealmSeparator) then
        return name;
    end

    realm = realm or Regrowth.User.realm;
    return ("%s-%s"):format(name, realm), realm;
end

function Regrowth:findByKeyInArray(array, key, value)
    for _, item in ipairs(array) do
        for k, v in pairs(item) do
            if k == key then
                if v == value then
                    return item;
                end
            end
        end
    end

    return nil;
end

function Regrowth:findByKey(tbl, key)
    for k, v in pairs(tbl) do
        if key == k then
            return v;
        end
    end

    return nil;
end

function Regrowth:deepCopyTable(orig)
	local originalType = type(orig)
	local copy

	if originalType == 'table' then
		copy = {}
		for key, value in pairs(orig) do
			copy[key] = self:deepCopyTable(value)
		end
	else
		copy = orig
	end

	return copy
end

function Regrowth:iEquals(reference, control)
    if (type(reference) ~= "string"
            or type(control) ~= "string"
        ) then
        return false
    end

    return string.lower(strtrim(reference)) == string.lower(strtrim(control));
end

function Regrowth:isSelf(senderName, senderFqn)
    return Regrowth:iEquals(senderName, Regrowth.User.name)
        or Regrowth:iEquals(senderFqn, Regrowth.User.fqn);
end

function Regrowth:strStartsWith(str, startStr, insensitive)
    str = tostring(str);
    startStr = tostring(startStr);

    if (insensitive ~= false) then
        str = strlower(str);
        startStr = strlower(startStr);
    end

    return string.sub(str, 1, string.len(startStr)) == startStr;
end

function Regrowth:isCurrentVersion()
    return Regrowth.Data.Version.current and Regrowth.Data.Version.current == Regrowth.Data.Version.latest;
end

function Regrowth:formatEpochForDisplay(epoch)
    if not epoch or epoch == 0 then
        return "Never";
    end

    return date("%d/%m/%Y %H:%M", epoch);
end

function Regrowth:formatEpochAsDateOnly(epoch)
    if not epoch or epoch == 0 then
        return "Never";
    end

    return date("%d/%m/%Y", epoch);
end

-- Guild rank names that count as "officer" for auto-sync purposes. Case
-- and whitespace insensitive.
local OFFICER_RANK_NAMES = {
    ["officer"] = true,
    ["guild master"] = true,
};

-- Enumerates every current guild officer's name, by matching each roster
-- entry's rank NAME (a plain string GetGuildRosterInfo already returns
-- per-member, no extra API call or numeric guessing needed) against
-- OFFICER_RANK_NAMES above. Recalculated live each time, so promotions/
-- demotions apply automatically without needing any manual list update.
function Regrowth:getAllGuildOfficerNames()
    local officerNames = {};
    local numMembers = GetNumGuildMembers and GetNumGuildMembers() or 0;

    for i = 1, numMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote,
            officerNote, isOnline, status, class, achievementPoints, achievementRank,
            isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i);

        if name and rankName then
            local normalizedRank = rankName:lower():gsub("^%s+", ""):gsub("%s+$", "");

            if OFFICER_RANK_NAMES[normalizedRank] then
                local nameNoRealm = name:match("(.+)-") or name;
                table.insert(officerNames, nameNoRealm);
            end
        end
    end

    return officerNames;
end

function Regrowth:isGuildMemberOnline(name)
    if self:empty(name) then
        return false;
    end

    local numMembers = GetNumGuildMembers and GetNumGuildMembers() or 0;

    for i = 1, numMembers do
        local rosterName, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i);

        if rosterName then
            local rosterNameNoRealm = rosterName:match("(.+)-") or rosterName;

            if self:iEquals(rosterNameNoRealm, name) and isOnline then
                return true;
            end
        end
    end

    return false;
end

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

function Regrowth:getPriorityIconText(icon)
    if self:empty(icon) then
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
function Regrowth:getClassIconTextForPriorityLabel(name)
    if self:empty(name) then
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

function Regrowth:colorizePriorityLabel(name)
    if self:empty(name) then
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

function Regrowth:message(...)
    print(msgPrefix .. " " .. table.concat({ ... }, " "));
end

function Regrowth:coloredMessage(color, ...)
    Regrowth:message(string.format("|c00%s%s", color, string.join(" ", ...)));
end

function Regrowth:success(...)
    Regrowth:coloredMessage("92FF00", ...);
end

function Regrowth:warning(...)
    Regrowth:coloredMessage("E9D502", ...);
end

function Regrowth:error(...)
    Regrowth:coloredMessage("BE3333", ...);
end

function Regrowth:debug(...)
    if Regrowth.Settings.DebugMode ~= "on" then
        return;
    end

    Regrowth:coloredMessage("F7922E", ...);
end

function Regrowth:dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. self.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
