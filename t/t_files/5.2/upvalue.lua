function generator()
    local val = "vsalue"
    return function()
        return val
    end
end

local closure = generator()

print(closure())
print(closure())
