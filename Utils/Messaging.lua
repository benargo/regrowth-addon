---@type Regrowth
local _, Regrowth = ...;

local msgPrefix = "|cff10b981[RegrowthLootTool]|r"

---@class Regrowth.Utils.Messaging
local Messaging = {};
Regrowth.Utils = Regrowth.Utils or {};
Regrowth.Utils.Messaging = Messaging;

function Messaging:message(...)
    print(msgPrefix .. " " .. table.concat({ ... }, " "));
end

function Messaging:coloredMessage(color, ...)
    self:message(string.format("|c00%s%s", color, string.join(" ", ...)));
end

function Messaging:success(...)
    self:coloredMessage("92FF00", ...);
end

function Messaging:warning(...)
    self:coloredMessage("E9D502", ...);
end

function Messaging:error(...)
    self:coloredMessage("BE3333", ...);
end

function Messaging:debug(...)
    if Regrowth.Settings.DebugMode ~= "on" then
        return;
    end

    self:coloredMessage("F7922E", ...);
end
