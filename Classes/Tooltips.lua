---@type Regrowth
local _, Regrowth = ...;

---@class Tooltips
local Tooltips = {
    _initialized = false,
};

---@type Tooltips
Regrowth.Tooltips = Tooltips;

local function GetItemId(tooltip)
    local _, link = tooltip:GetItem();
    if not link then
        return;
    end

    local itemID = C_Item.GetItemInfoInstant(link);
    if not itemID then
        return;
    end

    return itemID;
end

local function AddWishlistDataToTooltip(tooltip)
    if not Regrowth_Config.TooltipToggles["wishlist"] and not IsInRaid() then
        return;
    end

    local itemID = GetItemId(tooltip);

    if not itemID then
        return
    end

    local wanted = Regrowth.Utils.Table:findByKeyInArray(Regrowth_Data.Wishlists.data, "itemId", itemID);

    if wanted then
        tooltip:AddLine(" ");
        tooltip:AddLine("Wanted by:", 0.1, 1, 0.6);

        local wantedBy = wanted.wantedBy;

        for _, wantedData in ipairs(wantedBy) do
            tooltip:AddLine(wantedData.name, 1, 1, 1);
        end
    end
end

local function AddRegrowthItemDataToTooltip(tooltip)
    if not Regrowth_Config.TooltipToggles["bias"] and not IsInRaid() then
        return;
    end

    local itemID = GetItemId(tooltip);

    if not itemID then
        return
    end

    local itemDataById = Regrowth.Utils.Table:findByKeyInArray(Regrowth_Data.Items.data, "item_id", itemID);


    if itemDataById and itemDataById.text then
        tooltip:AddLine(" ");
        tooltip:AddLine("Regrowth Bias:", 0.1, 1, 0.6);
        tooltip:AddLine(itemDataById.text, 1, 1, 1, true);
    end
end

local function AddLootReceivedPlayerDataToTooltip(tooltip, name)
    local receivedDataByName = Regrowth.Utils.Table:findByKey(Regrowth_Data.LootReceived.data, name);

    if not receivedDataByName then
        return;
    end

    local lootCount = #receivedDataByName;
    local currentPhase = Regrowth.Data:GetCurrentPhase();
    local previousPhase = Regrowth.Data:GetPreviousPhase();

    -- Total in white, current-phase count in green, previous-phase count
    -- in yellow. Inline colour codes so all three can share one line.
    -- Once phases are configured, "Total" is scoped to just those two
    -- phases (not all-time) - anything from an older phase is disregarded
    -- for both the split and the total. Falls back to the all-time total
    -- if no phases are configured yet at all.
    local totalText;

    if currentPhase or previousPhase then
        local phaseCounts = Regrowth.Data:GetPhaseLootCounts(receivedDataByName);
        local scopedTotal = phaseCounts.current + phaseCounts.previous;

        totalText = "|cffffffff" .. scopedTotal .. "|r";

        if currentPhase then
            totalText = totalText .. " |cff00ff00(P" .. currentPhase.phase_number .. ": " ..
                phaseCounts.current .. ")|r";
        end

        if previousPhase then
            totalText = totalText .. " |cffffff00(P" .. previousPhase.phase_number .. ": " ..
                phaseCounts.previous .. ")|r";
        end
    else
        totalText = "|cffffffffAll Phases " .. lootCount .. "|r";
    end

    tooltip:AddDoubleLine("Total Loot:", totalText, 0.1, 1, 0.6, 1, 1, 1);

    if lootCount > 0 then
        local lastWinEpoch = Regrowth.Utils.Table:findByKey(receivedDataByName[1].when, "epoch");
        tooltip:AddDoubleLine("Last Win:", Regrowth.Utils.DateFormat:formatEpochAsDateOnly(lastWinEpoch), 0.1, 1, 0.6, 1, 1, 1);
    end

end

local function AddRegrowthPlayerDataToTooltip(tooltip)
    if not Regrowth_Config.TooltipToggles["players"] and not IsInRaid() then
        return;
    end

    local name = tooltip:GetUnit();

    local playerDataByName = Regrowth.Utils.Table:findByKeyInArray(Regrowth_Data.Players.data, "name", name);

    if not playerDataByName then
        return;
    end

    local attendance = playerDataByName.attendance.percentage and playerDataByName.attendance.percentage .. "%" or "N/A";

    tooltip:AddLine(" ");
    tooltip:AddLine("Guild Raid Stats:", 0.1, 1, 0.6);
    tooltip:AddDoubleLine("Attendance:", attendance, 1, 1, 1, 1, 1, 1);

    AddLootReceivedPlayerDataToTooltip(tooltip, name);
end

function Tooltips:_init()
    if self._initialized then
        return;
    end

    GameTooltip:HookScript("OnTooltipSetItem", AddRegrowthItemDataToTooltip);
    GameTooltip:HookScript("OnTooltipSetItem", AddWishlistDataToTooltip);
    GameTooltip:HookScript("OnTooltipSetUnit", AddRegrowthPlayerDataToTooltip);

    -- ItemRefTooltip is a separate frame from GameTooltip - it's what
    -- actually renders when clicking an item link in chat, so it needs
    -- its own hooks or bias/wishlist data never shows there.
    if ItemRefTooltip then
        ItemRefTooltip:HookScript("OnTooltipSetItem", AddRegrowthItemDataToTooltip);
        ItemRefTooltip:HookScript("OnTooltipSetItem", AddWishlistDataToTooltip);
    end

    self._initialized = true;
end
