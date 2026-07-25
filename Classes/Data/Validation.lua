---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Data.Validation
local Validation = {};

---@type Regrowth.Data.Validation
Regrowth.Data.Validation = Validation;

local function isValidSystemSchema(systemData)
    local function isValidSystemUserSchema(systemUserData)
        if type(systemUserData.id) ~= "string" then
            Regrowth.Utils.Messaging:debug("1.5.1");
            return false;
        end

        if type(systemUserData.name) ~= "string" then
            Regrowth.Utils.Messaging:debug("1.5.2");
            return false;
        end

        return true;
    end

    if type(systemData) ~= "table" then
        Regrowth.Utils.Messaging:debug("1.1");
        return false;
    end

    if not (systemData.date_generated and systemData.user) then
        Regrowth.Utils.Messaging:debug("1.2");
        return false;
    end

    if type(systemData.date_generated) ~= "number" then
        Regrowth.Utils.Messaging:debug("1.3");
        return false;
    end

    if type(systemData.user) ~= "table" then
        Regrowth.Utils.Messaging:debug("1.4");
        return false;
    end

    if not isValidSystemUserSchema(systemData.user) then
        Regrowth.Utils.Messaging:debug("1.5");
        return false;
    end

    return true;
end

local function isValidPrioritiesSchema(prioritiesData)
    local function isValidPrioritiesIndexSchema(prioritiesIndexData)
        if type(prioritiesIndexData.id) ~= "number" then
            Regrowth.Utils.Messaging:debug("2.2.1");
            return false;
        end

        if type(prioritiesIndexData.name) ~= "string" then
            Regrowth.Utils.Messaging:debug("2.2.2");
            return false;
        end

        if type(prioritiesIndexData.icon) ~= "string" and type(prioritiesIndexData.icon) ~= "nil" then
            Regrowth.Utils.Messaging:debug("2.2.3");
            return false;
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(prioritiesData) then
        Regrowth.Utils.Messaging:debug("2.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(prioritiesData) do
        idx = idx + 1;

        if not isValidPrioritiesIndexSchema(prioritiesData[idx]) then
            Regrowth.Utils.Messaging:debug("2.2");
            return false;
        end
    end

    return true;
end

local function isValidItemsSchema(itemsData)
    local function isValidItemsIndexSchema(itemsIndexData)
        local function isValidItemsIndexPrioritySchema(itemsIndexPriorityData)
            if type(itemsIndexPriorityData.priority_id) ~= "number" then
                Regrowth.Utils.Messaging:debug("3.2.4.1");
                return false;
            end

            if type(itemsIndexPriorityData.weight) ~= "number" then
                Regrowth.Utils.Messaging:debug("3.2.4.2");
                return false;
            end

            return true;
        end

        if type(itemsIndexData.item_id) ~= "number" then
            Regrowth.Utils.Messaging:debug("3.2.1");
            return false;
        end

        if type(itemsIndexData.notes) ~= "string" and type(itemsIndexData.notes) ~= "nil" then
            Regrowth.Utils.Messaging:debug("3.2.2");
            return false;
        end

        if not Regrowth.Utils.Table:isArray(itemsIndexData.priorities) then
            Regrowth.Utils.Messaging:debug("3.2.3");
            return false;
        end

        local idx = 0;

        for _ in pairs(itemsIndexData.priorities) do
            idx = idx + 1;

            if not isValidItemsIndexPrioritySchema(itemsIndexData.priorities[idx]) then
                Regrowth.Utils.Messaging:debug("3.2.4");
                return false;
            end
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(itemsData) then
        Regrowth.Utils.Messaging:debug("3.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(itemsData) do
        idx = idx + 1;

        if not isValidItemsIndexSchema(itemsData[idx]) then
            Regrowth.Utils.Messaging:debug("3.2");
            return false;
        end
    end

    return true;
end

local function isValidPlayersSchema(playersData)
    local function isValidPlayersIndexSchema(playerData)
        if type(playerData) ~= "table" then
            Regrowth.Utils.Messaging:debug("4.2.1");
            return false;
        end

        if not (playerData.id and playerData.name and playerData.attendance) then
            Regrowth.Utils.Messaging:debug("4.2.2");
            return false;
        end

        if type(playerData.id) ~= "number" then
            Regrowth.Utils.Messaging:debug("4.2.3");
            return false;
        end

        if type(playerData.name) ~= "string" then
            Regrowth.Utils.Messaging:debug("4.2.4");
            return false;
        end

        if type(playerData.attendance) ~= "table" then
            Regrowth.Utils.Messaging:debug("4.2.5");
            return false;
        end

        if not (playerData.attendance.first_attendance and
                playerData.attendance.attended and
                playerData.attendance.total and
                playerData.attendance.percentage)
        then
            Regrowth.Utils.Messaging:debug("4.2.6");
            return false;
        end

        if type(playerData.attendance.first_attendance) ~= "string" then
            Regrowth.Utils.Messaging:debug("4.2.7");
            return false;
        end

        if type(playerData.attendance.attended) ~= "number" then
            Regrowth.Utils.Messaging:debug("4.2.8");
            return false;
        end

        if type(playerData.attendance.total) ~= "number" then
            Regrowth.Utils.Messaging:debug("4.2.9");
            return false;
        end

        if type(playerData.attendance.percentage) ~= "number" then
            Regrowth.Utils.Messaging:debug("4.2.10");
            return false;
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(playersData) then
        Regrowth.Utils.Messaging:debug("4.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(playersData) do
        idx = idx + 1;

        if not isValidPlayersIndexSchema(playersData[idx]) then
            Regrowth.Utils.Messaging:debug("4.2");
            return false;
        end
    end

    return true;
end

local function isValidCouncillorsSchema(councillorsData)
    local function isValidCouncillorsIndexSchema(councillorData)
        if type(councillorData) ~= "table" then
            Regrowth.Utils.Messaging:debug("5.2.1");
            return false;
        end

        if not (councillorData.id and councillorData.name and councillorData.rank) then
            Regrowth.Utils.Messaging:debug("5.2.2");
            return false;
        end

        if type(councillorData.id) ~= "number" then
            Regrowth.Utils.Messaging:debug("5.2.3");
            return false;
        end

        if type(councillorData.name) ~= "string" then
            Regrowth.Utils.Messaging:debug("5.2.4");
            return false;
        end

        if type(councillorData.rank) ~= "string" then
            Regrowth.Utils.Messaging:debug("5.2.5");
            return false;
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(councillorsData) then
        Regrowth.Utils.Messaging:debug("5.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(councillorsData) do
        idx = idx + 1;

        if not isValidCouncillorsIndexSchema(councillorsData[idx]) then
            Regrowth.Utils.Messaging:debug("5.2");
            return false;
        end
    end

    return true;
end

local function isValidPhasesSchema(phasesData)
    local function isValidPhasesIndexSchema(phaseData)
        if type(phaseData) ~= "table" then
            Regrowth.Utils.Messaging:debug("8.2.1");
            return false;
        end

        if type(phaseData.number) ~= "number" then
            Regrowth.Utils.Messaging:debug("8.2.2");
            return false;
        end

        if type(phaseData.start_date) ~= "number" then
            Regrowth.Utils.Messaging:debug("8.2.3");
            return false;
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(phasesData) then
        Regrowth.Utils.Messaging:debug("8.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(phasesData) do
        idx = idx + 1;

        if not isValidPhasesIndexSchema(phasesData[idx]) then
            Regrowth.Utils.Messaging:debug("8.2");
            return false;
        end
    end

    if idx < 1 then
        Regrowth.Utils.Messaging:debug("8.3");
        return false;
    end

    return true;
end

local function isValidSchema(inputData)
    if type(inputData) ~= "table" then
        Regrowth.Utils.Messaging:debug("0");
        return false;
    end

    if inputData.system and not isValidSystemSchema(inputData.system) then
        Regrowth.Utils.Messaging:debug("1");
        return false;
    end

    if inputData.priorities and not isValidPrioritiesSchema(inputData.priorities) then
        Regrowth.Utils.Messaging:debug("2");
        return false;
    end

    if inputData.items and not isValidItemsSchema(inputData.items) then
        Regrowth.Utils.Messaging:debug("3");
        return false;
    end

    if inputData.players and not isValidPlayersSchema(inputData.players) then
        Regrowth.Utils.Messaging:debug("4");
        return false;
    end

    if inputData.councillors and not isValidCouncillorsSchema(inputData.councillors) then
        Regrowth.Utils.Messaging:debug("5");
        return false;
    end

    if inputData.phases and not isValidPhasesSchema(inputData.phases) then
        Regrowth.Utils.Messaging:debug("8");
        return false;
    end

    return true;
end

local function isValidRCSchema(inputData)
    local function isValidRCIndexSchema(rcIndexData)
        if type(rcIndexData) ~= "table" then
            Regrowth.Utils.Messaging:debug("6.2.1");
            return false;
        end

        if type(rcIndexData.id) ~= "string" and type(rcIndexData.id) ~= "number" then
            Regrowth.Utils.Messaging:debug("6.2.2");
            return false;
        end

        if type(rcIndexData.player) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.3");
            return false;
        end

        if not rcIndexData.player:match("-") then
            Regrowth.Utils.Messaging:debug("6.2.4");
            return false;
        end

        if type(rcIndexData.itemID) ~= "number" then
            Regrowth.Utils.Messaging:debug("6.2.5");
            return false;
        end

        if type(rcIndexData.itemName) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.6");
            return false;
        end

        if type(rcIndexData.itemString) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.7");
            return false;
        end

        if type(rcIndexData.servertime) ~= "number" then
            Regrowth.Utils.Messaging:debug("6.2.8");
            return false;
        end

        if type(rcIndexData.date) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.9");
            return false;
        end

        if type(rcIndexData.time) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.10");
            return false;
        end

        if rcIndexData.response ~= nil and type(rcIndexData.response) ~= "string" then
            Regrowth.Utils.Messaging:debug("6.2.11");
            return false;
        end

        return true;
    end

    if not Regrowth.Utils.Table:isArray(inputData) then
        Regrowth.Utils.Messaging:debug("6.1");
        return false;
    end

    local idx = 0;

    for _ in pairs(inputData) do
        idx = idx + 1;

        if not isValidRCIndexSchema(inputData[idx]) then
            Regrowth.Utils.Messaging:debug("6.2");
            return false;
        end
    end

    return true;
end

local function isValidWishlistsSchema(inputData)
    local function isValidWishlistsItemSchema(itemData)
        if not Regrowth.Utils.Table:isArray(itemData) then
            Regrowth.Utils.Messaging:debug("7.2.1");
            return false;
        end

        for _, nameData in ipairs(itemData) do
            if type(nameData) ~= "string" then
                Regrowth.Utils.Messaging:debug("7.2.2");
                return false;
            end

            if not nameData:match("[^|]+") then
                Regrowth.Utils.Messaging:debug("7.2.3");
                return false;
            end
        end

        return true;
    end

    if type(inputData) ~= "table" then
        Regrowth.Utils.Messaging:debug("7.1");
        return false;
    end

    if type(inputData.wishlists) ~= "table" then
        Regrowth.Utils.Messaging:debug("7.2");
        return false;
    end

    for itemId, itemData in pairs(inputData.wishlists) do
        if not tonumber(itemId) then
            Regrowth.Utils.Messaging:debug("7.3");
            return false;
        end

        if not isValidWishlistsItemSchema(itemData) then
            Regrowth.Utils.Messaging:debug("7.4");
            return false;
        end
    end

    return true;
end

function Validation:IsValidInput(inputData, type)
    if type == "Website" then
        return isValidSchema(inputData);
    end

    if type == "RCLootCouncil" then
        return isValidRCSchema(inputData);
    end

    if type == "Wishlists" then
        return isValidWishlistsSchema(inputData);
    end

    return false;
end

-- Sync payloads carry data that's already been transformed (see
-- Transformers.lua) by the officer who ran the import, so they don't match
-- the raw-import schemas above (those validate pre-transform shapes, e.g.
-- LootReceived import rows vs. the by-player-name map actually stored).
-- These validate the stored/transformed shape instead, just enough to stop
-- a malformed payload from reaching RegrowthData.Storage and crashing
-- readers like Tooltips.lua downstream.
local function isValidSyncSystemData(data)
    return type(data) == "table";
end

local function isValidSyncPrioritiesData(data)
    return Regrowth.Utils.Table:isArray(data);
end

local function isValidSyncItemsData(data)
    return Regrowth.Utils.Table:isArray(data);
end

local function isValidSyncPlayersData(data)
    return Regrowth.Utils.Table:isArray(data);
end

local function isValidSyncLootCouncilData(data)
    return type(data) == "string" or Regrowth.Utils.Table:isArray(data);
end

local function isValidSyncLootReceivedData(data)
    if type(data) ~= "table" then
        return false;
    end

    for _, entries in pairs(data) do
        if not Regrowth.Utils.Table:isArray(entries) then
            return false;
        end
    end

    return true;
end

local function isValidSyncWishlistsData(data)
    return Regrowth.Utils.Table:isArray(data);
end

local function isValidSyncPhasesData(data)
    return Regrowth.Utils.Table:isArray(data);
end

-- Per-table validators, keyed the same way as RegrowthData.Storage, used
-- to sanity-check incoming comm-sync payloads (which arrive one table at
-- a time, already transformed) before they're written to storage.
local SYNC_TABLE_VALIDATORS = {
    System = isValidSyncSystemData,
    Priorities = isValidSyncPrioritiesData,
    Items = isValidSyncItemsData,
    Players = isValidSyncPlayersData,
    LootCouncil = isValidSyncLootCouncilData,
    LootReceived = isValidSyncLootReceivedData,
    Wishlists = isValidSyncWishlistsData,
    Phases = isValidSyncPhasesData,
};

function Validation:IsValidSyncTableData(tableName, data)
    local validator = SYNC_TABLE_VALIDATORS[tableName];

    if not validator then
        return false;
    end

    return validator(data);
end
