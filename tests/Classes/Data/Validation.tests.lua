---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Data.Validation');
local Validation = Regrowth.Data.Validation;

local function validWebsiteInput()
    return {
        system = {
            date_generated = 12345,
            user = { id = "1", name = "Player" },
        },
        priorities = {
            { id = 1, name = "Balance Druid", icon = "spell_nature_starfall" },
        },
        items = {
            {
                item_id = 1001,
                notes = "notes",
                priorities = { { priority_id = 1, weight = 5 } },
            },
        },
        players = {
            {
                id = 1,
                name = "Player",
                attendance = {
                    first_attendance = "2024-01-01",
                    attended = 10,
                    total = 12,
                    percentage = 83,
                },
            },
        },
        councillors = {
            { id = 1, name = "Player", rank = "Officer" },
        },
        phases = {
            { number = 1, start_date = 12345 },
        },
    };
end

-- Website schema

function Tests:IsValidInputAcceptsFullyValidWebsitePayload()
    IsTrue(Validation:IsValidInput(validWebsiteInput(), "Website"));
end

function Tests:IsValidInputRejectsNonTableInput()
    IsFalse(Validation:IsValidInput("not a table", "Website"));
end

function Tests:IsValidInputRejectsSystemWithMissingUser()
    local data = validWebsiteInput();
    data.system.user = nil;

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsSystemWithWrongDateType()
    local data = validWebsiteInput();
    data.system.date_generated = "not a number";

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsPrioritiesNotAnArray()
    local data = validWebsiteInput();
    data.priorities = { foo = "bar" };

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsPriorityEntryMissingName()
    local data = validWebsiteInput();
    data.priorities = { { id = 1 } };

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsItemMissingPriorities()
    local data = validWebsiteInput();
    data.items = { { item_id = 1001, notes = "notes" } };

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsPlayerMissingAttendanceFields()
    local data = validWebsiteInput();
    data.players[1].attendance.percentage = nil;

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsCouncillorMissingRank()
    local data = validWebsiteInput();
    data.councillors = { { id = 1, name = "Player" } };

    IsFalse(Validation:IsValidInput(data, "Website"));
end

function Tests:IsValidInputRejectsEmptyPhasesArray()
    local data = validWebsiteInput();
    data.phases = {};

    IsFalse(Validation:IsValidInput(data, "Website"));
end

-- RCLootCouncil schema

local function validRCEntry()
    return {
        id = "1",
        player = "Player-Realm",
        itemID = 12345,
        itemName = "Sword",
        itemString = "item:12345",
        servertime = 999,
        date = "2024-01-01",
        time = "12:00",
    };
end

function Tests:IsValidInputAcceptsValidRCLootCouncilPayload()
    IsTrue(Validation:IsValidInput({ validRCEntry() }, "RCLootCouncil"));
end

function Tests:IsValidInputRejectsRCEntryWithPlayerMissingRealmSeparator()
    local entry = validRCEntry();
    entry.player = "PlayerNoRealm";

    IsFalse(Validation:IsValidInput({ entry }, "RCLootCouncil"));
end

function Tests:IsValidInputRejectsRCEntryWithNonStringResponse()
    local entry = validRCEntry();
    entry.response = 5;

    IsFalse(Validation:IsValidInput({ entry }, "RCLootCouncil"));
end

function Tests:IsValidInputAcceptsRCEntryWithNilResponse()
    IsTrue(Validation:IsValidInput({ validRCEntry() }, "RCLootCouncil"));
end

-- Wishlists schema

function Tests:IsValidInputAcceptsValidWishlistsPayload()
    local data = { wishlists = { [123] = { "Player-Realm" } } };

    IsTrue(Validation:IsValidInput(data, "Wishlists"));
end

function Tests:IsValidInputRejectsWishlistsWithNonNumericItemKey()
    local data = { wishlists = { notANumber = { "Player-Realm" } } };

    IsFalse(Validation:IsValidInput(data, "Wishlists"));
end

function Tests:IsValidInputRejectsWishlistsWithNonStringName()
    local data = { wishlists = { [123] = { 456 } } };

    IsFalse(Validation:IsValidInput(data, "Wishlists"));
end

-- Unknown type

function Tests:IsValidInputRejectsUnknownType()
    IsFalse(Validation:IsValidInput({}, "SomeUnknownType"));
end

-- Sync table data validators

function Tests:IsValidSyncTableDataAcceptsArrayForPriorities()
    IsTrue(Validation:IsValidSyncTableData("Priorities", { 1, 2, 3 }));
end

function Tests:IsValidSyncTableDataRejectsNonArrayForPriorities()
    IsFalse(Validation:IsValidSyncTableData("Priorities", { foo = "bar" }));
end

function Tests:IsValidSyncTableDataAcceptsStringOrArrayForLootCouncil()
    IsTrue(Validation:IsValidSyncTableData("LootCouncil", "some-string"));
    IsTrue(Validation:IsValidSyncTableData("LootCouncil", { 1, 2 }));
end

function Tests:IsValidSyncTableDataAcceptsPerPlayerArrayMapForLootReceived()
    IsTrue(Validation:IsValidSyncTableData("LootReceived", { ["Player-Realm"] = { 1, 2 } }));
end

function Tests:IsValidSyncTableDataRejectsLootReceivedWithNonArrayEntries()
    IsFalse(Validation:IsValidSyncTableData("LootReceived", { ["Player-Realm"] = "not an array" }));
end

function Tests:IsValidSyncTableDataRejectsUnknownTableName()
    IsFalse(Validation:IsValidSyncTableData("NotARealTable", {}));
end
