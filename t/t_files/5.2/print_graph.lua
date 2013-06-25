local line = 10

for i=1, line do
    local res = ''
    for j=1, i do
        res = res .. "*"
    end
    print(res)
end
