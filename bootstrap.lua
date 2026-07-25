-- Regrowth Loot Tool - Core Logic
-- Version 1.14 (Robust Identification & TBC Fix)

---@class Regrowth
local Regrowth;

---@type string
local appName;
appName, Regrowth = ...;

-- Initialize Persistent Storage
Regrowth_Data = Regrowth_Data or {};
Regrowth_Config = Regrowth_Config or {
    TooltipToggles = {
        bias = false,
        players = false,
        wishlist = false,
    },
    Activity = {
        lastSyncSent = 0,
        lastSyncReceived = 0,
    },
    -- Persists which data version (see RegrowthData:GetCurrentDataVersion)
    -- was last successfully sent to each loot council member, so auto-sync
    -- doesn't re-send unchanged data across logins/reloads. Keyed by
    -- character name, value is the data version number they received.
    SyncedRecipients = {},
};

-- Guards against players upgrading from an older saved-variables file that
-- predates these tables existing.
Regrowth_Config.Activity = Regrowth_Config.Activity or {
    lastSyncSent = 0,
    lastSyncReceived = 0,
};
Regrowth_Config.SyncedRecipients = Regrowth_Config.SyncedRecipients or {};

Regrowth.name = appName;
Regrowth._initialized = false;
Regrowth.EventFrame = nil;

Regrowth.Ace = LibStub("AceAddon-3.0"):NewAddon(Regrowth.name, "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0");

---@type AceGUI-3.0
Regrowth.AceGUI = LibStub("AceGUI-3.0");

Regrowth.Settings = {
    DebugMode = "off"
};

function Regrowth:_init()
    self.Data:_init();
    self.Commands:_init();
    self.Frames:_init();
    self.Tooltips:_init();
    self.User:_init();
    self.Comm:_init();
end

function Regrowth:bootstrap(_, _, addonName)
    if (self._initialized) then
        return;
    end

    if (addonName ~= self.name) then
        return;
    end

    self.EventFrame:UnregisterEvent("ADDON_LOADED");

    self:_init();

    Regrowth:success("v" .. Regrowth.Data.Version.current .. " - Ready. Run /regrowth to start.");

    self._initialized = true;
end

-- Auto-sync: ask the client for a fresh guild roster on login/reload, then
-- give it a couple of minutes before this client is allowed to announce
-- itself in the sync election - avoids every officer's client reacting
-- the instant everyone logs in around the same time.
function Regrowth:onPlayerEnteringWorld()
    if not self._initialized then
        return;
    end

    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster();
    end

    local delay = self.Comm.STARTUP_DELAY_SECONDS;

    self.Comm._nextAllowedElectionTime = GetServerTime() + delay;

    self.Ace:ScheduleTimer(function()
        Regrowth.Comm:StartElection();
    end, delay);
end

-- Auto-sync: fires whenever the guild roster changes (login/logout,
-- roster requests, etc). Debounced so a burst of roster events (e.g.
-- several people logging in around the same time) triggers one election
-- attempt rather than one per event.
function Regrowth:onGuildRosterUpdate()
    if not self._initialized then
        return;
    end

    if self._rosterDebounceHandle then
        self.Ace:CancelTimer(self._rosterDebounceHandle);
    end

    self._rosterDebounceHandle = self.Ace:ScheduleTimer(function()
        Regrowth.Comm:StartElection();
    end, self.Comm.ROSTER_DEBOUNCE_SECONDS);
end

Regrowth.EventFrame = CreateFrame("FRAME", "Regrowth_EventFrame");
Regrowth.EventFrame:RegisterEvent("ADDON_LOADED");
Regrowth.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
Regrowth.EventFrame:RegisterEvent("GUILD_ROSTER_UPDATE");
Regrowth.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        Regrowth:bootstrap(self, event, ...);
        return;
    end

    if event == "PLAYER_ENTERING_WORLD" then
        Regrowth:onPlayerEnteringWorld();
        return;
    end

    if event == "GUILD_ROSTER_UPDATE" then
        Regrowth:onGuildRosterUpdate();
        return;
    end
end);
