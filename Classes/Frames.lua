---@type Regrowth
local _, Regrowth = ...;

---@class Frames
local Frames = {
    _initialized = false,
    UIFrame = "closed",
    MainUIFrame = nil
};

---@type Frames
Regrowth.Frames = Frames;

local function SendDataSync()
    Regrowth.Commands:call("senddatasync");
end

local function UpdateLocalLootCouncil(lootCouncil)
    local applied = Regrowth.Data:UpdateLocalDataAndSave(lootCouncil, "LootCouncil");

    if not applied then
        Regrowth:warning("Loot council not updated - your data is already the same or newer.");
        return;
    end

    Regrowth:success("Loot council updated.");

    local delay = Regrowth.Comm.IMPORT_DELAY_SECONDS;

    Regrowth.Comm._nextAllowedElectionTime = GetServerTime() + delay;

    Regrowth.Ace:ScheduleTimer(function()
        Regrowth.Comm:StartElection();
    end, delay);
end

local function UpdateLocalData(importData, type)
    return Regrowth.Data:UpdateLocalDataAndSaveFromImport(importData, type);
end

local function ValidateData(importData, type)
    return Regrowth.Data.Validation:IsValidInput(importData, type);
end

local function GetImportType(importData)
    return Regrowth.Data:GetImportType(importData);
end

local function ToggleConfigOption(toggle)
    Regrowth.Commands:call("toggle " .. toggle);
end

local function CreateMainMenuTab(container)
    local mainMenuHeading = Regrowth.AceGUI:Create("Heading");
    mainMenuHeading:SetText("Regrowth Loot Tool");
    mainMenuHeading:SetFullWidth(true);
    container:AddChild(mainMenuHeading);

    local mainMenuIntro = Regrowth.AceGUI:Create("Label");
    mainMenuIntro:SetText("Addon is currently still in development. Features may not work as expected.");
    mainMenuIntro:SetFullWidth(true);
    container:AddChild(mainMenuIntro);

    local mainMenuCredit = Regrowth.AceGUI:Create("Label");
    mainMenuCredit:SetText("Addon implementation by Amy. Addon protoype and design by SoulJuice. <3");
    mainMenuCredit:SetFullWidth(true);
    container:AddChild(mainMenuCredit);

    local statusSpacer = Regrowth.AceGUI:Create("Label");
    statusSpacer:SetText(" ");
    statusSpacer:SetFullWidth(true);
    statusSpacer:SetHeight(10);
    container:AddChild(statusSpacer);

    Regrowth_Config.Activity = Regrowth_Config.Activity or {
        lastSyncSent = 0,
        lastSyncReceived = 0,
    };

    local lastSyncEpoch = math.max(
        Regrowth_Config.Activity.lastSyncSent or 0,
        Regrowth_Config.Activity.lastSyncReceived or 0
    );

    local lastSyncLabel = Regrowth.AceGUI:Create("Label");
    lastSyncLabel:SetText("Last Sync Received: " .. Regrowth:formatEpochForDisplay(lastSyncEpoch));
    lastSyncLabel:SetFullWidth(true);
    container:AddChild(lastSyncLabel);

    local lastLootImportLabel = Regrowth.AceGUI:Create("Label");
    lastLootImportLabel:SetText("Last Imported Loot Data: " ..
        Regrowth:formatEpochForDisplay(Regrowth.Data:GetLastLootReceivedEpoch()));
    lastLootImportLabel:SetFullWidth(true);
    container:AddChild(lastLootImportLabel);

    local lastPlayerImportLabel = Regrowth.AceGUI:Create("Label");
    lastPlayerImportLabel:SetText("Last Imported Player Data: " ..
        Regrowth:formatEpochForDisplay(Regrowth.Data.Storage.Players.timestamp));
    lastPlayerImportLabel:SetFullWidth(true);
    container:AddChild(lastPlayerImportLabel);

    local spacer = Regrowth.AceGUI:Create("Label");
    spacer:SetText(" ");
    spacer:SetFullWidth(true);
    spacer:SetHeight(10);
    container:AddChild(spacer);

    local mainMenuHeading = Regrowth.AceGUI:Create("Heading");
    mainMenuHeading:SetText("Config");
    mainMenuHeading:SetFullWidth(true);
    container:AddChild(mainMenuHeading);

    local itemTooltipToggle = Regrowth.AceGUI:Create("CheckBox");
    itemTooltipToggle:SetValue(Regrowth_Config.TooltipToggles["bias"]);
    itemTooltipToggle:SetType("checkbox");
    itemTooltipToggle:SetLabel("Display Loot bias tooltips outside of raid.");
    itemTooltipToggle:SetFullWidth(true);
    itemTooltipToggle:SetCallback("OnValueChanged", function (self, e, v)
        ToggleConfigOption("bias");
    end);
    container:AddChild(itemTooltipToggle);

    local playerTooltipToggle = Regrowth.AceGUI:Create("CheckBox");
    playerTooltipToggle:SetValue(Regrowth_Config.TooltipToggles["players"]);
    playerTooltipToggle:SetType("checkbox");
    playerTooltipToggle:SetLabel("Display Player tooltips outside of raid.");
    playerTooltipToggle:SetFullWidth(true);
    playerTooltipToggle:SetCallback("OnValueChanged", function (self, e, v)
        ToggleConfigOption("players");
    end);
    container:AddChild(playerTooltipToggle);

    local wishlistTooltipToggle = Regrowth.AceGUI:Create("CheckBox");
    wishlistTooltipToggle:SetValue(Regrowth_Config.TooltipToggles["wishlist"]);
    wishlistTooltipToggle:SetType("checkbox");
    wishlistTooltipToggle:SetLabel("Display Wishlist tooltips outside of raid.");
    wishlistTooltipToggle:SetFullWidth(true);
    wishlistTooltipToggle:SetCallback("OnValueChanged", function (self, e, v)
        ToggleConfigOption("wishlist");
    end);
    container:AddChild(wishlistTooltipToggle);
end

local function CreateDataSyncTab(container)
    local dataSyncHeading = Regrowth.AceGUI:Create("Heading");
    dataSyncHeading:SetText("Data Sync");
    dataSyncHeading:SetFullWidth(true);
    container:AddChild(dataSyncHeading);

    local desc = Regrowth.AceGUI:Create("Label");
    desc:SetText("Send local data to all valid receivers.");
    desc:SetFullWidth(true);
    container:AddChild(desc);

    local syncDataBtn = Regrowth.AceGUI:Create("Button");
    syncDataBtn:SetText("Send");
    syncDataBtn:SetWidth(200);
    syncDataBtn:SetCallback("OnClick", function()
        SendDataSync();
    end);
    container:AddChild(syncDataBtn);
end

local function GetImportSuccessMessage(type)
    if type == "Website" then
        return "Website data imported.";
    end

    if type == "RCLootCouncil" then
        return "Loot history imported.";
    end

    if type == "Wishlists" then
        return "Wishlist imported.";
    end

    return "Data imported.";
end

local function GetImportSkippedMessage(type)
    if type == "Website" then
        return "Website data not updated - your data is already the same or newer.";
    end

    if type == "RCLootCouncil" then
        return "Loot history not updated - your data is already the same or newer.";
    end

    if type == "Wishlists" then
        return "Wishlist not updated - your data is already the same or newer.";
    end

    return "Data not updated - your data is already the same or newer.";
end

local function CreateImportDataTab(container)
    local importDataHeading = Regrowth.AceGUI:Create("Heading");
    importDataHeading:SetText("Import Data");
    importDataHeading:SetFullWidth(true);
    container:AddChild(importDataHeading);

    local importDataEb = Regrowth.AceGUI:Create("MultiLineEditBox");
    importDataEb:SetFullWidth(true);
    importDataEb:SetNumLines(20);
    importDataEb:SetLabel("");

    local importDataBtn = importDataEb.button;
    importDataBtn:SetText("Save");
    importDataBtn:SetScript("OnClick", function()
        local importData = importDataEb:GetText();
        local jsonAsTable = Regrowth.json.decode(importData);

        local type = GetImportType(jsonAsTable);

        local isValid = ValidateData(jsonAsTable, type);

        if not isValid then
            error("Input data does not match expected schema.");
        end

        local appliedCount, totalCount = UpdateLocalData(jsonAsTable, type);

        importDataEb:ClearFocus();
        importDataBtn:Disable();

        if appliedCount and appliedCount > 0 then
            Regrowth:success(GetImportSuccessMessage(type));
        else
            Regrowth:warning(GetImportSkippedMessage(type));
        end
    end);

    container:AddChild(importDataEb);

    local clearImportBtn = Regrowth.AceGUI:Create("Button");
    clearImportBtn:SetText("Clear");
    clearImportBtn:SetWidth(120);
    clearImportBtn:SetCallback("OnClick", function()
        importDataEb:SetText("");
        importDataEb:ClearFocus();
        importDataBtn:Enable();
    end);
    container:AddChild(clearImportBtn);
end

local function CreateLootCouncilTab(container)
    local lootCouncilHeading = Regrowth.AceGUI:Create("Heading");
    lootCouncilHeading:SetText("Loot Council");
    lootCouncilHeading:SetFullWidth(true);
    container:AddChild(lootCouncilHeading);

    local lootCouncilLbl = Regrowth.AceGUI:Create("Label");
    lootCouncilLbl:SetText(
        "By default, all officers in the guild will be considered part of the loot council.\n\nAdditional members can be added.");
    lootCouncilLbl:SetFullWidth(true);
    container:AddChild(lootCouncilLbl);

    local spacer = Regrowth.AceGUI:Create("Label");
    spacer:SetText(" ");
    spacer:SetFullWidth(true);
    spacer:SetHeight(10);
    container:AddChild(spacer);

    local lootCouncilAdditionalHeading = Regrowth.AceGUI:Create("Heading");
    lootCouncilAdditionalHeading:SetText("Additional Members");
    lootCouncilAdditionalHeading:SetFullWidth(true);
    container:AddChild(lootCouncilAdditionalHeading);

    local lootCouncilAdditionalLbl = Regrowth.AceGUI:Create("Label");
    lootCouncilAdditionalLbl:SetText("Additional character names. Comma separated e.g. \"Nex, Juice\"");
    lootCouncilAdditionalLbl:SetFullWidth(true);
    container:AddChild(lootCouncilAdditionalLbl);

    local lootCouncilAdditionalList = Regrowth.AceGUI:Create("EditBox");
    lootCouncilAdditionalList:SetFullWidth(true);
    lootCouncilAdditionalList:SetMaxLetters(0);
    lootCouncilAdditionalList:SetText(Regrowth.Data.Storage.LootCouncil.data);
    container:AddChild(lootCouncilAdditionalList);

    local lootCouncilSaveBtn = Regrowth.AceGUI:Create("Button");
    lootCouncilSaveBtn:SetText("Save");
    lootCouncilSaveBtn:SetCallback("OnClick", function()
        UpdateLocalLootCouncil(lootCouncilAdditionalList:GetText());
    end);
    container:AddChild(lootCouncilSaveBtn);
end

local function SelectTab(container, _, group)
    container:ReleaseChildren();

    if group == "mainMenu" then
        return CreateMainMenuTab(container);
    end
    if group == "dataSync" then
        return CreateDataSyncTab(container);
    end
    if group == "importData" then
        return CreateImportDataTab(container);
    end
    if group == "lootCouncil" then
        return CreateLootCouncilTab(container);
    end
end

local function CreateTabs()
    if C_GuildInfo.IsGuildOfficer() then
        return {
            { text = "Main Menu",    value = "mainMenu" },
            { text = "Data Sync",    value = "dataSync" },
            { text = "Import data",  value = "importData" },
            { text = "Loot Council", value = "lootCouncil" },
        };
    end

    return {
        { text = "Main Menu", value = "mainMenu" },
    }
end

local function CreateCommunitiesButtonFrame()
    local communitiesButtonFrame = CreateFrame("Button", "Regrowth_CommunitiesButton", CommunitiesFrame.GuildInfoTab,
        "UIPanelButtonTemplate");
    communitiesButtonFrame.Text = communitiesButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontWhiteTiny");
    communitiesButtonFrame.Text:SetPoint("CENTER", communitiesButtonFrame);
    communitiesButtonFrame.Text:SetText("");

    communitiesButtonFrame:SetSize(40, 40);
    communitiesButtonFrame:SetPoint("TOP", 2, -200);
    communitiesButtonFrame:SetNormalTexture("Interface\\AddOns\\RegrowthLootTool\\Icons\\rlt");

    communitiesButtonFrame:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            Regrowth.Frames:ToggleMainUIFrame();
        end
    end);

    return communitiesButtonFrame;
end

local function CreateMainUI()
    local uiFrame = Regrowth.AceGUI:Create("Frame");
    uiFrame:SetTitle("Regrowth Loot Tool");
    uiFrame:SetCallback("OnClose", function(widget)
        Regrowth.AceGUI:Release(widget);
        Regrowth.Frames.UIFrame = "closed";
    end);
    uiFrame:SetLayout("Fill");

    local tabGroup = Regrowth.AceGUI:Create("TabGroup");
    tabGroup:SetLayout("List");
    tabGroup:SetTabs(CreateTabs());
    tabGroup:SetCallback("OnGroupSelected", SelectTab);
    tabGroup:SelectTab("mainMenu");
    uiFrame:AddChild(tabGroup);

    _G["RegrowthMainUIFrame"] = uiFrame.frame;
    tinsert(UISpecialFrames, "RegrowthMainUIFrame");

    return uiFrame;
end

function Frames:ToggleMainUIFrame()
    if self.UIFrame == "closed" then
        self.MainUIFrame = CreateMainUI();
        self.UIFrame = "open";
    else
        self.MainUIFrame:Hide();
        self.UIFrame = "closed";
    end
end

function Frames:_init()
    if (self._initialized) then
        return;
    end

    self.CommunitiesUiButtonFrame = CreateCommunitiesButtonFrame();

    self._initialized = true;
end
