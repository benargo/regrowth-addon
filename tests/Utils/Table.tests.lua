---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Utils.Table');
local Table = Regrowth.Utils.Table;

function Tests:EmptyNilIsTrue()
    IsTrue(Table:empty(nil));
end

function Tests:EmptyFalseIsTrue()
    IsTrue(Table:empty(false));
end

function Tests:EmptyTrueIsFalse()
    IsFalse(Table:empty(true));
end

function Tests:EmptyBlankStringIsTrue()
    IsTrue(Table:empty(""));
end

function Tests:EmptyWhitespaceStringIsTrue()
    IsTrue(Table:empty("   "));
end

function Tests:EmptyNonBlankStringIsFalse()
    IsFalse(Table:empty("hello"));
end

function Tests:EmptyTableWithNoEntriesIsTrue()
    IsTrue(Table:empty({}));
end

function Tests:EmptyTableWithEntriesIsFalse()
    IsFalse(Table:empty({ 1, 2, 3 }));
end

function Tests:EmptyZeroIsTrue()
    IsTrue(Table:empty(0));
end

function Tests:EmptyNonZeroNumberIsFalse()
    IsFalse(Table:empty(42));
end

function Tests:EmptyFunctionIsFalse()
    IsFalse(Table:empty(function() end));
end

function Tests:IsArrayDenseTableIsTrue()
    IsTrue(Table:isArray({ "a", "b", "c" }));
end

function Tests:IsArraySparseTableIsFalse()
    IsFalse(Table:isArray({ [1] = "a", [3] = "c" }));
end

function Tests:IsArrayKeyedTableIsFalse()
    IsFalse(Table:isArray({ foo = "bar" }));
end

function Tests:FindByKeyInArrayReturnsMatchingItem()
    local array = {
        { itemId = 1, name = "First" },
        { itemId = 2, name = "Second" },
    };

    AreEqual({ itemId = 2, name = "Second" }, Table:findByKeyInArray(array, "itemId", 2));
end

function Tests:FindByKeyInArrayReturnsNilWhenNotFound()
    local array = { { itemId = 1, name = "First" } };

    IsFalse(Table:findByKeyInArray(array, "itemId", 99) ~= nil);
end

function Tests:FindByKeyReturnsMatchingValue()
    local tbl = { epoch = 12345, name = "Test" };

    AreEqual(12345, Table:findByKey(tbl, "epoch"));
end

function Tests:FindByKeyReturnsNilWhenNotFound()
    local tbl = { epoch = 12345 };

    IsFalse(Table:findByKey(tbl, "missing") ~= nil);
end

function Tests:DeepCopyTableCopiesNestedTables()
    local orig = { a = 1, nested = { b = 2 } };
    local copy = Table:deepCopyTable(orig);

    AreEqual(orig, copy);

    copy.nested.b = 99;

    AreEqual(2, orig.nested.b);
end

function Tests:DeepCopyTablePassesThroughScalars()
    AreEqual(5, Table:deepCopyTable(5));
    AreEqual("str", Table:deepCopyTable("str"));
end
