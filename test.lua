

lines = [[
line1
line2
line3
]]

lines = [[ for i in range(1, 5):
    print(i) ]]

new_lines = {}

for line in lines:gmatch("[^\n]+") do
    table.insert(new_lines, line)
end

for i, line in ipairs(new_lines) do
    print(line, i)
    if next(new_lines, i) == nil then
        print("ALL DONE!")
    end
end





