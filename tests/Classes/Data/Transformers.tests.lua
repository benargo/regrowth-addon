---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Data.Transformers');
local Transformers = Regrowth.Data.Transformers;

-- TransformItemsData

function Tests:TransformItemsDataMapsPriorityIdsToNamesAndSortsByWeight()
    Replace(_G, 'Regrowth_Data', {
        Priorities = {
            data = {
                { id = 1, name = "Balance Druid" },
                { id = 2, name = "Tank" },
            },
        },
    });
    Replace(_G, 'RAID_CLASS_COLORS', {});

    local itemsData = {
        {
            item_id = 1,
            priorities = {
                { priority_id = 2, weight = 2 },
                { priority_id = 1, weight = 1 },
            },
        },
    };

    local result = Transformers:TransformItemsData(itemsData);

    IsFalse(result[1].priorities ~= nil);
    IsTrue(result[1].text:find("Balance Druid") ~= nil);
    IsTrue(result[1].text:find("Tank") ~= nil);
end

function Tests:TransformItemsDataDefaultsToMsOsWhenNoPrioritiesConfigured()
    Replace(_G, 'Regrowth_Data', { Priorities = { data = {} } });

    local itemsData = {
        { item_id = 1, priorities = {} },
    };

    local result = Transformers:TransformItemsData(itemsData);

    AreEqual("MS > OS", result[1].text);
end

-- TransformLootCouncillors

function Tests:TransformLootCouncillorsJoinsCsvString()
    AreEqual("Alice, Bob", Transformers:TransformLootCouncillors(" Alice ,  Bob "));
end

function Tests:TransformLootCouncillorsIgnoresEmptyCsvEntries()
    AreEqual("Alice, Bob", Transformers:TransformLootCouncillors("Alice,,Bob,"));
end

function Tests:TransformLootCouncillorsJoinsArrayOfObjects()
    AreEqual("Alice, Bob", Transformers:TransformLootCouncillors({ { name = "Alice" }, { name = "Bob" } }));
end

-- TransformedLootReceivedData (via the public entry point, which also
-- filters duplicates and merges against existing stored data)

function Tests:TransformedLootReceivedDataGroupsByPlayerAndExcludesDisenchantOffspec()
    Replace(_G, 'Regrowth_Data', { LootReceived = { data = {} } });

    local input = {
        {
            id = "1", player = "Alice-Realm", response = "Need",
            servertime = 100, time = "12:00", date = "2024-01-01",
            itemName = "Sword", itemID = 1, itemString = "item:1",
        },
        {
            id = "2", player = "Alice-Realm", response = "Disenchant",
            servertime = 200, time = "12:05", date = "2024-01-01",
            itemName = "Axe", itemID = 2, itemString = "item:2",
        },
        {
            id = "3", player = "Bob-Realm", response = "offspec",
            servertime = 150, time = "12:02", date = "2024-01-01",
            itemName = "Bow", itemID = 3, itemString = "item:3",
        },
    };

    local result = Transformers:TransformedLootReceivedData(input);

    AreEqual(1, #result["Alice"]);
    AreEqual("Sword", result["Alice"][1].item.name);
    IsFalse(result["Bob"] ~= nil);
end

function Tests:TransformedLootReceivedDataFiltersDuplicatesAgainstExistingData()
    Replace(_G, 'Regrowth_Data', {
        LootReceived = {
            data = {
                Alice = { { id = "1", when = { epoch = 50 } } },
            },
        },
    });

    local input = {
        {
            id = "1", player = "Alice-Realm", response = "Need",
            servertime = 100, time = "12:00", date = "2024-01-01",
            itemName = "Sword", itemID = 1, itemString = "item:1",
        },
    };

    local result = Transformers:TransformedLootReceivedData(input);

    AreEqual(1, #result["Alice"]);
end

-- TransformWishlistsData

function Tests:TransformWishlistsDataCapitalizesNameAndExtractsPosition()
    local input = { wishlists = { [123] = { "alice|1" } } };

    local result = Transformers:TransformWishlistsData(input);

    AreEqual(123, result[1].itemId);
    AreEqual("Alice", result[1].wantedBy[1].name);
    AreEqual("1", result[1].wantedBy[1].position);
end

function Tests:TransformWishlistsDataSkipsNamesWithParentheses()
    local input = { wishlists = { [123] = { "alice(alt)|1" } } };

    local result = Transformers:TransformWishlistsData(input);

    AreEqual(0, #result[1].wantedBy);
end
