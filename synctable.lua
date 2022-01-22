-----------------------
-- synctable
-- Author simon_xlg 285909195@qq.com
-----------------------
--[[
synctable 解决的问题是数据同步存在的痛点
典型的场景：
	如果有一个 table userinfo = {user_id = 10001, nickname = "simon", gold = 8888}
	这个 userinfo 在用户登陆的时候是由 DB代理去（机器1） 数据库中加载后发给 逻辑处理模块（机器2）
	那么就存在 DB代理和逻辑处理模块数据同步问题，譬如用户的金币 gold 值改变了。
	同步这个数据一般有两种做法：	
		1.在 DB代理中写一个接口 update_gold 来处理 gold 值的变化，这种办法会随着接口越来越多而导致代码很难看和一堆 update_xxx 接口。
		2.在 DB代理中写一个接口 updata_userinfo 来全量更新 userinfo ，这种办法在 userinfo 很多字段的情况下浪费过多的流量和执行消耗。
	synctable 的目的就是为了解决上述问题而设计的。
	synctable 可以跟踪逻辑处理模 userinfo （随便一个普通的 table, 调用 synctable.create(userinfo) ）的属性变化，并且生成变化记录 diff（调用 synctable.diff）。
	在后续DB代理中的 synctable.patch(DB代理中的 userinfo， 逻辑处理模块变化记录 diff) 就可以把 userinfo 同步到 DB代理。
	可以做到用最小的代价来解决这个痛点。

限制：
	由于 synctable 是利用了 table 的 __newindex 来记录变化，所以在使用通过 synctable.create(userinfo) 生产出来的副本时候有下列限制：
		1.数组的元素增删需要用 synctable.remove 替换 table.remove、 synctable.insert table.insert
		2.如果动态加了新字段或者 数组 insert 元素，以及 数组 remove 元素。都要及时同步，否则会导致异常。
		3.不要对 synctable 生成的副本频繁加字段删字段，而是改变字段的值！！！
]]

local pairs = pairs
local setmetatable = setmetatable
local insert = table.insert
local synctable = {}
local new
local make

local function distinct_insert(array, key, value)
	-- print("distinct_insert", key, value)
	for i=1,#array do
		for k,v in pairs(array[i]) do
			if k == key then
				array[i][k] = value
				-- print("distinct")
				return
			end
		end
	end
	insert(array, {[key] = value})
end

new = function(root, tab, tag)
	-- print("new:", tag)
	local _tab = {}
	local _root = root
	local ret = make(_root,_tab,tag)
	if not _root then 
		_root = ret
	end
	for k,v in pairs(tab) do
		if type(v) == "table"  then
			_tab[k] = new(_root,v,tag.."."..k)
		else
			_tab[k] = v
		end
	end
	return ret
end

make = function(root, tab, tag)
	local proxy = {
			__data = tab,
			__tag = tag,
			__root = root,
		}
	if not root then 
		proxy.__root = proxy
		proxy.__pair ={}
	end
	setmetatable(proxy,{
		__newindex = function(s, k, v)
						-- print("__newindex", k, v)
						local root = s.__root
						local tag = s.__tag
						local data = s.__data
						if not data[k] and type(v) == "table"  then
							data[k] = new(root,v,tag.."."..k)
						else
							data[k] = v
						end
						distinct_insert(root.__pair, s.__tag.."."..k, v or "nil")
					end,
		__index = function (s, k)
						return s.__data[k]
					end,
		__pairs = function(tab)
					return next, tab.__data ,nil
				  end,
		__len = function (tab)
			       return #tab.__data
				end
	})
	return proxy
end

function synctable.create(tab)
	local _tag = "root"
	return new(nil, tab, _tag)
end

function synctable.diff(tab)
	local diff = tab.__pair
	tab.__pair = {}
	return diff
end

function synctable.patch(obj, diff)
	for i = 1 ,#diff do 
		for k,v in pairs(diff[i]) do
			local arr = {}
			for w in k:gmatch("([^.]+)") do insert(arr, w) end
			local curr = obj
			local len = #arr
			for i=2,len-1 do
				curr = curr[tonumber(arr[i]) or (arr[i])]
				assert(curr, string.format("\n%s=%s", tostring(k) , tostring(v))) 
			end
			curr[tonumber(arr[len]) or (arr[len])] = v
			if v == "nil" then
				if curr[tonumber(arr[len])] then
					table.remove(curr, tonumber(arr[len]))
				else
					curr[(arr[len])] = nil
				end
			end
		end
	end
	return obj
end

function synctable.remove(list, pos)
	table.remove(list, pos)
	for i = pos, #list do
		if type(list[i]) == "table" then
			list[i].__tag = i
		end
	end
end

function synctable.insert(list, obj)
	list[#list+1] = obj
end

--[[
--假设这段代码是 DB代理 从数据中读出来的，并且本地也留一个副本
local userinfo = {user_id = 10001, nickname = "simon", gold = 8888, arr = {1,2,3,4,5}} 
--处理逻辑的模块是在另一台机器上，并且通过网络传输得到了 userinfo
local userinfo2 = synctable.create(userinfo)
--用户玩游戏得到了 1111 个金币
userinfo2.gold = userinfo2.gold + 1111
--增加或者减少元素，增加或者减少字段都要第一时间同步，也就是生成 diff 推送给正本进行 patch
synctable.remove(userinfo2.arr, 2)
--生成变化记录（发送给 DB代理）
local diff = synctable.diff(userinfo2)

--DB代理 用之前的 userinfo 和 处理逻辑的模块 传过来的 diff，合成最新数据
synctable.patch(userinfo, diff)
--打印
print(table.concat(userinfo.arr, ","))
print(userinfo.gold)
--]]

return synctable
