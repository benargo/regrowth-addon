---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Utils.DebugMode');
local DebugMode = Regrowth.Utils.DebugMode;

function Tests:DumpScalarReturnsToString()
    AreEqual("42", DebugMode:dump(42));
    AreEqual("hello", DebugMode:dump("hello"));
end

function Tests:DumpFlatTableIncludesAllEntries()
    local result = DebugMode:dump({ a = 1 });

    IsTrue(result:find('"a"') ~= nil);
    IsTrue(result:find('1') ~= nil);
end

-- Regression test for the self.dump(v) / self:dump(v) recursion bug: a
-- dot-call silently drops `self`, so nested tables used to render as
-- "table: 0x...." instead of recursing. This must stay a colon call.
function Tests:DumpNestedTableRecursesIntoNestedValues()
    local result = DebugMode:dump({ outer = { inner = "value" } });

    IsFalse(result:find("table: ") ~= nil);
    IsTrue(result:find('"inner"') ~= nil);
    IsTrue(result:find("value") ~= nil);
end
