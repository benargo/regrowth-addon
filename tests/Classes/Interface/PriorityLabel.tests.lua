---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Interface.PriorityLabel');
local PriorityLabel = Regrowth.Interface.PriorityLabel;

function Tests:ColorizePriorityLabelColorsRecognizedClassSuffix()
    Replace(_G, 'RAID_CLASS_COLORS', {
        DRUID = { colorStr = "ff7fd94f" },
    });

    AreEqual("|cff7fd94fBalance Druid|r", PriorityLabel:colorizePriorityLabel("Balance Druid"));
end

function Tests:ColorizePriorityLabelLeavesRoleOnlyLabelsUnmodified()
    Replace(_G, 'RAID_CLASS_COLORS', {
        DRUID = { colorStr = "ff7fd94f" },
    });

    AreEqual("Tank", PriorityLabel:colorizePriorityLabel("Tank"));
end

function Tests:ColorizePriorityLabelReturnsNameUnchangedWhenNoClassColorTable()
    Replace(_G, 'RAID_CLASS_COLORS', nil);

    AreEqual("Balance Druid", PriorityLabel:colorizePriorityLabel("Balance Druid"));
end

function Tests:GetClassIconTextForPriorityLabelReturnsIconForRecognizedClass()
    local result = PriorityLabel:getClassIconTextForPriorityLabel("Balance Druid");

    IsTrue(result:find("classicon_druid") ~= nil);
end

function Tests:GetClassIconTextForPriorityLabelReturnsEmptyForRoleOnlyLabel()
    AreEqual("", PriorityLabel:getClassIconTextForPriorityLabel("Tank"));
end

function Tests:GetPriorityIconTextReturnsEmptyForEmptyIcon()
    AreEqual("", PriorityLabel:getPriorityIconText(""));
end

function Tests:GetPriorityIconTextWrapsIconName()
    local result = PriorityLabel:getPriorityIconText("classicon_druid");

    IsTrue(result:find("classicon_druid") ~= nil);
end
