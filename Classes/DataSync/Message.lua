---@type Regrowth
local _, Regrowth = ...;

---@class Message
local Message = {};
Message.__index = Message;

---@type Message
Regrowth.Comm.Message = Message;

setmetatable(Message, {
    __call = function(cls, ...)
        return cls.new(...);
    end,
});

local LibDeflate = LibStub:GetLibrary("LibDeflate");
local LibSerialize = LibStub:GetLibrary("LibSerialize");

function Message.new(action, content, channel, recipient, onResponse)
    local self = setmetatable({}, Message);

    self.action = action;
    self.content = content;
    self.channel = channel;
    self.sender = Regrowth.User.name;
    self.senderFqn = Regrowth.User.fqn;
    self.senderGUID = UnitGUID("player");
    self.recipient = recipient or nil;
    -- GetServerTime() is realm-synced across every connected client, so
    -- comparing this against GetServerTime() on the recipient's end gives
    -- a reliable, exact delivery time - not something eyeballed off two
    -- different chat windows.
    self.sentAt = GetServerTime();

    self.onResponse = onResponse or function() end;

    return self;
end

function Message.newFromReceived(payload)
    local self = setmetatable({}, Message);

    self.action = payload.action;
    self.content = payload.content;
    self.channel = payload.channel;
    self.sender = payload.sender;
    self.senderFqn = payload.senderFqn;
    self.recipient = payload.recipient;
    self.sentAt = payload.sentAt;

    return self;
end

function Message:compress(unencoded)
    unencoded = unencoded or self;

    local Payload = {
        a = unencoded.action,
        c = unencoded.content,
        h = unencoded.channel,
        s = unencoded.sender,
        f = unencoded.senderFqn,
        g = unencoded.senderGUID,
        r = unencoded.channel ~= "WHISPER" and unencoded.recipient or nil,
        t = unencoded.sentAt,
    };

    local success, encoded = pcall(
        function()
            local serialized = LibSerialize:Serialize(Payload);
            local compressed = LibDeflate:CompressDeflate(serialized, { level = 5, });
            local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);

            return encoded;
        end
    );

    if (not success or not encoded) then
        return false;
    end

    return encoded;
end

function Message:decompress(encoded)
    local success, Payload = pcall(
        function()
            local compressed = LibDeflate:DecodeForWoWAddonChannel(encoded);
            local decompressed = LibDeflate:DecompressDeflate(compressed);
            local _, deserialized = LibSerialize:Deserialize(decompressed);

            return deserialized;
        end
    );

    if (not success or not Payload) then
        return;
    end

    if (type(Payload) == "string") then
        return Payload;
    end

    return {
        action = Payload.a or nil,
        channel = Payload.h or nil,
        content = Payload.c or nil,
        sender = Payload.s or nil,
        senderFqn = Payload.f or nil,
        senderGUID = Payload.g or nil,
        recipient = Payload.r or nil,
        sentAt = Payload.t or nil,
    };
end

function Message:send(broadcastFinishedCallback, packageSentCallback)
    Regrowth.Comm:send(self, broadcastFinishedCallback, packageSentCallback)

    return self;
end
