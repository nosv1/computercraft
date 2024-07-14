function valueToKey(table, value)
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
    return "unknown"
end
