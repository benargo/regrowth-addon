---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Data.Transformers
local Transformers = {};

---@type Regrowth.Data.Transformers
Regrowth.Data.Transformers = Transformers;

local function GetPriorityForId(priorityData)
    local pID = priorityData.priority_id;
    local weight = priorityData.weight;

    if Regrowth:empty(Regrowth_Data.Priorities.data) then
        return {
            priority_id = pID,
            weight = weight,
            name = "MS > OS",
        };
    end

    local priority = Regrowth:findByKeyInArray(Regrowth_Data.Priorities.data, "id", pID);

    return {
        priority_id = pID,
        weight = weight,
        name = priority.name,
        icon = priority.icon,
    };
end

local function GetIconTextForPriority(priorityEntry)
    -- The website already supplies a spec-specific icon per priority (e.g.
    -- "Protection Paladin" gets its own icon, not just a generic Paladin
    -- one) - use that directly whenever it's present. Only fall back to a
    -- class-detected generic icon if it's missing.
    if not Regrowth:empty(priorityEntry.icon) then
        return Regrowth:getPriorityIconText(priorityEntry.icon);
    end

    return Regrowth:getClassIconTextForPriorityLabel(priorityEntry.name);
end

local function CreatePriorityTextFromWeightings(priorityData)
    if not priorityData or #priorityData == 0 then
        return "MS > OS";
    end

    local text = "";
    local prevWeight = -1;

    for idx in ipairs(priorityData) do
        local label = GetIconTextForPriority(priorityData[idx]) ..
            Regrowth:colorizePriorityLabel(priorityData[idx].name);

        if text == "" then
            text = label;
        else
            if prevWeight == priorityData[idx].weight then
                text = text .. " = " .. label;
            else
                text = text .. " > " .. label;
            end
        end

        prevWeight = priorityData[idx].weight;
    end

    return text;
end

local function TransformItemsDataWithPriorities(itemsData)
    for iIdx, itemData in ipairs(itemsData) do
        for pIdx, priorityData in ipairs(itemData.priorities) do
            local mappedPriority = GetPriorityForId(priorityData);

            itemsData[iIdx].priorities[pIdx] = mappedPriority
        end

        table.sort(itemsData[iIdx].priorities, function(k1, k2)
            return k1.weight < k2.weight;
        end);

        itemsData[iIdx].text = CreatePriorityTextFromWeightings(itemsData[iIdx].priorities);
        itemsData[iIdx].priorities = nil;
    end

    return itemsData;
end

local function TransformLootCouncilToCSL(lootCouncilData)
    -- Already a plain CSV string, e.g. typed directly into the in-game
    -- Loot Council tab - just clean up spacing/empty entries rather than
    -- treating it as an array of {name=...} objects like a Website import
    -- provides.
    if type(lootCouncilData) == "string" then
        local names = {};

        for name in lootCouncilData:gmatch("[^,]+") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "");

            if name ~= "" then
                table.insert(names, name);
            end
        end

        return table.concat(names, ", ");
    end

    local csl = nil;

    for _, lootCouncilData in ipairs(lootCouncilData) do
        if not csl then
            csl = lootCouncilData.name;
        else
            csl = csl .. ", " .. lootCouncilData.name;
        end
    end

    return csl;
end

local function TransformedLootReceivedData(lootReceivedData)
    local filteredData = {};

    for _, lrData in ipairs(lootReceivedData) do
        if lrData.response ~= "Disenchant" or lrData.response ~= "offspec" then
            local playerName = lrData.player:match("(.+)-");

            if not filteredData[playerName] then
                filteredData[playerName] = {};
            end

            table.insert(filteredData[playerName], {
                id = lrData.id,
                when = {
                    epoch = lrData.servertime,
                    time = lrData.time,
                    date = lrData.date
                },
                item = {
                    name = lrData.itemName,
                    id = lrData.itemID,
                    link = lrData.itemString
                }
            });
        end
    end

    return filteredData;
end

local function FilterNewLootReceivedData(transformedData)
    local lrData = Regrowth_Data.LootReceived.data;
    local merged = {};

    for name, nameData in pairs(transformedData) do
        if not merged[name] then
            merged[name] = {};
        end

        for _, data in ipairs(nameData) do
            if lrData[name] then
                if Regrowth:findByKeyInArray(lrData[name], "id", data.id) then
                    Regrowth:debug("Duplicate entry '" .. data.id .. "' found. Ignoring.");
                else
                    table.insert(merged[name], data);
                end
            else
                table.insert(merged[name], data);
            end
        end
    end

    return merged;
end

local function MergeLootReceivedData(filteredData)
    local newData = Regrowth:deepCopyTable(Regrowth_Data.LootReceived.data);

    for name, nameData in pairs(filteredData) do
        if not newData[name] then
            newData[name] = {};
        end

        for _, data in ipairs(nameData) do
            table.insert(newData[name], data);
        end

        table.sort(newData[name], function(k1, k2)
            return k1.when.epoch > k2.when.epoch;
        end);
    end

    return newData;
end

local function TransformWishlistsData(wishlistsData)
    local wl = wishlistsData.wishlists;

    local transformed = {};

    for itemId, itemData in pairs(wl) do
        local wantedBy = {};

        for _, nameData in ipairs(itemData) do
            local matches = {};

            for m in string.gmatch(nameData, "([^|]+)") do
                table.insert(matches, m);
            end

            local name = matches[1]:sub(1, 1):upper() .. matches[1]:sub(2);
            local position = matches[2];

            local dodgyName = string.match(name, "%(.+%)");

            if dodgyName then
                Regrowth:warning("Not adding '" ..
                name .. "' due to unexpected characters in character name. Please check wishlist.");
            else
                table.insert(wantedBy, {
                    name = name,
                    position = position
                });
            end
        end

        table.insert(transformed, {
            itemId = tonumber(itemId),
            wantedBy = wantedBy,
        });
    end

    return transformed;
end

function Transformers:TransformItemsData(itemsData)
    return TransformItemsDataWithPriorities(itemsData);
end

function Transformers:TransformLootCouncillors(lootCouncilData)
    return TransformLootCouncilToCSL(lootCouncilData);
end

function Transformers:TransformedLootReceivedData(lootReceivedData)
    local transformedData = TransformedLootReceivedData(lootReceivedData);
    local filteredData = FilterNewLootReceivedData(transformedData);

    return MergeLootReceivedData(filteredData);
end

function Transformers:TransformWishlistsData(wishlistsData)
    return TransformWishlistsData(wishlistsData);
end
