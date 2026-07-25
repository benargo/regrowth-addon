---@type Regrowth
local _, Regrowth = ...;

local defaultTabulatedData = {
    data = {},
    timestamp = 0,
}

local defaultStringData = {
    data = "",
    timestamp = 0,
}

---@class Regrowth.Data
local RegrowthData = {
    _initialized = false,
    Constants = {
        Comm = {
            channel = "RGLT_Channel",

            Actions = {
                nex = 1,
                handlereceiveddata = 2,
                versionannounce = 3,
            },
        },
    },
    Version = {
        current = "0.0",
        latest = "0.8.0-beta.1",
    },
    Storage = {
        LootCouncil = defaultStringData,
        System = defaultTabulatedData,
        Priorities = defaultTabulatedData,
        Items = defaultTabulatedData,
        Players = defaultTabulatedData,
        LootReceived = defaultTabulatedData,
        Wishlists = defaultTabulatedData,
        Phases = defaultTabulatedData
    }
};

---@type Regrowth.Data
Regrowth.Data = RegrowthData;

local function isOlderData(input, current)
    if input > current then
        return false;
    end

    return true;
end

local function UpdateSystem(systemData)
    if isOlderData(systemData.timestamp, RegrowthData.Storage.System.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'System' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'System'...");

    RegrowthData.Storage.System = systemData;

    return true;
end

local function UpdatePhases(phasesData)
    if isOlderData(phasesData.timestamp, RegrowthData.Storage.Phases.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'Phases' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'Phases'...");

    -- Map to our internal shape and sort oldest-first, so we can derive
    -- each phase's end_date as "1 second before the next phase starts" -
    -- the website only gives us start dates, not end dates.
    local mappedPhases = {};

    for _, phase in ipairs(phasesData.data) do
        table.insert(mappedPhases, {
            phase_number = phase.number,
            start_date = phase.start_date,
        });
    end

    table.sort(mappedPhases, function(a, b)
        return a.start_date < b.start_date;
    end);

    for i = 1, #mappedPhases - 1 do
        mappedPhases[i].end_date = mappedPhases[i + 1].start_date - 1;
    end
    -- The newest phase (last after this ascending sort) gets no end_date -
    -- it's still ongoing.

    -- Now flip to newest-first, so [1] is always "current" and [2] is
    -- always "previous", regardless of how many phases were provided.
    local sortedPhases = {};

    for i = #mappedPhases, 1, -1 do
        table.insert(sortedPhases, mappedPhases[i]);
    end

    RegrowthData.Storage.Phases = {
        data = sortedPhases,
        timestamp = phasesData.timestamp,
    };

    return true;
end

local function UpdatePriorities(prioritiesData)
    if isOlderData(prioritiesData.timestamp, RegrowthData.Storage.Priorities.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'Priorities' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'Priorities'...");

    RegrowthData.Storage.Priorities = prioritiesData;

    return true;
end

local function UpdateItems(itemsData)
    if isOlderData(itemsData.timestamp, RegrowthData.Storage.Items.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'Items' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'Items'...");

    local transformedItemsData = RegrowthData.Transformers:TransformItemsData(itemsData.data);

    RegrowthData.Storage.Items = {
        data = transformedItemsData,
        timestamp = itemsData.timestamp,
    };

    return true;
end

local function UpdatePlayers(playersData)
    if isOlderData(playersData.timestamp, RegrowthData.Storage.Players.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'Players' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'Players'...");

    RegrowthData.Storage.Players = playersData;

    return true;
end

local function UpdateLootCouncil(lootCouncilData)
    if isOlderData(lootCouncilData.timestamp, RegrowthData.Storage.LootCouncil.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'LootCouncil' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'LootCouncil'...");

    local transformedLootCouncilData = RegrowthData.Transformers:TransformLootCouncillors(lootCouncilData.data);

    RegrowthData.Storage.LootCouncil = {
        data = transformedLootCouncilData,
        timestamp = lootCouncilData.timestamp
    };

    return true;
end

local function UpdateLootReceivedData(lootReceivedData)
    if isOlderData(lootReceivedData.timestamp, RegrowthData.Storage.LootReceived.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'LootReceived' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'LootReceived'...");

    local transformedLootReceivedData = RegrowthData.Transformers:TransformedLootReceivedData(lootReceivedData.data);

    RegrowthData.Storage.LootReceived = {
        data = transformedLootReceivedData,
        timestamp = lootReceivedData.timestamp
    }

    return true;
end

local function UpdateWishlistsData(wishlistsData)
    if isOlderData(wishlistsData.timestamp, RegrowthData.Storage.Wishlists.timestamp) then
        Regrowth.Utils.Messaging:debug("Update for 'Wishlists' skipped - current data is already current or newer.");
        return false;
    end

    Regrowth.Utils.Messaging:debug("Updating 'Wishlists'...");

    local transformedWishlistsData = RegrowthData.Transformers:TransformWishlistsData(wishlistsData.data);

    RegrowthData.Storage.Wishlists = {
        data = transformedWishlistsData,
        timestamp = wishlistsData.timestamp
    }

    return true;
end

local function UpdateProtectedData(newData, table)
    if (table == "Priorities") then
        return UpdatePriorities(newData);
    end

    if (table == "Items") then
        return UpdateItems(newData);
    end

    if (table == "Players") then
        return UpdatePlayers(newData);
    end

    if (table == "LootCouncil") then
        return UpdateLootCouncil(newData);
    end

    if (table == "LootReceived") then
        return UpdateLootReceivedData(newData);
    end

    if (table == "Wishlists") then
        return UpdateWishlistsData(newData);
    end

    if (table == "Phases") then
        return UpdatePhases(newData);
    end
end

local function UpdateOpenData(newData, table)
    if (table == "System") then
        return UpdateSystem(newData);
    end
end

local function UpdateLocalDataFromSync(data, table)
    if type(data) ~= "table" then
        Regrowth.Utils.Messaging:error("Sync update for '" .. table .. "' rejected - malformed payload.");
        return false;
    end

    if not RegrowthData.Validation:IsValidSyncTableData(table, data.data) then
        Regrowth.Utils.Messaging:error("Sync update for '" .. table .. "' rejected - failed schema validation.");
        return false;
    end

    local currentData = RegrowthData.Storage[table];
    local currentTimestamp = currentData and currentData.timestamp or 0;
    local incomingTimestamp = data.timestamp or 0;

    if isOlderData(incomingTimestamp, currentTimestamp) then
        -- Routine and expected (e.g. two officers' data already agreeing) -
        -- not worth alarming the player with a visible message every time.
        Regrowth.Utils.Messaging:debug("Sync update for '" .. table .. "' skipped - local data is already current.");
        return false;
    end

    RegrowthData.Storage[table] = data;

    RegrowthData:UpdateLocalSavedData();

    return true;
end

function RegrowthData:UpdateLocalData(newData, table, timestamp)
    if (table ~= "System" and
            table ~= "Priorities" and
            table ~= "Items" and
            table ~= "Players" and
            table ~= "LootCouncil" and
            table ~= "LootReceived" and
            table ~= "Wishlists" and
            table ~= "Phases")
    then
        Regrowth.Utils.Messaging:error("Invalid table '" .. table .. "'.");
        return;
    end

    local mappedData = {
        data = newData,
        timestamp = timestamp or GetServerTime(),
    };

    if (table == "Priorities" or
            table == "Items" or
            table == "Players" or
            table == "LootCouncil" or
            table == "LootReceived" or
            table == "Wishlists" or
            table == "Phases")
    then
        return UpdateProtectedData(mappedData, table);
    end

    return UpdateOpenData(mappedData, table);
end

function RegrowthData:UpdateLocalSavedData()
    if not Regrowth.Addon:isCurrentVersion() then
        Regrowth.Utils.Messaging:warning("Can't update local Regrowth_Data - Version out of date.");
        return;
    end

    Regrowth_Data = self.Storage;
end

function RegrowthData:UpdateLocalDataAndSave(newData, table, timestamp)
    if not Regrowth.Addon:isCurrentVersion() then
        Regrowth.Utils.Messaging:warning("Can't update local Regrowth_Data - Version out of date.");
        return false;
    end

    local applied = self:UpdateLocalData(newData, table, timestamp);

    self:UpdateLocalSavedData();

    return applied and true or false;
end

function RegrowthData:UpdateLocalProtectedDataFromSync(newData)
    if not Regrowth.Addon:isCurrentVersion() then
        Regrowth.Utils.Messaging:warning("Can't update local Regrowth_Data - Version out of date.");
        return 0, 0;
    end

    local appliedCount = 0;
    local totalCount = 0;

    local function tryUpdate(key)
        if newData[key] then
            totalCount = totalCount + 1;

            Regrowth.Utils.Messaging:debug("New '" .. key .. "' data received. Updating...");

            if UpdateLocalDataFromSync(newData[key], key) then
                appliedCount = appliedCount + 1;
            end
        end
    end

    tryUpdate("System");
    tryUpdate("Priorities");
    tryUpdate("Items");
    tryUpdate("Players");
    tryUpdate("LootCouncil");
    tryUpdate("LootReceived");
    tryUpdate("Wishlists");
    tryUpdate("Phases");

    return appliedCount, totalCount;
end

function RegrowthData:UpdateLocalOpenDataFromSync(newData)
    if not Regrowth.Addon:isCurrentVersion() then
        Regrowth.Utils.Messaging:warning("Can't update local Regrowth_Data - Version out of date.");
        return 0, 0;
    end

    local appliedCount = 0;
    local totalCount = 0;

    if newData["System"] then
        totalCount = totalCount + 1;

        Regrowth.Utils.Messaging:debug("New 'System' data received. Updating...");

        if UpdateLocalDataFromSync(newData["System"], "System") then
            appliedCount = appliedCount + 1;
        end
    end

    return appliedCount, totalCount;
end

function RegrowthData:UpdateLocalDataAndSaveFromImport(importData, type)
    if not Regrowth.Addon:isCurrentVersion() then
        Regrowth.Utils.Messaging:warning("Can't update local Regrowth_Data - Version out of date.");
        return 0, 0;
    end

    local timestamp = importData.system and importData.system.date_generated or nil;
    local appliedCount = 0;
    local totalCount = 0;

    local function tryImport(field, table)
        if importData[field] then
            totalCount = totalCount + 1;

            if self:UpdateLocalDataAndSave(importData[field], table, timestamp) then
                appliedCount = appliedCount + 1;
            end
        end
    end

    if type == "Website" then
        tryImport("system", "System");
        tryImport("priorities", "Priorities");
        tryImport("items", "Items");
        tryImport("players", "Players");
        tryImport("councillors", "LootCouncil");
        tryImport("phases", "Phases");
    end

    if type == "RCLootCouncil" then
        totalCount = totalCount + 1;

        if self:UpdateLocalDataAndSave(importData, "LootReceived", timestamp) then
            appliedCount = appliedCount + 1;
        end
    end

    if type == "Wishlists" then
        totalCount = totalCount + 1;

        if self:UpdateLocalDataAndSave(importData, "Wishlists", timestamp) then
            appliedCount = appliedCount + 1;
        end
    end

    if appliedCount > 0 then
        -- New data means the data version has changed, which automatically
        -- makes every previously-synced recipient's stored version stale
        -- (see Comm:IsRecipientUpToDate). Give it a couple of minutes
        -- before pushing it out - if another officer imports around the
        -- same time, this delay plus the election means only one of them
        -- ends up syncing it, rather than both immediately racing to send.
        local delay = Regrowth.Comm.IMPORT_DELAY_SECONDS;

        Regrowth.Comm._nextAllowedElectionTime = GetServerTime() + delay;

        Regrowth.Ace:ScheduleTimer(function()
            Regrowth.Comm:StartElection();
        end, delay);
    end

    return appliedCount, totalCount;
end

-- Returns the epoch of the most recent loot entry across every player in
-- LootReceived, i.e. the raid date the last imported loot item was won on -
-- not when the import itself happened.
function RegrowthData:GetLastLootReceivedEpoch()
    local mostRecentEpoch = nil;

    for _, playerEntries in pairs(self.Storage.LootReceived.data) do
        for _, entry in ipairs(playerEntries) do
            if entry.when and entry.when.epoch then
                if not mostRecentEpoch or entry.when.epoch > mostRecentEpoch then
                    mostRecentEpoch = entry.when.epoch;
                end
            end
        end
    end

    return mostRecentEpoch;
end

-- A single number representing "how current is our data overall" - the
-- newest timestamp across every table. Used to decide whether a given
-- recipient's last-known-synced version is already up to date.
function RegrowthData:GetCurrentDataVersion()
    local tables = {
        "System", "Priorities", "Items", "Players",
        "LootCouncil", "LootReceived", "Wishlists", "Phases",
    };

    local newest = 0;

    for _, tableName in ipairs(tables) do
        local tableData = self.Storage[tableName];
        local timestamp = tableData and tableData.timestamp or 0;

        if timestamp > newest then
            newest = timestamp;
        end
    end

    return newest;
end

-- Phases are stored sorted newest-start-first (see UpdatePhases), so [1] is
-- always "current" (newest that hasn't necessarily ended) and [2] is
-- always "previous" (the one directly before it). Returns nil if that
-- phase isn't configured.
-- Phases are stored sorted newest-start-first, but a future-dated phase
-- (e.g. the website pre-populating a phase that hasn't actually started
-- yet) shouldn't count as "current" until its start_date has actually
-- passed. Evaluated live against the current time on every call, rather
-- than baked in at import time, so a phase correctly becomes current the
-- moment its date arrives - no fresh sync needed.
function RegrowthData:GetCurrentPhase()
    local phases = self.Storage.Phases.data;
    local now = GetServerTime();

    for _, phase in ipairs(phases) do
        if phase.start_date <= now then
            return phase;
        end
    end

    return nil;
end

function RegrowthData:GetPreviousPhase()
    local phases = self.Storage.Phases.data;
    local now = GetServerTime();

    for i, phase in ipairs(phases) do
        if phase.start_date <= now then
            return phases[i + 1];
        end
    end

    return nil;
end

local function epochFallsInPhase(epoch, phase)
    if not phase or not epoch then
        return false;
    end

    if epoch < phase.start_date then
        return false;
    end

    if phase.end_date and epoch > phase.end_date then
        return false;
    end

    return true;
end

-- Given a player's LootReceived entries (the array under LootReceived.data
-- for one name), returns how many fall in the current phase and how many
-- fall in the previous phase, based on each entry's when.epoch.
function RegrowthData:GetPhaseLootCounts(playerEntries)
    local currentPhase = self:GetCurrentPhase();
    local previousPhase = self:GetPreviousPhase();

    local counts = {
        current = 0,
        previous = 0,
    };

    if not playerEntries then
        return counts;
    end

    for _, entry in ipairs(playerEntries) do
        local epoch = entry.when and entry.when.epoch;

        if epochFallsInPhase(epoch, currentPhase) then
            counts.current = counts.current + 1;
        elseif epochFallsInPhase(epoch, previousPhase) then
            counts.previous = counts.previous + 1;
        end
    end

    return counts;
end

-- The effective loot council receiver list: every current guild officer
-- (recalculated live, so promotions/demotions apply automatically) plus
-- anyone manually added via the in-game "Additional Members" box or a
-- Website import, de-duplicated. This is what auto-sync and the manual
-- sync commands should actually iterate, rather than reading
-- Storage.LootCouncil.data directly.
function RegrowthData:GetLootCouncilReceivers()
    local receivers = {};
    local seen = {};

    for _, officerName in ipairs(Regrowth.Guild:getAllGuildOfficerNames()) do
        if not seen[officerName] then
            seen[officerName] = true;
            table.insert(receivers, officerName);
        end
    end

    for name in self.Storage.LootCouncil.data:gmatch("[^,]+") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "");

        if name ~= "" and not seen[name] then
            seen[name] = true;
            table.insert(receivers, name);
        end
    end

    return receivers;
end

function RegrowthData:GetImportType(importData)
    if importData.system then
        return "Website";
    end

    if importData.wishlists then
        return "Wishlists";
    end

    return "RCLootCouncil";
end

function RegrowthData:_init()
    if (self._initialized) then
        return;
    end

    self.Version.current = C_AddOns.GetAddOnMetadata(Regrowth.name, "Version") or self.Version.current;

    if not Regrowth.Utils.Table:empty(Regrowth_Data) then
        self.Storage = Regrowth_Data
    else
        Regrowth_Data = self.Storage;
    end

    self.Storage.LootCouncil = self.Storage.LootCouncil or defaultStringData;
    self.Storage.System = self.Storage.System or defaultTabulatedData;
    self.Storage.Priorities = self.Storage.Priorities or defaultTabulatedData;
    self.Storage.Items = self.Storage.Items or defaultTabulatedData;
    self.Storage.Players = self.Storage.Players or defaultTabulatedData;
    self.Storage.LootReceived = self.Storage.LootReceived or defaultTabulatedData;
    self.Storage.Wishlists = self.Storage.Wishlists or defaultTabulatedData;
    self.Storage.Phases = self.Storage.Phases or defaultTabulatedData;

    self._initialized = true;
end
