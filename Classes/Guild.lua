---@type Regrowth
local _, Regrowth = ...;

---@class Guild
local Guild = {};

---@type Guild
Regrowth.Guild = Guild;

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
function Guild:getAllGuildOfficerNames()
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

function Guild:isGuildMemberOnline(name)
    if Regrowth.Utils.Table:empty(name) then
        return false;
    end

    local numMembers = GetNumGuildMembers and GetNumGuildMembers() or 0;

    for i = 1, numMembers do
        local rosterName, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i);

        if rosterName then
            local rosterNameNoRealm = rosterName:match("(.+)-") or rosterName;

            if Regrowth.Utils.String:iEquals(rosterNameNoRealm, name) and isOnline then
                return true;
            end
        end
    end

    return false;
end
