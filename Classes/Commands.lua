local _, Regrowth = ...;

---@type RegrowthData
local RegrowthData = Regrowth.Data;

---@class Commands
local Commands = {
    nex = function()
        Regrowth.Comm.Message.new(
            RegrowthData.Constants.Comm.Actions.nex,
            "Nex says hi (>^.^<)",
            "GUILD"
        ):send();
    end,
    togglemainui = function()
        Regrowth.Frames:ToggleMainUIFrame();
    end,
    senddatasync = function()
        if C_GuildInfo.IsGuildOfficer() then
            -- Manual command is an explicit override - always allowed to
            -- run regardless of what the election decided.
            Regrowth.Comm._isActiveSyncer = true;

            local receivers = RegrowthData:GetLootCouncilReceivers();

            for _, receiver in ipairs(receivers) do
                if not Regrowth.Utils.String:iEquals(receiver, Regrowth.User.name) then
                    Regrowth.Comm:QueueSync(receiver);
                end
            end

            return;
        end

        Regrowth.Utils.Messaging:error("You are not authorised to send data.");
    end,
    syncto = function(name)
        if not C_GuildInfo.IsGuildOfficer() then
            Regrowth.Utils.Messaging:error("You are not authorised to send data.");
            return;
        end

        -- Manual command is an explicit override - always allowed to run
        -- regardless of what the election decided.
        Regrowth.Comm._isActiveSyncer = true;

        name = name and strtrim(name) or "";

        if Regrowth.Utils.Table:empty(name) then
            Regrowth.Utils.Messaging:error("Usage: /rg syncto [player name]");
            return;
        end

        local receivers = RegrowthData:GetLootCouncilReceivers();
        local matchedReceiver = nil;

        for _, receiver in ipairs(receivers) do
            if Regrowth.Utils.String:iEquals(receiver, name) then
                matchedReceiver = receiver;
                break;
            end
        end

        if not matchedReceiver then
            Regrowth.Utils.Messaging:error("'" .. name .. "' is not a loot council member.");
            return;
        end

        if Regrowth.Comm:IsRecipientUpToDate(matchedReceiver) then
            Regrowth.Utils.Messaging:warning("'" .. matchedReceiver .. "' already has the current data - nothing to sync.");
            return;
        end

        Regrowth.Comm:QueueSyncPriority(matchedReceiver);

        Regrowth.Utils.Messaging:success("'" .. matchedReceiver .. "' moved to the front of the sync queue.");
    end,
    toggle = function(type)
        if Regrowth_Config.TooltipToggles[type] then
            Regrowth_Config.TooltipToggles[type] = false;
            return;
        end

        if not Regrowth_Config.TooltipToggles[type] then
            Regrowth_Config.TooltipToggles[type] = true;
            return;
        end
    end,
};

local function HookinTime()
    Regrowth.Utils.Messaging:debug("kek");
end

local function _dispatch(str)
    local command = str:match("^(%S+)");
    local argumentStr = "";

    if (command) then
        argumentStr = strsub(str, strlen(command) + 2);
    end

    if (not str or #str < 1) then
        command = "togglemainui";
    end

    command = string.lower(command);

    local args = {};

    args = { strsplit(" ", argumentStr, 1) };

    if (command and Regrowth.Commands[command] and type(Regrowth.Commands[command]) == "function") then
        return Regrowth.Commands[command](unpack(args))
    end
end;

---@type Commands
Regrowth.Commands = Commands;

function Commands:_init()
    Regrowth.Ace:RegisterChatCommand("rg", function(...)
        return _dispatch(...);
    end);

    Regrowth.Ace:RegisterChatCommand("regrowth", function(...)
        return _dispatch(...)
    end)
end

function Commands:call(str)
    return _dispatch(str);
end
