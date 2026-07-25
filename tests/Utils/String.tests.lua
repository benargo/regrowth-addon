---@type Regrowth
local _, Regrowth = ...;

if not WoWUnit then return end

local Tests = WoWUnit('Regrowth.Utils.String');
local String = Regrowth.Utils.String;

function Tests:IEqualsMatchesExactCase()
    IsTrue(String:iEquals("Hello", "Hello"));
end

function Tests:IEqualsIsCaseInsensitive()
    IsTrue(String:iEquals("Hello", "hello"));
end

function Tests:IEqualsIsWhitespaceInsensitive()
    IsTrue(String:iEquals("  Hello  ", "hello"));
end

function Tests:IEqualsReturnsFalseForDifferentStrings()
    IsFalse(String:iEquals("Hello", "World"));
end

function Tests:IEqualsReturnsFalseForNonStringInputs()
    IsFalse(String:iEquals(123, "123"));
    IsFalse(String:iEquals("123", nil));
end

function Tests:StrStartsWithMatchesPrefix()
    IsTrue(String:strStartsWith("Hello World", "Hello"));
end

function Tests:StrStartsWithIsCaseInsensitiveByDefault()
    IsTrue(String:strStartsWith("HELLO World", "hello"));
end

function Tests:StrStartsWithCanBeCaseSensitive()
    IsFalse(String:strStartsWith("HELLO World", "hello", false));
end

function Tests:StrStartsWithReturnsFalseForNonPrefix()
    IsFalse(String:strStartsWith("Hello World", "World"));
end
