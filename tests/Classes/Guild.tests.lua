---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Guild');
local Guild = Regrowth.Guild;

-- Simulates GetGuildRosterInfo's return signature for a small fixed roster.
-- Fields not needed by Guild's methods are left nil.
local function mockRoster(members)
    Replace(_G, 'GetNumGuildMembers', function() return #members end);
    Replace(_G, 'GetGuildRosterInfo', function(index)
        local member = members[index];
        if not member then return nil end

        return member.name, member.rankName, nil, nil, nil, nil, nil,
            nil, member.isOnline;
    end);
end

function Tests:GetAllGuildOfficerNamesMatchesOfficerRank()
    mockRoster({
        { name = "Alice-Realm", rankName = "Officer", isOnline = true },
        { name = "Bob-Realm", rankName = "Member", isOnline = true },
    });

    AreEqual({ "Alice" }, Guild:getAllGuildOfficerNames());
end

function Tests:GetAllGuildOfficerNamesMatchesGuildMasterRank()
    mockRoster({
        { name = "Alice-Realm", rankName = "Guild Master", isOnline = true },
    });

    AreEqual({ "Alice" }, Guild:getAllGuildOfficerNames());
end

function Tests:GetAllGuildOfficerNamesIsCaseAndWhitespaceInsensitive()
    mockRoster({
        { name = "Alice-Realm", rankName = "  OFFICER  ", isOnline = true },
    });

    AreEqual({ "Alice" }, Guild:getAllGuildOfficerNames());
end

function Tests:GetAllGuildOfficerNamesReturnsEmptyWhenNoOfficers()
    mockRoster({
        { name = "Bob-Realm", rankName = "Member", isOnline = true },
    });

    AreEqual({}, Guild:getAllGuildOfficerNames());
end

function Tests:IsGuildMemberOnlineTrueForOnlineMember()
    mockRoster({
        { name = "Alice-Realm", rankName = "Member", isOnline = true },
    });

    IsTrue(Guild:isGuildMemberOnline("Alice"));
end

function Tests:IsGuildMemberOnlineFalseForOfflineMember()
    mockRoster({
        { name = "Alice-Realm", rankName = "Member", isOnline = false },
    });

    IsFalse(Guild:isGuildMemberOnline("Alice"));
end

function Tests:IsGuildMemberOnlineFalseForEmptyName()
    mockRoster({});

    IsFalse(Guild:isGuildMemberOnline(""));
end
