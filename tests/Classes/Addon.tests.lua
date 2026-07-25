---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Addon');
local Addon = Regrowth.Addon;

function Tests:GetFullyQualifiedNameAddsRealmWhenMissing()
    Replace(Regrowth, 'User', { realm = "TestRealm" });

    AreEqual("Player-TestRealm", Addon:getFullyQualifiedName("Player"));
end

function Tests:GetFullyQualifiedNameLeavesNameUnchangedWhenRealmAlreadyPresent()
    AreEqual("Player-OtherRealm", Addon:getFullyQualifiedName("Player-OtherRealm"));
end

function Tests:GetFullyQualifiedNameReturnsEmptyStringForEmptyName()
    AreEqual("", Addon:getFullyQualifiedName(""));
end

function Tests:IsSelfMatchesOnName()
    Replace(Regrowth, 'User', { name = "Player", fqn = "Player-Realm" });

    IsTrue(Addon:isSelf("Player", "SomeoneElse-Realm"));
end

function Tests:IsSelfMatchesOnFqn()
    Replace(Regrowth, 'User', { name = "SomeoneElse", fqn = "Player-Realm" });

    IsTrue(Addon:isSelf("SomeoneElse", "Player-Realm"));
end

function Tests:IsSelfReturnsFalseWhenNeitherMatches()
    Replace(Regrowth, 'User', { name = "Player", fqn = "Player-Realm" });

    IsFalse(Addon:isSelf("Other", "Other-Realm"));
end

function Tests:IsCurrentVersionTrueWhenCurrentMatchesLatest()
    Replace(Regrowth.Data, 'Version', { current = 5, latest = 5 });

    IsTrue(Addon:isCurrentVersion());
end

function Tests:IsCurrentVersionFalseWhenOutOfDate()
    Replace(Regrowth.Data, 'Version', { current = 4, latest = 5 });

    IsFalse(Addon:isCurrentVersion());
end
