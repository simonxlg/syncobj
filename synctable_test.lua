local synctable = require "synctable"

function _dump(data, max_level, prefix)
    if type(prefix) ~= "string" then
        prefix = ""
    end
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
    else
        print(data)
        if max_level ~= 0 then
            local prefix_next = prefix .. "    "
            print(prefix .. "{")
            for k,v in pairs(data) do
                io.stdout:write(prefix_next .. k .. " = ")
                if type(v) ~= "table" or (type(max_level) == "number" and max_level <= 1) then
                    print(v)
                else
                    if max_level == nil then
                        _dump(v, nil, prefix_next)
                    else
                        _dump(v, max_level - 1, prefix_next)
                    end
                end
            end
            print(prefix .. "}")
        end
    end
end

function dump(tab,prefix)
	_dump(tab,5,prefix)
end 

local arr = {1,2,3,5}
for k,v in pairs(arr) do
    print(k,v)
end


local tab = {a=1,b=2,c={c_1 = {c_2={c_3="c_3"}}},d={{1},{2},{3}}}
local tab2 = {a=1,b=2,c={c_1 = {c_2={c_3="c_3"}}},d={{1},{2},{3}}}
print('{a=1,b=2,c={c_1 = {c_2={c_3="c_3"}}},d={{1},{2},{3}}}')

tab = synctable.create(tab)

tab.c.c_1.c_2.c_3 = "c_4"
tab.a={1,2,3,5}
tab.a[1]=2
tab.a[2]=7
tab.a = nil
tab.d = {1,2}
tab.k = {x = 1,y=2,z={x=1,y=2}}
tab.k.z.x=199
tab.a = 9
tab.k.z.x=220


dump(tab2,"----")
local diff = synctable.diff(tab)
dump(diff)
dump(synctable.patch(tab2,diff))

local t = os.time()
for i = 1 ,1000000 do
    tab.a = i
    tab.d = {1,i}
    -- synctable.diff(tab)
    -- synctable.patch(tab2,synctable.diff(tab))
end
dump(tab2)
print("test 100w used times" , os.time() - t)
-- tab.tab=tab
-- dump(synctable.diff(tab),"diff")
--dump(tab,"tab")
--[[
--tab.a=nil
print(tab.c.c_1.c_2.c_3)
tab.c.c_1.c_2.c_3 = "c_4"
print(tab.c.c_1.c_2.c_3)

print('diff================')
dump(tab,"tab")
]]
-- local diff = synctable.diff(tab)
-- dump(diff,"diff")