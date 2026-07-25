---@type Regrowth
local _, Regrowth = ...;

---@class Addon
local Addon = {};

---@type Addon
Regrowth.Addon = Addon;

function Addon:getFullyQualifiedName(name, realm)
    realm = not Regrowth.Utils.Table:empty(realm) and realm or nil;
    name = tostring(name);

    if (Regrowth.Utils.Table:empty(name)) then
        return "";
    end

    local nameHasRealmSeparator = name:match("-");

    if (nameHasRealmSeparator) then
        return name;
    end

    realm = realm or Regrowth.User.realm;
    return ("%s-%s"):format(name, realm), realm;
end

function Addon:isSelf(senderName, senderFqn)
    return Regrowth.Utils.String:iEquals(senderName, Regrowth.User.name)
        or Regrowth.Utils.String:iEquals(senderFqn, Regrowth.User.fqn);
end

function Addon:isCurrentVersion()
    return Regrowth.Data.Version.current and Regrowth.Data.Version.current == Regrowth.Data.Version.latest;
end
