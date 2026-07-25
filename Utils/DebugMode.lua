---@type Regrowth
local _, Regrowth = ...;

---@class Regrowth.Utils.DebugMode
local DebugMode = {};
Regrowth.Utils = Regrowth.Utils or {};
Regrowth.Utils.DebugMode = DebugMode;

function DebugMode:dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. self:dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
