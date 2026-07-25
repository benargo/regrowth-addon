---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Utils.Table
local Table = {};
Regrowth.Utils = Regrowth.Utils or {};
Regrowth.Utils.Table = Table;

function Table:empty(mixed)
    mixed = mixed or false;

    ---@type string
    local varType = type(mixed);

    if (varType == "boolean") then
        return not mixed;
    end

    if (varType == "string") then
        return strtrim(mixed) == "";
    end

    if (varType == "table") then
        for _, val in pairs(mixed) do
            if (val ~= nil) then
                return false;
            end
        end

        return true;
    end

    if (varType == "number") then
        return mixed == 0;
    end

    if (varType == "function"
            or varType == "CFunction"
            or varType == "userdata"
        ) then
        return false;
    end

    return true;
end

function Table:isArray(tbl)
    local i = 0;

    for _ in pairs(tbl) do
        i = i + 1;
        if tbl[i] == nil then
            return false;
        end
    end

    return true;
end

function Table:findByKeyInArray(array, key, value)
    for _, item in ipairs(array) do
        for k, v in pairs(item) do
            if k == key then
                if v == value then
                    return item;
                end
            end
        end
    end

    return nil;
end

function Table:findByKey(tbl, key)
    for k, v in pairs(tbl) do
        if key == k then
            return v;
        end
    end

    return nil;
end

function Table:deepCopyTable(orig)
	local originalType = type(orig)
	local copy

	if originalType == 'table' then
		copy = {}
		for key, value in pairs(orig) do
			copy[key] = self:deepCopyTable(value)
		end
	else
		copy = orig
	end

	return copy
end
