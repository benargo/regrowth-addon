---@type Regrowth
local _, Regrowth = ...;

---@class Comm
local Comm = {
    _initialized = false,
    -- FIFO queue of receiver names waiting for a sync send, processed one
    -- at a time on a timer rather than all in the same tick, to avoid
    -- flooding the addon-message bandwidth throttle (ChatThrottleLib) when
    -- several large whispers would otherwise fire back to back.
    _syncQueue = {},
    _queuedLookup = {},
    _queueRunning = false,
    _queueTimerHandle = nil,

    -- Only the officer holding this becomes true is allowed to actually
    -- run the sync queue - see the election mechanism below.
    _isActiveSyncer = false,

    -- Election state: when multiple officers might sync at once, they
    -- each announce their own data version on GUILD chat and listen for a
    -- short window before deciding who has the newest data and should be
    -- the one to actually sync. Everyone computes the same winner
    -- independently (ties broken alphabetically), so no coordinator is
    -- needed.
    _election = {
        active = false,
        knownVersions = {},
        listenTimerHandle = nil,
    },

    -- Gate for the login/import delay - StartElection no-ops before this.
    _nextAllowedElectionTime = 0,
};

local SYNC_QUEUE_INTERVAL_SECONDS = 2;

-- How long to wait after login, or after importing fresh data, before the
-- first election/sync attempt - gives the guild roster time to populate
-- and avoids every officer's client reacting the instant everyone logs in
-- around the same time.
Comm.STARTUP_DELAY_SECONDS = 120;
Comm.IMPORT_DELAY_SECONDS = 120;

-- How long to listen for other officers' version announcements before
-- deciding who should be the active syncer.
Comm.ELECTION_LISTEN_SECONDS = 8;

-- How long to wait for guild roster events to settle before re-running
-- the election, so a burst of people logging in doesn't trigger a
-- separate election per event.
Comm.ROSTER_DEBOUNCE_SECONDS = 5;

---@type Comm
Regrowth.Comm = Comm;

---@type Regrowth.Data
local RegrowthData = Regrowth.Data;

-- Trusts the same rank-name-based officer definition used everywhere else
-- (see Utils/helpers.lua's OFFICER_RANK_NAMES/getAllGuildOfficerNames),
-- rather than a separate rankOrder-based check, so a sender who's an
-- officer by rank name can't be rejected (or a non-officer wrongly
-- admitted) due to the two mechanisms disagreeing.
local function senderIsOfficer(senderName)
    if type(senderName) ~= "string" or Regrowth:empty(senderName) then
        return false;
    end

    local nameNoRealm = senderName:match("(.+)-") or senderName;

    for _, officerName in ipairs(Regrowth:getAllGuildOfficerNames()) do
        if Regrowth:iEquals(officerName, nameNoRealm) then
            return true;
        end
    end

    return false;
end

function Regrowth.Ace:OnCommReceived(prefix, payload, distribution, sender)
    Regrowth:debug("HELLO");

    payload = Regrowth.Comm.Message:decompress(payload);

    if (not payload) then
        return;
    end

    if (Regrowth:isSelf(payload.sender, payload.senderFqn)) then
        return;
    end

    Regrowth:debug(payload.sender);

    -- `sender` is the identity AceComm itself verified this message came
    -- from; payload.sender/payload.senderFqn are just strings the sender
    -- put in their own message and can set to anything. Validate the
    -- payload's claimed identity against the real `sender` first, so
    -- everything below is checked against a name we know is genuine.
    if (type(payload.senderFqn) ~= "string" or Regrowth:empty(payload.senderFqn)) then
        return;
    end

    local ciSenderFqn = strlower(strtrim(payload.senderFqn));
    local ciPlayerName = strlower(strtrim(sender));

    if (not Regrowth:strStartsWith(ciSenderFqn, ciPlayerName)) then
        return;
    end

    if (not senderIsOfficer(sender)) then
        Regrowth:error("Received message from non-officer. Name = " .. tostring(sender));
        return;
    end

    payload.channel = distribution;

    Comm:dispatch(Regrowth.Comm.Message.newFromReceived(payload));
end

function Comm:_init()
    if (self._initialized) then
        return;
    end

    self.channel = RegrowthData.Constants.Comm.channel;

    Regrowth.Ace:RegisterComm(self.channel);

    self._initialized = true;
end
 
function Comm:send(Message, broadcastFinishedCallback, packageSentCallback)
    local compressed = Regrowth.Comm.Message:compress(Message);

    Regrowth.Ace:SendCommMessage(
        self.channel,
        compressed,
        Message.channel,
        Message.recipient
    );
end

function Comm:dispatch(Message)
    local action = Message.action;

    if (not action) then
        return;
    end

    if (not Regrowth.Comm.Actions[action]) then
        return;
    end

    return Regrowth.Comm.Actions[action](Message);
end

-- Kicks off (or, if one's already in progress, defers to) the election
-- process: announce our own data version to other officers, listen for
-- theirs, and after ELECTION_LISTEN_SECONDS decide who has the newest
-- data and should be the one actively syncing.
function Comm:StartElection()
    if not C_GuildInfo.IsGuildOfficer() then
        return;
    end

    if GetServerTime() < (self._nextAllowedElectionTime or 0) then
        return;
    end

    if self._election.active then
        -- Already mid-election - let it conclude rather than restarting
        -- the listening window from scratch.
        return;
    end

    self._election.active = true;
    self._election.knownVersions = {};

    local myVersion = RegrowthData:GetCurrentDataVersion();

    Regrowth.Comm.Message.new(
        RegrowthData.Constants.Comm.Actions.versionannounce,
        myVersion,
        "GUILD"
    ):send();

    self._election.listenTimerHandle = Regrowth.Ace:ScheduleTimer(function()
        self:ConcludeElection();
    end, self.ELECTION_LISTEN_SECONDS);
end

-- Called whenever another officer's version announcement is received.
function Comm:RecordAnnouncedVersion(sender, version)
    if not C_GuildInfo.IsGuildOfficer() then
        return;
    end

    if not version then
        return;
    end

    self._election.knownVersions[sender] = version;

    -- If we're already actively syncing and just heard about someone with
    -- strictly newer data, stop - they should be the one syncing, not us.
    local myVersion = RegrowthData:GetCurrentDataVersion();

    if self._isActiveSyncer and version > myVersion then
        self:YieldActiveSyncer();
    end
end

-- Decides the election winner: whoever has the newest data version, ties
-- broken alphabetically by name so every client independently computes
-- the exact same result without needing a coordinator.
function Comm:ConcludeElection()
    self._election.active = false;

    local myName = Regrowth.User.name;
    local winner = myName;
    local winnerVersion = RegrowthData:GetCurrentDataVersion();

    for name, version in pairs(self._election.knownVersions) do
        if version > winnerVersion or (version == winnerVersion and name < winner) then
            winner = name;
            winnerVersion = version;
        end
    end

    if winner == myName then
        self:BecomeActiveSyncer();
    else
        self:YieldActiveSyncer();
    end
end

function Comm:BecomeActiveSyncer()
    self._isActiveSyncer = true;
    self:AutoSyncCheck();
end

-- Stops actively syncing and abandons whatever's left in the queue -
-- another officer with newer data is taking over.
function Comm:YieldActiveSyncer()
    self._isActiveSyncer = false;
    self._syncQueue = {};
    self._queuedLookup = {};
    self._queueRunning = false;

    if self._queueTimerHandle then
        Regrowth.Ace:CancelTimer(self._queueTimerHandle);
        self._queueTimerHandle = nil;
    end
end

-- Records the data version (see RegrowthData:GetCurrentDataVersion) that
-- was just sent to a receiver, persisted so future logins/reloads know
-- they're already up to date. Used by both auto-sync and the manual
-- /rg senddatasync command, so the two don't double up.
function Comm:MarkSynced(receiver)
    Regrowth_Config.SyncedRecipients = Regrowth_Config.SyncedRecipients or {};
    Regrowth_Config.SyncedRecipients[receiver] = RegrowthData:GetCurrentDataVersion();
end

-- True if this receiver's last-known-synced data version is already the
-- current version - i.e. nothing has changed since we last sent to them,
-- so there's no need to send again.
function Comm:IsRecipientUpToDate(receiver)
    Regrowth_Config.SyncedRecipients = Regrowth_Config.SyncedRecipients or {};

    local syncedVersion = Regrowth_Config.SyncedRecipients[receiver];

    if not syncedVersion then
        return false;
    end

    return syncedVersion >= RegrowthData:GetCurrentDataVersion();
end

-- Moves a receiver to the very front of the send queue, adding them if
-- they weren't already queued. Used by the manual /rg syncto override so
-- an officer can jump someone ahead of the line rather than waiting their
-- turn behind everyone else already queued.
function Comm:QueueSyncPriority(receiver)
    if self._queuedLookup[receiver] then
        for i, queuedReceiver in ipairs(self._syncQueue) do
            if queuedReceiver == receiver then
                table.remove(self._syncQueue, i);
                break;
            end
        end
    else
        self._queuedLookup[receiver] = true;
    end

    table.insert(self._syncQueue, 1, receiver);

    self:_startQueueProcessor();
end

-- Adds a receiver to the send queue if they're not already waiting in it.
-- Starts the queue processor if it isn't already running.
function Comm:QueueSync(receiver)
    if self._queuedLookup[receiver] then
        return;
    end

    table.insert(self._syncQueue, receiver);
    self._queuedLookup[receiver] = true;

    self:_startQueueProcessor();
end

function Comm:_startQueueProcessor()
    if self._queueRunning then
        return;
    end

    self._queueRunning = true;

    -- Always go through the timer, even for the very first item. Sending
    -- it immediately/synchronously here would mean a burst of QueueSync
    -- calls in the same loop (e.g. from AutoSyncCheck looping over several
    -- eligible receivers) each drain straight back to empty and reset
    -- _queueRunning before the next one is even added - so nothing would
    -- actually get paced.
    self._queueTimerHandle = Regrowth.Ace:ScheduleTimer(function()
        self:_processSyncQueueTick();
    end, SYNC_QUEUE_INTERVAL_SECONDS);
end

-- Sends to the next queued receiver who's actually online, then schedules
-- itself again after SYNC_QUEUE_INTERVAL_SECONDS if there's more work
-- waiting. Offline recipients are silently skipped and don't consume a
-- pacing interval - there's nothing to throttle if nothing is being sent,
-- so it moves straight on to the next one in the same tick.
function Comm:_processSyncQueueTick()
    if not self._isActiveSyncer then
        self._queueRunning = false;
        return;
    end

    local receiver = table.remove(self._syncQueue, 1);

    while receiver do
        self._queuedLookup[receiver] = nil;

        if Regrowth:isGuildMemberOnline(receiver) then
            Regrowth:success("Syncing data to '" .. receiver .. "'.");

            local message = Regrowth.Comm.Message.new(
                RegrowthData.Constants.Comm.Actions.handlereceiveddata,
                Regrowth_Data,
                "WHISPER",
                receiver
            );

            message:send();

            self:MarkSynced(receiver);

            Regrowth_Config.Activity = Regrowth_Config.Activity or {
                lastSyncSent = 0,
                lastSyncReceived = 0,
            };

            Regrowth_Config.Activity.lastSyncSent = GetServerTime();

            if #self._syncQueue > 0 then
                self._queueTimerHandle = Regrowth.Ace:ScheduleTimer(function()
                    self:_processSyncQueueTick();
                end, SYNC_QUEUE_INTERVAL_SECONDS);
            else
                self._queueRunning = false;
            end

            return;
        end

        -- Not online - skip silently, try the next one right away.
        receiver = table.remove(self._syncQueue, 1);
    end

    -- Queue is empty, either because it started that way or everyone
    -- remaining turned out to be offline.
    self._queueRunning = false;
end

-- The auto-sync equivalent of /rg senddatasync. Mimics what addons like
-- Guild Roster Manager do to avoid needing a manual sync command. Only
-- runs for whichever officer won the election (see StartElection) as the
-- active syncer - everyone else's copy of this function no-ops, so
-- multiple officers online at once don't all sync simultaneously.
function Comm:AutoSyncCheck()
    if not C_GuildInfo.IsGuildOfficer() then
        return;
    end

    if not self._isActiveSyncer then
        return;
    end

    local receivers = RegrowthData:GetLootCouncilReceivers();

    for _, receiver in ipairs(receivers) do
        local isSelf = Regrowth:iEquals(receiver, Regrowth.User.name);

        if not Regrowth:empty(receiver) and not isSelf and not self:IsRecipientUpToDate(receiver) then
            if Regrowth:isGuildMemberOnline(receiver) then
                self:QueueSync(receiver);
            end
        end
    end
end
