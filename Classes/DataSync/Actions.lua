---@type Regrowth
local _, Regrowth = ...;

---@type Regrowth.Data.Constants.Actions
local Actions = Regrowth.Data.Constants.Comm.Actions or {};

---@class Actions
local CommActions = {
    [Actions.nex] = function(Message)
        Regrowth:success("Message received: " .. Message.content);
    end,
    [Actions.handlereceiveddata] = function(Message)
        if not Message.sender then
            Regrowth:error("Received message from unknown sender. Ignoring.");
            return;
        end

        local ok, appliedCount, totalCount = pcall(function()
            return Regrowth.Data:UpdateLocalProtectedDataFromSync(Message.content);
        end);

        if not ok then
            Regrowth:error("Failed to apply synced data from '" .. Message.sender .. "'. (" .. tostring(appliedCount) .. ")");
            return;
        end

        if not appliedCount or appliedCount == 0 then
            -- Nothing was actually newer than what we already had - routine
            -- and expected (e.g. two officers' data already agreeing), not
            -- worth telling the player anything happened.
            Regrowth:debug("Sync from '" .. Message.sender .. "' had nothing newer to apply.");
            return;
        end

        local elapsedText = "";

        if Message.sentAt then
            local elapsedSeconds = GetServerTime() - Message.sentAt;
            elapsedText = " (took " .. elapsedSeconds .. "s)";
        end

        Regrowth:success("Received updated loot council data from '" .. Message.sender .. "'." .. elapsedText ..
            " Re-hover or reopen if something looks out of date.");

        Regrowth_Config.Activity = Regrowth_Config.Activity or {
            lastSyncSent = 0,
            lastSyncReceived = 0,
        };

        Regrowth_Config.Activity.lastSyncReceived = GetServerTime();
    end,
    [Actions.versionannounce] = function(Message)
        if not Message.sender then
            return;
        end

        Regrowth.Comm:RecordAnnouncedVersion(Message.sender, Message.content);
    end
};

---@class Actions
Regrowth.Comm.Actions = CommActions;
